//! Multi-protocolo core library for backend_api.
//! Módulos principales expuestos por el servidor.

pub mod auth;          // Login + Web3
pub mod config;        // Environment validation
pub mod social;        // Chat + Feed
pub mod finance;       // Pagos USDT + Ledger
pub mod gamification;  // XP, Rangos, Logros
pub mod security;      // Quantum Crypto + Audit
pub mod rpc;           // Servidor gRPC
pub mod state;
pub mod middleware;    // Rate limiting & other middleware
pub mod tls;           // TLS/HTTPS configuration
pub mod storage;       // S3/MinIO object storage
pub mod notifications; // FCM Push Notifications
pub mod operations;    // Attendance & ops
pub mod admin;         // God Mode & CEO Dashboard
pub mod engine;        // Core logic engine (finance + gamification)
pub mod realtime;      // WebSocket hub for real-time dashboards
pub mod tracking;      // Telemetry from Chrome extension
pub mod legal;         // Contratos y documentos legales
pub mod emergency;     // Parada de emergencia global


