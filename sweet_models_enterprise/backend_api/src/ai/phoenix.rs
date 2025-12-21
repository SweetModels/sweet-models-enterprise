use std::fs;

use async_openai::{config::OpenAIConfig, types::{ChatCompletionRequestMessage, ChatCompletionRequestUserMessageArgs, CreateChatCompletionRequestArgs}, Client};
use regex::Regex;
use tokio::{fs as tokio_fs, process::Command, time::{sleep, Duration}};
use tracing::{error, info, warn};

#[derive(Clone)]
pub struct PhoenixAgent {
    pub api_client: Client<OpenAIConfig>,
    pub is_active: bool,
}

impl PhoenixAgent {
    pub fn new() -> Self {
        let api_key = std::env::var("OPENAI_API_KEY")
            .expect("OPENAI_API_KEY environment variable must be set");
        
        // Configure for DeepSeek API
        let config = OpenAIConfig::new()
            .with_api_key(api_key)
            .with_api_base("https://api.deepseek.com");
        
        let client = Client::with_config(config);
        Self {
            api_client: client,
            is_active: true,
        }
    }
}

/// Arranca el centinela que vigila los logs y dispara la autocuración.
pub async fn start_sentinel() {
    let agent = PhoenixAgent::new();
    let log_path = String::from("errors.log");
    tokio::spawn(async move {
        watch_logs(agent, log_path.as_str()).await;
    });
}

async fn watch_logs(agent: PhoenixAgent, log_path: &str) {
    let re = Regex::new("(?i)(panic|error)").unwrap_or_else(|_| Regex::new("panic").unwrap());
    info!("[PHOENIX] Centinela iniciado, vigilando {}", log_path);
    let mut last_seen = String::new();
    loop {
        match tokio_fs::read_to_string(log_path).await {
            Ok(content) => {
                if content != last_seen {
                    if let Some(mat) = re.find(&content) {
                        info!("[PHOENIX] Herida detectada: {}", mat.as_str());
                        
                        // Extract file path from stack trace
                        let file_path = extract_source_file(&content)
                            .unwrap_or_else(|| "src/main.rs".to_string());
                        
                        info!("[PHOENIX] Archivo detectado: {}", file_path);
                        
                        if let Err(e) = heal_code(&agent, content.clone(), &file_path).await {
                            error!("[PHOENIX] Reparación fallida: {}", e);
                        }
                    }
                    last_seen = content;
                }
            }
            Err(_) => {
                // No file yet; ignore
            }
        }
        sleep(Duration::from_secs(5)).await;
    }
}

/// Extracts source file path from Rust panic/error stack trace
/// 
/// Looks for patterns like:
/// - "at src/main.rs:42:5"
/// - "src/auth/web3.rs:123:10"
/// - "--> src/lib.rs:15:1"
fn extract_source_file(error_log: &str) -> Option<String> {
    // Pattern 1: "at src/path/file.rs:line:col"
    let at_pattern = Regex::new(r"at (src/[^\s:]+\.rs):\d+:\d+").ok()?;
    if let Some(cap) = at_pattern.captures(error_log) {
        return Some(cap[1].to_string());
    }
    
    // Pattern 2: "src/path/file.rs:line:col" (standalone)
    let standalone_pattern = Regex::new(r"(src/[^\s:]+\.rs):\d+:\d+").ok()?;
    if let Some(cap) = standalone_pattern.captures(error_log) {
        return Some(cap[1].to_string());
    }
    
    // Pattern 3: "--> src/path/file.rs:line:col" (compiler errors)
    let arrow_pattern = Regex::new(r"--> (src/[^\s:]+\.rs):\d+:\d+").ok()?;
    if let Some(cap) = arrow_pattern.captures(error_log) {
        return Some(cap[1].to_string());
    }
    
    // Pattern 4: Check for common keywords followed by file paths
    let keyword_pattern = Regex::new(r"(?:panic|error|thread)[^\n]+(src/[^\s:]+\.rs)").ok()?;
    if let Some(cap) = keyword_pattern.captures(error_log) {
        return Some(cap[1].to_string());
    }
    
    None
}

async fn heal_code(agent: &PhoenixAgent, error_msg: String, file_path: &str) -> Result<(), String> {
    if !agent.is_active {
        return Err("Phoenix desactivado".into());
    }

    // Verify file exists before attempting to heal
    if !tokio_fs::try_exists(file_path).await.unwrap_or(false) {
        return Err(format!("Archivo no encontrado: {}", file_path));
    }

    let code = tokio_fs::read_to_string(file_path)
        .await
        .map_err(|e| format!("No se pudo leer {file_path}: {e}"))?;

    info!("[PHOENIX] Analizando {} ({} líneas)", file_path, code.lines().count());

    let prompt = format!(
        "Actúa como un Experto en Rust. Este código en el archivo '{}' generó el error:\n\n{}\n\nDevuélveme EL CÓDIGO CORREGIDO COMPLETO para este archivo. Solo código, sin explicaciones, sin markdown.\n\nCódigo actual:\n{}",
        file_path,
        error_msg.lines().take(20).collect::<Vec<_>>().join("\n"), // Limit error context
        code
    );

    let user_msg = ChatCompletionRequestUserMessageArgs::default()
        .content(prompt)
        .build()
        .map_err(|e| e.to_string())?;

    let request = CreateChatCompletionRequestArgs::default()
        .model("deepseek-chat")
        .messages([ChatCompletionRequestMessage::User(user_msg)])
        .build()
        .map_err(|e| e.to_string())?;

    info!("[PHOENIX] Consultando al Oráculo...");
    let resp = agent.api_client.chat().create(request).await.map_err(|e| e.to_string())?;
    let suggestion = resp
        .choices
        .first()
        .and_then(|c| c.message.content.clone())
        .unwrap_or_default();

    if suggestion.trim().is_empty() {
        return Err("El oráculo no devolvió código".into());
    }

    let tmp_path = format!("{file_path}.tmp");
    tokio_fs::write(&tmp_path, suggestion.as_bytes())
        .await
        .map_err(|e| format!("No se pudo escribir tmp: {e}"))?;

    info!("[PHOENIX] Ejecutando pruebas en archivo reparado...");
    let status = Command::new("cargo")
        .arg("test")
        .arg("--quiet")
        .arg("--")
        .arg("--nocapture")
        .status()
        .await
        .map_err(|e| format!("No se pudo ejecutar cargo test: {e}"))?;

    if status.success() {
        fs::rename(&tmp_path, file_path).map_err(|e| format!("No se pudo aplicar parche: {e}"))?;
        info!("[PHOENIX] ✨ ¡Sistema reparado exitosamente! Archivo: {}", file_path);
        Ok(())
    } else {
        let _ = fs::remove_file(&tmp_path);
        warn!("[PHOENIX] ⚠️ Reparación fallida, se descarta el parche para {}", file_path);
        Err("Tests fallaron".into())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_source_file_at_pattern() {
        let log = "thread 'main' panicked at src/auth/web3.rs:42:5:\nindex out of bounds";
        let result = extract_source_file(log);
        assert_eq!(result, Some("src/auth/web3.rs".to_string()));
    }

    #[test]
    fn test_extract_source_file_standalone() {
        let log = "Error in src/finance/ledger.rs:123:10: invalid block hash";
        let result = extract_source_file(log);
        assert_eq!(result, Some("src/finance/ledger.rs".to_string()));
    }

    #[test]
    fn test_extract_source_file_compiler_arrow() {
        let log = "error[E0599]: no method named `foo`\n --> src/lib.rs:15:1\n  |";
        let result = extract_source_file(log);
        assert_eq!(result, Some("src/lib.rs".to_string()));
    }

    #[test]
    fn test_extract_source_file_no_match() {
        let log = "Some generic error message without file path";
        let result = extract_source_file(log);
        assert_eq!(result, None);
    }

    #[test]
    fn test_extract_source_file_nested_path() {
        let log = "panic at src/auth/zk/mod.rs:89:12: challenge expired";
        let result = extract_source_file(log);
        assert_eq!(result, Some("src/auth/zk/mod.rs".to_string()));
    }
}
