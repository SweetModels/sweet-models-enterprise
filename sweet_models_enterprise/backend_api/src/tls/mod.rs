use std::path::Path;
use std::sync::Arc;
use std::io::BufReader;
use std::fs::File;
use tokio_rustls::rustls::{Certificate, PrivateKey, ServerConfig};
use rustls_pemfile::{certs, rsa_private_keys};

/// TLS configuration for HTTPS server
pub struct TlsConfiguration {
    pub cert_path: String,
    pub key_path: String,
}

impl TlsConfiguration {
    /// Create TLS config from environment variables
    pub fn from_env() -> Option<Self> {
        let cert_path = std::env::var("TLS_CERT_PATH").ok()?;
        let key_path = std::env::var("TLS_KEY_PATH").ok()?;
        
        Some(Self { cert_path, key_path })
    }
    
    /// Check if certificate files exist
    pub fn validate(&self) -> Result<(), String> {
        if !Path::new(&self.cert_path).exists() {
            return Err(format!("Certificate file not found: {}", self.cert_path));
        }
        
        if !Path::new(&self.key_path).exists() {
            return Err(format!("Private key file not found: {}", self.key_path));
        }
        
        Ok(())
    }
    
    /// Build ServerConfig for tokio-rustls
    pub fn build_config(&self) -> Result<Arc<ServerConfig>, Box<dyn std::error::Error + Send + Sync>> {
        self.validate()?;
        
        tracing::info!("🔒 Loading TLS certificate from: {}", self.cert_path);
        tracing::info!("🔑 Loading TLS private key from: {}", self.key_path);
        
        // Load certificate chain
        let cert_file = File::open(&self.cert_path)
            .map_err(|e| format!("Failed to open certificate: {}", e))?;
        let mut cert_reader = BufReader::new(cert_file);
        let cert_chain: Vec<Certificate> = certs(&mut cert_reader)
            .map_err(|_| "Failed to parse certificates")?
            .into_iter()
            .map(Certificate)
            .collect();
        
        if cert_chain.is_empty() {
            return Err("No certificates found in certificate file".into());
        }
        
        // Load private key
        let key_file = File::open(&self.key_path)
            .map_err(|e| format!("Failed to open private key: {}", e))?;
        let mut key_reader = BufReader::new(key_file);
        let mut keys = rsa_private_keys(&mut key_reader)
            .map_err(|_| "Failed to parse private key")?;
        
        if keys.is_empty() {
            return Err("No RSA private keys found in key file".into());
        }
        
        let private_key = PrivateKey(keys.remove(0));
        
        // Build ServerConfig
        let config = ServerConfig::builder()
            .with_safe_defaults()
            .with_no_client_auth()
            .with_single_cert(cert_chain, private_key)
            .map_err(|e| format!("Failed to build TLS config: {}", e))?;
        
        Ok(Arc::new(config))
    }
}

/// Generate self-signed certificate for development (instructions only)
pub fn print_dev_cert_instructions() {
    println!("\n📋 To generate a self-signed certificate for development:");
    println!("   Run these commands:\n");
    
    #[cfg(target_os = "windows")]
    {
        println!("   # Using OpenSSL (install from https://slproweb.com/products/Win32OpenSSL.html)");
        println!("   openssl req -x509 -newkey rsa:4096 -nodes -keyout key.pem -out cert.pem -days 365 -subj \"/CN=localhost\"\n");
    }
    
    #[cfg(not(target_os = "windows"))]
    {
        println!("   openssl req -x509 -newkey rsa:4096 -nodes \\");
        println!("     -keyout key.pem -out cert.pem -days 365 \\");
        println!("     -subj \"/CN=localhost\"\n");
    }
    
    println!("   Then set in .env:");
    println!("   TLS_CERT_PATH=cert.pem");
    println!("   TLS_KEY_PATH=key.pem\n");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tls_config_from_env() {
        // Without env vars, should return None
        std::env::remove_var("TLS_CERT_PATH");
        std::env::remove_var("TLS_KEY_PATH");
        
        assert!(TlsConfiguration::from_env().is_none());
    }

    #[test]
    fn test_tls_config_validation_fails_for_missing_files() {
        let config = TlsConfiguration {
            cert_path: "nonexistent_cert.pem".to_string(),
            key_path: "nonexistent_key.pem".to_string(),
        };
        
        assert!(config.validate().is_err());
    }
}
