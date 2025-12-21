-- Tabla de Productos
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    price_cop DECIMAL(15, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    image_url VARCHAR(512),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Órdenes
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING_DELIVERY',
    quantity INTEGER NOT NULL DEFAULT 1,
    total_price_cop DECIMAL(15, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_products_active ON products(is_active, stock);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
CREATE INDEX idx_orders_status ON orders(status);

-- Datos Semilla (3 Productos)
INSERT INTO products (name, price_cop, stock, image_url, is_active) VALUES
    ('Lencería Victoria Red', 85000.00, 15, 'https://via.placeholder.com/300?text=Lenceria+Victoria', TRUE),
    ('Aro de Luz LED RGB', 120000.00, 8, 'https://via.placeholder.com/300?text=Aro+LED', TRUE),
    ('Vibrador Lush 2', 250000.00, 5, 'https://via.placeholder.com/300?text=Vibrador+Lush', TRUE);
