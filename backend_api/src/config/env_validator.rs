use std::env;
use std::process;

/// Required environment variables for the application
const REQUIRED_ENV_VARS: &[(&str, &str)] = &[
    ("DATABASE_URL", "PostgreSQL connection string (e.g., postgresql://user:pass@localhost/dbname)"),
    ("REDIS_URL", "Redis connection string (e.g., redis://localhost:6379)"),
    ("NATS_URL", "NATS server URL (e.g., nats://localhost:4222)"),
    ("JWT_SECRET", "Secret key for JWT token signing (use a strong random string)"),
    ("OPENAI_API_KEY", "OpenAI API key for Phoenix auto-repair agent"),
];

/// Optional environment variables with defaults
const OPTIONAL_ENV_VARS: &[(&str, &str, &str)] = &[
    ("RUST_LOG", "info", "Logging level (trace, debug, info, warn, error)"),
    ("SERVER_HOST", "0.0.0.0", "Server bind address"),
    ("SERVER_PORT", "8080", "Server bind port"),
];

/// Validates all required environment variables are set
/// 
/// # Panics
/// 
/// Exits the process with code 1 if any required variables are missing
pub fn validate_environment() {
    println!("🔍 Validating environment variables...");
    
    let mut missing_vars = Vec::new();
    let mut warnings = Vec::new();
    
    // Check required variables
    for (var_name, description) in REQUIRED_ENV_VARS {
        match env::var(var_name) {
            Ok(value) => {
                if value.trim().is_empty() {
                    missing_vars.push((*var_name, *description));
                } else {
                    // Mask sensitive values in logs
                    let masked_value = mask_sensitive_value(var_name, &value);
                    println!("  ✓ {} = {}", var_name, masked_value);
                }
            }
            Err(_) => {
                missing_vars.push((*var_name, *description));
            }
        }
    }
    
    // Check optional variables and set defaults
    for (var_name, default_value, description) in OPTIONAL_ENV_VARS {
        match env::var(var_name) {
            Ok(value) => {
                println!("  ✓ {} = {} ({})", var_name, value, description);
            }
            Err(_) => {
                env::set_var(var_name, default_value);
                warnings.push(format!(
                    "  ⚠ {} not set, using default: {} ({})",
                    var_name, default_value, description
                ));
            }
        }
    }
    
    // Print warnings
    if !warnings.is_empty() {
        println!("\n⚠️  Warnings:");
        for warning in warnings {
            println!("{}", warning);
        }
    }
    
    // Exit if required variables are missing
    if !missing_vars.is_empty() {
        eprintln!("\n❌ Missing required environment variables:\n");
        for (var_name, description) in missing_vars {
            eprintln!("  • {}", var_name);
            eprintln!("    Description: {}", description);
        }
        eprintln!("\n💡 Create a .env file in the project root with the required variables.");
        eprintln!("   See .env.example for a template.\n");
        process::exit(1);
    }
    
    println!("✅ Environment validation passed!\n");
}

/// Masks sensitive values in environment variable output
fn mask_sensitive_value(var_name: &str, value: &str) -> String {
    let sensitive_keywords = ["SECRET", "KEY", "PASSWORD", "TOKEN"];
    
    if sensitive_keywords.iter().any(|kw| var_name.contains(kw)) {
        if value.len() <= 8 {
            return "***".to_string();
        }
        format!("{}...{}", &value[..4], &value[value.len()-4..])
    } else if var_name.contains("URL") {
        // Mask credentials in URLs
        mask_url_credentials(value)
    } else {
        value.to_string()
    }
}

/// Masks username/password in database URLs
fn mask_url_credentials(url: &str) -> String {
    if let Some(at_pos) = url.find('@') {
        if let Some(scheme_end) = url.find("://") {
            let scheme = &url[..scheme_end + 3];
            let after_at = &url[at_pos..];
            return format!("{}***:***{}", scheme, after_at);
        }
    }
    url.to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mask_sensitive_value() {
        assert_eq!(mask_sensitive_value("JWT_SECRET", "my_super_secret_key_12345"), "my_s...2345");
        assert_eq!(mask_sensitive_value("API_KEY", "short"), "***");
        assert_eq!(mask_sensitive_value("SERVER_PORT", "8080"), "8080");
    }

    #[test]
    fn test_mask_url_credentials() {
        let url = "postgresql://user:password@localhost:5432/dbname";
        let masked = mask_url_credentials(url);
        assert!(masked.contains("***:***"));
        assert!(masked.contains("@localhost:5432/dbname"));
        assert!(!masked.contains("user"));
        assert!(!masked.contains("password"));
    }
}
