-- ============================================================================
-- EJEMPLOS DE USO DEL LEDGER DE AUDITORÍA
-- ============================================================================

-- 1. Ver el estado actual de la cadena
SELECT 
    total_blocks,
    last_block_timestamp,
    unique_hashes
FROM ledger_chain_status;

-- 2. Obtener el último bloque sellado
SELECT * FROM get_last_block();

-- 3. Ver todas las transacciones de un usuario
SELECT * FROM user_transaction_audit
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY timestamp DESC;

-- 4. Obtener un resumen de transacciones por usuario
SELECT * FROM get_user_transaction_summary(
    '550e8400-e29b-41d4-a716-446655440000'::UUID
);

-- 5. Verificar que toda la cadena es íntegra
-- Ejecución de verifying_chain_integrity() en Rust
-- que ejecuta esta consulta para validar:
SELECT 
    al.id,
    al.prev_hash,
    al.data,
    al.nonce,
    al.hash,
    al.timestamp
FROM audit_ledger al
ORDER BY al.timestamp ASC;

-- 6. Contar transacciones de un usuario
SELECT count_user_transactions('550e8400-e29b-41d4-a716-446655440000'::UUID);

-- 7. Ver todas las transacciones de tipo "payment"
SELECT * FROM user_transaction_audit
WHERE transaction_type = 'payment'
ORDER BY timestamp DESC;

-- 8. Ver transacciones en un rango de fechas
SELECT * FROM user_transaction_audit
WHERE timestamp BETWEEN '2025-12-01' AND '2025-12-31'
ORDER BY timestamp DESC;

-- 9. Obtener el total de dinero movido por divisa
SELECT 
    currency,
    SUM(CAST(amount AS NUMERIC)) as total_amount,
    COUNT(*) as transaction_count
FROM user_transaction_audit
GROUP BY currency
ORDER BY total_amount DESC;

-- 10. Auditoría: Ver quién hizo qué y cuándo
SELECT 
    user_id,
    transaction_type,
    amount,
    currency,
    timestamp,
    block_id
FROM user_transaction_audit
WHERE timestamp >= NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;

-- ============================================================================
-- INSERCIÓN MANUAL (Solo para testing, no usar en producción)
-- ============================================================================

-- Insertar un bloque de ejemplo (NOTA: El hash debe ser calculado correctamente)
-- INSERT INTO audit_ledger (
--     id, 
--     prev_hash, 
--     data, 
--     nonce, 
--     hash, 
--     timestamp
-- ) VALUES (
--     gen_random_uuid(),
--     '0',
--     '{"tx_type": "payment", "user_id": "550e8400-e29b-41d4-a716-446655440000", "amount": 100.50, "currency": "COP", "description": "Test"}'::jsonb,
--     EXTRACT(EPOCH FROM NOW()) * 1000000000,
--     'hash_calculado_correctamente_aqui',
--     NOW()
-- );

-- ============================================================================
-- VERIFICACIONES DE INTEGRIDAD
-- ============================================================================

-- Verificar que no hay hashes duplicados
SELECT hash, COUNT(*) as count
FROM audit_ledger
GROUP BY hash
HAVING COUNT(*) > 1;

-- Verificar que todos los prev_hash existen (excepto el bloque genesis)
SELECT DISTINCT al.prev_hash
FROM audit_ledger al
WHERE al.prev_hash != '0'
  AND al.prev_hash NOT IN (SELECT hash FROM audit_ledger);

-- Ver la cadena completa en orden
WITH RECURSIVE chain AS (
    SELECT id, prev_hash, hash, timestamp, 1 as depth
    FROM audit_ledger
    WHERE prev_hash = '0'
    
    UNION ALL
    
    SELECT al.id, al.prev_hash, al.hash, al.timestamp, c.depth + 1
    FROM audit_ledger al
    INNER JOIN chain c ON al.prev_hash = c.hash
)
SELECT * FROM chain
ORDER BY depth;

-- ============================================================================
-- LIMPIEZA Y MANTENIMIENTO
-- ============================================================================

-- Verificar tamaño de la tabla
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE tablename = 'audit_ledger';

-- Ver estadísticas de índices
SELECT 
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE relname = 'audit_ledger'
ORDER BY idx_scan DESC;

-- ============================================================================
-- MONITOREO Y ALERTAS
-- ============================================================================

-- Transacciones en las últimas 24 horas
SELECT 
    COUNT(*) as total_transactions,
    SUM(CAST(amount AS NUMERIC)) as total_amount,
    COUNT(DISTINCT user_id) as unique_users
FROM user_transaction_audit
WHERE timestamp >= NOW() - INTERVAL '24 hours';

-- Usuarios con más transacciones
SELECT 
    user_id,
    COUNT(*) as tx_count,
    SUM(CAST(amount AS NUMERIC)) as total_amount
FROM user_transaction_audit
GROUP BY user_id
ORDER BY tx_count DESC
LIMIT 10;

-- Tipos de transacciones más comunes
SELECT 
    transaction_type,
    COUNT(*) as count,
    SUM(CAST(amount AS NUMERIC)) as total
FROM user_transaction_audit
GROUP BY transaction_type
ORDER BY count DESC;
