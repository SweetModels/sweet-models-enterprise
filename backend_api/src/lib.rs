//! Multi-protocolo core library for backend_api.
//! Módulos principales expuestos por el servidor.

pub mod auth;      // Login + Web3
pub mod config;    // Environment validation
pub mod social;    // Chat + Feed
pub mod finance;   // Pagos USDT + Ledger
pub mod security;  // Quantum Crypto + Audit
pub mod rpc;       // Servidor gRPC
pub mod state;
pub mod middleware; // Rate limiting & other middleware
pub mod tls;       // TLS/HTTPS configuration
