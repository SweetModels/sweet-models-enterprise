# 💰 Módulo de Pagos - Sweet Models Enterprise

## Descripción General

Sistema completo de liquidación de pagos para modelos con integración backend Rust/Axum.

## Archivos del Módulo

### 1. `payments_provider.dart`

- **Responsabilidad**: Gestión de estado y comunicación con backend
- **Métodos principales**:
  - `fetchBalance()`: Obtiene saldo pendiente del usuario
  - `fetchHistory()`: Obtiene historial de pagos
  - `processPayout()`: Registra un nuevo pago en backend

### 2. `payout_dialog.dart`

- **Responsabilidad**: BottomSheet modal para realizar pagos
- **Características**:
  - Validación de monto (0 < monto <= saldo_pendiente)
  - Selector de método (Binance, Nequi, Efectivo)
  - Campo referencia/TXID
  - Animación Lottie de éxito

### 3. `user_profile_screen.dart`

- **Responsabilidad**: Pantalla principal de perfil de modelo (Admin)
- **Secciones**:
  - Card gigante de saldo pendiente (rojo/verde según monto)
  - Botón "💸 LIQUIDAR PAGO"
  - Tabs: "Datos" e "Historial de Pagos"

### 4. `payout_history_screen.dart`

- **Responsabilidad**: Pantalla dedicada al historial de transacciones
- **Datos mostrados**: Fecha, Monto, Método, Referencia, Admin que procesó

### 5. `admin_payments_example.dart`

- **Responsabilidad**: Ejemplo de integración
- **Uso**: Reemplaza `userId` y `adminToken` con valores reales

## Integración en tu App

### En `main.dart`

```dart
import 'payments/admin_payments_example.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweet Models',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AdminPaymentsExample(),
    );
  }
}
```

## Endpoints Backend Requeridos

### 1. GET `/api/admin/user-balance/{user_id}`

**Headers**: `Authorization: Bearer {token}`
**Response**:

```json
{
  "user_id": "uuid",
  "email": "model@example.com",
  "total_earned": 1000.0,
  "total_paid": 200.0,
  "pending_balance": 800.0,
  "last_payout_date": "2025-12-05T10:30:00Z"
}
```

### 2. GET `/api/admin/payouts/{user_id}`

**Headers**: `Authorization: Bearer {token}`
**Response**:

```json
{
  "payouts": [
    {
      "id": "uuid",
      "amount": 100.0,
      "method": "Binance",
      "reference_id": "REF123",
      "notes": null,
      "created_at": "2025-12-05T10:30:00Z",
      "processed_by_email": "admin@example.com"
    }
  ],
  "total_paid": 200.0,
  "total_count": 2
}
```

### 3. POST `/api/admin/payout`

**Headers**:

- `Authorization: Bearer {token}`
- `Content-Type: application/json`

**Body**:

```json
{
  "user_id": "uuid",
  "amount": 100.0,
  "method": "Binance",
  "reference_id": "REF123",
  "notes": "Pago mensual"
}
```

**Response** (201 Created):

```json
{
  "payout_id": "uuid",
  "user_id": "uuid",
  "amount": 100.0,
  "method": "Binance",
  "reference_id": "REF123",
  "new_pending_balance": 700.0,
  "message": "Payout registered successfully",
  "created_at": "2025-12-06T10:30:00Z"
}
```

## Flujo de Uso

1. **Admin abre perfil de modelo**
   - Se carga `UserProfileScreen`
   - `PaymentsProvider.fetchBalance()` obtiene saldo
   - Se muestra card con saldo pendiente

2. **Admin toca "💸 LIQUIDAR PAGO"**
   - Se abre `PayoutDialog` en BottomSheet
   - Muestra saldo actual
   - Admin ingresa monto, método y referencia

3. **Admin confirma transacción**
   - `PaymentsProvider.processPayout()` envía POST al backend
   - Backend valida y registra pago
   - Si OK: animación Lottie verde ✓
   - Saldo se actualiza automáticamente

4. **Historial visible en pestaña**
   - Lista de pagos anteriores con detalles
   - Sin necesidad de recargar la app

## Assets Requeridos

- `assets/lottie/success_check.json` (Animación Lottie de check verde)
- Registrada en `pubspec.yaml`:

  ```yaml
  flutter:
    assets:
      - assets/lottie/success_check.json
  ```

## Dependencias

```yaml
provider: ^6.0.0           # State management
http: ^1.6.0               # HTTP client
lottie: ^2.7.0             # Animaciones
```

## Notas de Seguridad

- ✅ Token JWT se valida en cada request
- ✅ Backend valida monto <= saldo_pendiente
- ✅ Solo admins pueden procesar pagos
- ✅ Auditoria: Se registra processed_by (admin UUID)

## Testing

Para probar localmente:

1. Obtén un token admin:

   ```bash
   curl -X POST http://localhost:3000/login \
     -H "Content-Type: application/json" \
     -d '{"email":"admin@example.com","password":"password"}'
   ```

2. Copia el `access_token` en `admin_payments_example.dart`

3. Obtén un UUID de modelo y reemplázalo en el mismo archivo

4. Ejecuta:

   ```bash
   flutter run
   ```

## TODO Futuro

- [ ] Agregar más métodos de pago dinámicamente
- [ ] Notificaciones en tiempo real cuando se procesa pago
- [ ] Gráficos de historial de pagos
- [ ] Exportar historial a PDF
- [ ] Comprobantes digitales firmados
