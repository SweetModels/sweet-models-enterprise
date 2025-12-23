-- SWEET MODELS ENTERPRISE - USERS TABLE SCHEMA (MySQL Version)
-- Optimizado para Railway y rendimiento máximo
CREATE TABLE IF NOT EXISTS users (
  -- 1. Identificacion Unica
  id INT AUTO_INCREMENT PRIMARY KEY,

  -- 2. Autenticacion Blindada
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL, -- Hash de la contrasena
  role VARCHAR(50) NOT NULL DEFAULT 'user', -- 'admin', 'model', 'studio'

  -- 3. Auditoria Automatica (MySQL)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  -- 4. Perfil Enterprise
  full_name VARCHAR(255),
  phone VARCHAR(20),
  address TEXT,
  national_id VARCHAR(50), -- DNI/Cedula

  -- 5. Seguridad & Verificacion
  is_verified BOOLEAN DEFAULT FALSE, -- Email verificado
  is_active BOOLEAN DEFAULT TRUE,    -- Interruptor general
  biometric_enabled BOOLEAN DEFAULT FALSE,
  phone_verified BOOLEAN DEFAULT FALSE,

  -- 6. Modulo KYC
  kyc_status VARCHAR(50) DEFAULT 'pending',
  kyc_verified_at TIMESTAMP NULL,

  -- 7. Integraciones
  platform_usernames JSON -- Guarda usuarios de cams
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indices de Velocidad
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_active ON users(is_active);
