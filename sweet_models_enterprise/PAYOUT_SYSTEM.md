# 💰 Sistema de Liquidación de Pagos (Payouts)

Sistema completo para liquidar saldos pendientes a modelos y gestionar historial de pagos.

## 📋 Resumen de Implementación

### ✅ Backend (Rust/Axum)

#### 1. Base de Datos (Migration 011)

**Tabla `payouts`:**


```sql
CREATE TABLE payouts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    amount NUMERIC(12, 2) NOT NULL,
    method VARCHAR(50) NOT NULL, -- 'binance', 'bank', 'cash', 'other'
    transaction_ref VARCHAR(255),
    notes TEXT,
    receipt_url VARCHAR(500),
    status VARCHAR(20) DEFAULT 'completed',
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

```

**Nueva columna en `users`:**


```sql
ALTER TABLE users ADD COLUMN pending_balance NUMERIC(12, 2) DEFAULT 0.00;

```

**Funciones SQL:**
- `calculate_pending_balance(user_id)`: Calcula saldo real (ganado - pagado)
- `sync_all_pending_balances()`: Sincroniza saldos de todos los usuarios
- `get_user_payout_history(user_id)`: Historial de pagos del usuario
- `get_payout_stats()`: Estadísticas de pagos (por método, por estado)


#### 2. API Endpoints

### POST /api/admin/payout

- **Propósito**: Procesar liquidación y generar recibo
- **Body:**


  ```json
  {
    "user_id": "uuid",
    "amount": 500.00,
    "method": "binance",
    "transaction_ref": "TX12345",
    "notes": "Pago quincenal"
  }
  ```

- **Response:**


  ```json
  {
    "payout_id": "uuid",
    "amount": 500.00,
    "new_pending_balance": 1500.00,
    "receipt_url": "/uploads/receipts/receipt_uuid.pdf",
    "status": "completed",
    "message": "Payout processed successfully"
  }
  ```

- **Acciones:**
  1. Valida saldo suficiente
  2. Inserta registro en `payouts`
  3. Reduce `pending_balance` del usuario
  4. Genera PDF de recibo
  5. Devuelve confirmación


### GET /api/admin/payouts

- **Propósito**: Obtener historial de pagos
- **Response:**


  ```json
  {
    "payouts": [
      {
        "id": "uuid",
        "amount": 500.00,
        "method": "binance",
        "transaction_ref": "TX12345",
        "notes": "Pago quincenal",
        "receipt_url": "/uploads/receipts/...",
        "status": "completed",
        "created_at": "2025-12-06T10:30:00Z",
        "created_by_email": "admin`@sweet.com`"
      }
    ],
    "total_paid": 2500.00,
    "total_count": 5
  }
  ```

### GET /api/admin/user-balance/:user_id

- **Propósito**: Obtener detalles financieros del usuario
- **Response:**


  ```json
  {
    "user_id": "uuid",
    "email": "modelo`@sweet.com`",
    "pending_balance": 1500.00,
    "total_earned": 5000.00,
    "total_paid": 3500.00,
    "last_payout_date": "2025-12-01T15:20:00Z"
  }
  ```

#### 3. Generación de PDF

**Función:** `generate_payout_receipt()`
- Usa librería `printpdf` (ya instalada)
- Genera recibo simple con:
  - Logo/Título: "SWEET MODELS ENTERPRISE"
  - Receipt ID
  - Fecha y hora
  - Destinatario (email)
  - Monto pagado
  - Método de pago
  - Referencia de transacción
  - Footer con información de contacto
- Guarda en `./uploads/receipts/receipt_{uuid}.pdf`
- Retorna URL: `/uploads/receipts/receipt_xxx.pdf`


### ✅ Frontend (Flutter)

#### 1. Servicio (`payout_service.dart`)

**Clase `PayoutService`:**
- `processPayout()`: Envía solicitud de pago al backend
- `getPayoutHistory()`: Obtiene historial
- `getUserBalance()`: Obtiene detalles de balance
- `cachePayoutHistory()`: Cache offline
- `getCachedPayoutHistory()`: Recupera cache
**Modelos de Datos:**
- `PayoutResponse`: Respuesta de pago exitoso
- `PayoutHistoryResponse`: Lista de pagos
- `PayoutRecord`: Registro individual de pago
- `UserBalanceResponse`: Detalles financieros
**Riverpod Providers:**


```dart
payoutServiceProvider          // Singleton del servicio
userBalanceProvider(userId)    // FutureProvider para balance
payoutHistoryProvider(userId)  // FutureProvider para historial
payoutNotifierProvider         // StateNotifier para operaciones

```

#### 2. UI (`model_profile_screen.dart`)

**Pantalla Principal:**
- Card de saldo con:
  - Saldo pendiente (grande, verde)
  - Total ganado (azul)
  - Total pagado (naranja)
  - Botón "Liquidar Saldo" (solo si balance > 0)
  - Última fecha de pago
**Historial de Pagos:**
- Lista de todos los pagos realizados
- Card resumen: Total de pagos + monto acumulado
- Cada pago muestra:
  - Monto
  - Método (con ícono y color)
  - Referencia de transacción
  - Notas
  - Fecha
  - Botón de recibo (si existe)
**Modal de Liquidación:**


```text
┌─────────────────────────────────┐
│ 💳 Liquidar Saldo              │
├─────────────────────────────────┤
│ Saldo disponible: $1,500.00    │
│                                 │
│ [Monto a pagar: $_____]         │
│                                 │
│ [Método ▼]                      │
│   💰 Binance                    │
│   🏦 Transferencia Bancaria     │
│   💵 Efectivo                   │
│   📝 Otro                       │
│                                 │
│ [Ref. transacción: _______]    │
│                                 │
│ [Notas: _______________]        │
│                                 │
│ [Cancelar] [Confirmar Pago]    │
└─────────────────────────────────┘

```

**Animación de Éxito:**


```text
┌─────────────────────────────────┐
│         ✅                      │
│    ¡Pago Exitoso!              │
│                                 │
│    $500.00 pagados             │
│    Nuevo saldo: $1,000.00      │
│    Recibo generado             │
│                                 │
│         [Cerrar]               │
└─────────────────────────────────┘
(Se cierra automáticamente en 3s)

```

## 🔄 Flujo Completo

```text
1. Admin abre perfil de modelo
   ├─> Se carga balance actual
   ├─> Se carga balance actual
   ├─> Se muestra historial de pagos
   └─> Botón "Liquidar Saldo" visible si balance > 0

2. Admin presiona "Liquidar Saldo"
   └─> Modal se abre con:
   └─> Modal se abre con:
       ├─> Saldo disponible pre-llenado
       ├─> Campos: Monto, Método, Ref, Notas
       └─> Botón "Confirmar Pago"

3. Admin completa formulario y confirma
   ├─> Validación frontend (monto > 0, <= balance)
   ├─> Validación frontend (monto > 0, <= balance)
   ├─> Dialog de "Procesando pago..."
   └─> POST /api/admin/payout

4. Backend procesa (transacción SQL):
   ├─> Inserta registro en payouts
   ├─> Inserta registro en payouts
   ├─> Actualiza pending_balance en users
   ├─> Genera PDF de recibo
   └─> Retorna confirmación + nueva balance

5. Frontend recibe respuesta:
   ├─> Cierra dialog de procesamiento
   ├─> Cierra dialog de procesamiento
   ├─> Muestra animación de éxito
   ├─> Actualiza balance (pending_balance = nueva_balance)
   ├─> Refresca historial de pagos
   └─> Auto-cierra después de 3 segundos

6. Nuevo estado:
   ├─> Saldo pendiente: $0.00 (o reducido)
   ├─> Saldo pendiente: $0.00 (o reducido)
   ├─> Historial actualizado con nuevo pago
   └─> Recibo PDF disponible para descarga

```

## 🎨 Características de UI

### Validaciones Frontend

- ✅ Monto debe ser > 0
- ✅ Monto no puede exceder saldo disponible
- ✅ Método de pago requerido
- ✅ Referencia y notas opcionales


### Feedback Visual

- 🟢 Verde: Saldo pendiente positivo
- 🔵 Azul: Total ganado
- 🟠 Naranja: Total pagado
- 🟣 Morado: Botones de acción
- ✅ Verde: Éxito
- ❌ Rojo: Errores


### Íconos por Método

- 💰 Binance → Bitcoin (orange)
- 🏦 Banco → Bank (blue)
- 💵 Efectivo → Money (green)
- 📝 Otro → Payment (grey)


### Animaciones

- CircularProgressIndicator durante procesamiento
- Check circle grande en éxito
- Auto-dismiss después de 3 segundos
- Pull-to-refresh en lista de historial


## 📊 Ejemplo de Datos

### Antes del Pago

```text
Modelo: modelo`@sweet.com`
├─ Saldo Pendiente: $1,500.00
├─ Total Ganado: $5,000.00
└─ Total Pagado: $3,500.00

```

### Después del Pago ($500)

```text
Modelo: modelo`@sweet.com`
├─ Saldo Pendiente: $1,000.00  ⬅️ REDUCIDO
├─ Total Ganado: $5,000.00
└─ Total Pagado: $4,000.00  ⬅️ INCREMENTADO

Historial Actualizado:
┌──────────────────────────────────────┐
│ 💰 $500.00 - Binance                │
│ Ref: TX123456789                    │
│ Nota: Pago quincenal Diciembre     │
│ 06/12/2025 10:30                    │
│ Por: admin`@sweet.com`                │
│ [📄 Ver Recibo]                     │
└──────────────────────────────────────┘

```

## 🔐 Seguridad

### Backend

- ✅ Solo rol `admin` puede procesar pagos
- ✅ Validación de saldo suficiente
- ✅ Transacción SQL atómica (rollback en error)
- ✅ Auditoría: `created_by` registra quién hizo el pago
- ✅ Timestamps automáticos


### Frontend

- ✅ Token JWT requerido en headers
- ✅ Validación de inputs antes de enviar
- ✅ Manejo de errores con mensajes claros
- ✅ Cache offline solo de historial (no de operaciones)


## 🧪 Testing

### Casos de Prueba

#### 1. Pago Exitoso

```text
Given: Modelo con $1,500 pendiente
When: Admin liquida $500 vía Binance
Then:

  - Saldo nuevo = $1,000
  - Pago registrado en historial
  - PDF generado
  - Balance actualizado en UI


```

#### 2. Saldo Insuficiente

```text
Given: Modelo con $100 pendiente
When: Admin intenta liquidar $200
Then: Error "Insufficient balance"

```

#### 3. Liquidación Total

```text
Given: Modelo con $1,500 pendiente
When: Admin liquida $1,500
Then:

  - Saldo nuevo = $0.00
  - Botón "Liquidar Saldo" se oculta
  - Total pagado = total ganado


```

#### 4. Métodos de Pago

```text
✅ Binance con TX ref
✅ Banco con número de cuenta
✅ Efectivo sin ref
✅ Otro con nota personalizada

```

## 📁 Archivos Creados

### Backend - Archivos

```text
backend_api/
├── migrations/
│   └── 011_payouts.sql                    [NEW] ✅
└── src/
    └── main.rs                             [UPDATED] ✅
        ├── Structs: PayoutRequest, PayoutResponse, etc.
        ├── Functions: process_payout(), generate_payout_receipt()
        └─ Routes: /api/admin/payout, /api/admin/payouts

```

### Frontend - Archivos

```text
mobile_app/
└── lib/
    ├── services/
    │   └── payout_service.dart             [NEW] ✅
    │       ├── PayoutService class
    │       ├── Data models
    │       └── Riverpod providers
    └── screens/
        └── model_profile_screen.dart       [NEW] ✅
            ├── Balance card
            ├── Payout history list
            ├── Liquidation modal
            └── Success animation

```

## 🚀 Próximos Pasos

1. **Integrar en Admin Dashboard:**
   - Agregar botón en lista de modelos
   - Link directo a `ModelProfileScreen`
2. **Notificaciones:**
   - Push notification cuando se recibe pago
   - Email con recibo adjunto
3. **Reportes:**
   - Export de payouts a CSV/Excel
   - Gráficas de pagos por mes
4. **Multi-divisa:**
   - Soporte para pagos en COP, USD, BTC
   - Conversión automática
5. **Automatización:**
   - Pagos programados (quincenal/mensual)
   - Auto-liquidación cuando saldo > threshold
---
**Estado:** ✅ COMPLETADO
**Fecha:** 06 de Diciembre, 2025
**Desarrollador:** GitHub Copilot + User
