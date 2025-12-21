use argon2::{Argon2, PasswordHasher};
use argon2::password_hash::SaltString;
use rand::thread_rng;

fn main() {
    let password = "Isaias..20-26";
    let salt = SaltString::generate(thread_rng());
    let argon2 = Argon2::default();
    match argon2.hash_password(password.as_bytes(), &salt) {
        Ok(hash) => println!("{}", hash.to_string()),
        Err(e) => eprintln!("Error: {}", e),
    }
}
