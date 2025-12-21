use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};

/// Error personalizado para operaciones de password
#[derive(Debug)]
pub enum PasswordError {
    HashingFailed(String),
    VerificationFailed(String),
}

impl std::fmt::Display for PasswordError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            PasswordError::HashingFailed(msg) => write!(f, "Password hashing failed: {}", msg),
            PasswordError::VerificationFailed(msg) => write!(f, "Password verification failed: {}", msg),
        }
    }
}

impl std::error::Error for PasswordError {}

/// Hashea una contraseña usando Argon2
/// 
/// # Argumentos
/// * `password` - La contraseña en texto plano
/// 
/// # Retorna
/// * `Ok(String)` - El hash de la contraseña en formato PHC
/// * `Err(PasswordError)` - Si el hashing falla
/// 
/// # Ejemplo
/// ```rust
/// let password = "mi_contraseña_segura";
/// let hash = hash_password(password).unwrap();
/// // hash: $argon2id$v=19$m=19456,t=2,p=1$...
/// ```
pub fn hash_password(password: &str) -> Result<String, PasswordError> {
    // Generar un salt aleatorio
    let salt = SaltString::generate(&mut OsRng);
    
    // Usar Argon2 con configuración por defecto (segura)
    let argon2 = Argon2::default();
    
    // Hashear la contraseña
    let password_hash = argon2
        .hash_password(password.as_bytes(), &salt)
        .map_err(|e| PasswordError::HashingFailed(e.to_string()))?;
    
    Ok(password_hash.to_string())
}

/// Verifica una contraseña contra un hash almacenado
/// 
/// # Argumentos
/// * `password` - La contraseña en texto plano a verificar
/// * `password_hash` - El hash almacenado en la base de datos
/// 
/// # Retorna
/// * `Ok(true)` - Si la contraseña es correcta
/// * `Ok(false)` - Si la contraseña es incorrecta
/// * `Err(PasswordError)` - Si hay un error en el parsing del hash
/// 
/// # Ejemplo
/// ```rust
/// let password = "mi_contraseña_segura";
/// let stored_hash = "$argon2id$v=19$m=19456,t=2,p=1$...";
/// 
/// if verify_password(password, stored_hash).unwrap() {
///     println!("Contraseña correcta!");
/// } else {
///     println!("Contraseña incorrecta!");
/// }
/// ```
pub fn verify_password(password: &str, password_hash: &str) -> Result<bool, PasswordError> {
    // Parsear el hash almacenado
    let parsed_hash = PasswordHash::new(password_hash)
        .map_err(|e| PasswordError::VerificationFailed(format!("Invalid hash format: {}", e)))?;
    
    // Usar Argon2 para verificar
    let argon2 = Argon2::default();
    
    // Verificar la contraseña
    match argon2.verify_password(password.as_bytes(), &parsed_hash) {
        Ok(_) => Ok(true),
        Err(_) => Ok(false), // Password no coincide (no es un error, es resultado válido)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash_password() {
        let password = "test_password_123";
        let hash = hash_password(password).unwrap();
        
        // Verificar que el hash tiene el formato correcto
        assert!(hash.starts_with("$argon2"));
        assert!(hash.len() > 50); // Los hashes Argon2 son largos
    }

    #[test]
    fn test_verify_password_correct() {
        let password = "test_password_123";
        let hash = hash_password(password).unwrap();
        
        // Verificar que la contraseña correcta pasa
        assert!(verify_password(password, &hash).unwrap());
    }

    #[test]
    fn test_verify_password_incorrect() {
        let password = "test_password_123";
        let hash = hash_password(password).unwrap();
        
        // Verificar que una contraseña incorrecta falla
        assert!(!verify_password("wrong_password", &hash).unwrap());
    }

    #[test]
    fn test_different_hashes() {
        let password = "same_password";
        let hash1 = hash_password(password).unwrap();
        let hash2 = hash_password(password).unwrap();
        
        // Los hashes deben ser diferentes (diferentes salts)
        assert_ne!(hash1, hash2);
        
        // Pero ambos deben verificar correctamente
        assert!(verify_password(password, &hash1).unwrap());
        assert!(verify_password(password, &hash2).unwrap());
    }
}
