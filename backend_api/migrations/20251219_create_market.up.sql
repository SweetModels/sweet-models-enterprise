-- Market module schema (products + orders)
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Products catalog
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    price_cop NUMERIC(15, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    image_url VARCHAR(512),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Purchase orders
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING_DELIVERY' CHECK (status IN ('PENDING_DELIVERY', 'DELIVERED')),
    quantity INTEGER NOT NULL DEFAULT 1,
    total_price_cop NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_products_active_stock ON products(is_active, stock);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_user_status ON orders(user_id, status);

-- Seed data (idempotent per name)
INSERT INTO products (name, price_cop, stock, image_url, is_active)
SELECT 'Lencería Victoria Red', 85000.00, 15, 'https://via.placeholder.com/300?text=Lenceria+Victoria', TRUE
WHERE NOT EXISTS (SELECT 1 FROM products WHERE name = 'Lencería Victoria Red');

INSERT INTO products (name, price_cop, stock, image_url, is_active)
SELECT 'Aro de Luz LED RGB', 120000.00, 8, 'https://via.placeholder.com/300?text=Aro+LED', TRUE
WHERE NOT EXISTS (SELECT 1 FROM products WHERE name = 'Aro de Luz LED RGB');

INSERT INTO products (name, price_cop, stock, image_url, is_active)
SELECT 'Vibrador Lush 2', 250000.00, 5, 'https://via.placeholder.com/300?text=Vibrador+Lush', TRUE
WHERE NOT EXISTS (SELECT 1 FROM products WHERE name = 'Vibrador Lush 2');
