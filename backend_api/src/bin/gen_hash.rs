// =====================================================
// Sweet Models Enterprise - Password Hash Generator
// =====================================================
//
// Este programa genera hashes Argon2 para contraseñas
// que luego pueden insertarse en la base de datos
//
// Uso:
// cargo run --bin gen_hash <contraseña>
//
// Ejemplo:
// cargo run --bin gen_hash modelo123

use argon2::{
    password_hash::{rand_core::OsRng, PasswordHasher, SaltString},
    Argon2,
};

fn main() {
    let args: Vec<String> = std::env::args().collect();
    
    if args.len() < 2 {
        eprintln!("❌ Error: Falta la contraseña");
        eprintln!();
        eprintln!("Uso: cargo run --bin gen_hash <contraseña>");
        eprintln!();
        eprintln!("Ejemplo:");
        eprintln!("  cargo run --bin gen_hash modelo123");
        std::process::exit(1);
    }
    
    let password = &args[1];
    
    println!();
    println!("🔐 Generando hash Argon2 para contraseña...");
    println!();
    
    // Generar salt aleatorio
    let salt = SaltString::generate(&mut OsRng);
    
    // Crear instancia de Argon2
    let argon2 = Argon2::default();
    
    // Generar hash
    match argon2.hash_password(password.as_bytes(), &salt) {
        Ok(password_hash) => {
            let hash_string = password_hash.to_string();
            
            println!("✅ Hash generado exitosamente:");
            println!();
            println!("{}", hash_string);
            println!();
            println!("📋 Para insertar en PostgreSQL:");
            println!();
            println!("INSERT INTO users (email, password_hash, role, full_name)");
            println!("VALUES (");
            println!("  'usuario@sweet.com',");
            println!("  '{}',", hash_string);
            println!("  'MODEL',");
            println!("  'Nombre del Usuario'");
            println!(");");
            println!();
        }
        Err(e) => {
            eprintln!("❌ Error al generar hash: {}", e);
            std::process::exit(1);
        }
    }
}
