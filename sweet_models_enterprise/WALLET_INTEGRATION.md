# 💳 WalletScreen - Documentación de Integración

## 📋 Descripción
`WalletScreen` es una pantalla profesional de fintech que integra:
- Tarjeta de saldo estilo crédito
- Gráfico de rendimiento (últimos 7 días)
- Historial de transacciones
- Modal de retiro de USDT

## 📁 Archivos Creados

### 1. **FinanceService** (`lib/services/finance_service.dart`)
Servicio que maneja toda la comunicación con el backend de finanzas.

**Métodos principales:**
```dart
Future<bool> fetchBalance({String? token})
Future<WithdrawResponse?> requestWithdrawal({
  required double amountUsdt,
  required String walletAddress,
  String? token,
})
Future<bool> fetchWithdrawals({String? token})
List<MapEntry<int, double>> getPerformanceData()
List<Transaction> getRecentTransactions({int limit = 10})
```

**Modelos de datos:**
- `BalanceData`: Respuesta de balance del usuario
- `Transaction`: Registro de transacción (EARNING, WITHDRAWAL, PENALTY)
- `WithdrawalRecord`: Solicitud de retiro
- `WithdrawResponse`: Confirmación de retiro

### 2. **BalanceCard** (`lib/widgets/balance_card.dart`)
Tarjeta principal que muestra:
- Logo "SWEET MODELS"
- Saldo en TK (grandes números)
- Equivalente en USD
- Botón de retiro brillante (Cyan neón)

**Propiedades:**
```dart
BalanceCard(
  balance: 15400.0,
  onWithdrawPressed: () { /* Abrir modal */ }
)
```

### 3. **PerformanceChart** (`lib/widgets/performance_chart.dart`)
Gráfico de líneas con fl_chart que muestra:
- Ganancias últimos 7 días
- Línea verde neón (#00FF00)
- Área degradada bajo la curva
- Tooltips interactivos

**Propiedades:**
```dart
PerformanceChart(
  performanceData: financeService.getPerformanceData()
)
```

### 4. **TransactionList** (`lib/widgets/transaction_list.dart`)
Lista de transacciones con:
- Iconos de tipo (flecha arriba/abajo, cruz)
- Colores por tipo (verde ingreso, rojo retiro, naranja penalización)
- Tiempo relativo ("Hace 5 minutos")
- Monto con signo

**Componentes:**
- `TransactionTile`: Widget individual
- `TransactionList`: Contenedor con ListView

### 5. **WithdrawModal** (`lib/widgets/withdraw_modal.dart`)
Modal completo para solicitar retiro:
- Campo de monto con cantidades rápidas (100, 500, 1000, 5000 TK)
- Campo de dirección Ethereum
- Checkbox de confirmación
- Conversión TK → USD en tiempo real
- Aviso de tarifa

### 6. **WalletScreen** (`lib/screens/wallet_screen.dart`)
Pantalla principal que orquesta todo:
- RefreshIndicator para actualizar datos
- Carga de datos en initState
- Consumer de Provider para reactividad
- Manejo de errores y loading

## 🔧 Integración en Aplicación

### 1. Agregar Provider en main.dart
```dart
import 'package:provider/provider.dart';
import 'package:sweet_models_mobile/services/finance_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceService()),
        // ... otros providers
      ],
      child: const MyApp(),
    ),
  );
}
```

### 2. Agregar ruta en GoRouter
```dart
GoRoute(
  path: '/wallet',
  builder: (context, state) => const WalletScreen(),
),
```

### 3. Uso en NavigationBar
```dart
onDestinationSelected: (int index) {
  if (index == 3) {
    context.go('/wallet');
  }
}
```

## 🎨 Paleta de Colores (Shadcn Dark)

| Elemento | Color | Hex |
|----------|-------|-----|
| Fondo | Casi negro | #0F0F0F |
| Tarjetas | Gris oscuro | #1a1a1a |
| Primario | Cyan neón | #00F5FF |
| Éxito | Verde neón | #00FF00 |
| Error | Rojo | #FF4444 |
| Warning | Naranja | #FF9500 |
| Texto | Gris | #888888 |

## 📊 Flujo de Datos

```
WalletScreen (StatefulWidget)
├── initState → fetchBalance()
├── Consumer<FinanceService>
│   ├── BalanceCard
│   │   └── onWithdraw → showWithdrawModal()
│   ├── PerformanceChart
│   │   └── getPerformanceData()
│   └── TransactionList
│       └── getRecentTransactions()
└── RefreshIndicator → _loadWalletData()
```

## 🔌 Endpoints Backend Requeridos

### GET `/api/finance/balance`
```json
{
  "user_id": "uuid",
  "total_balance": 15400.0,
  "transactions": [...]
}
```

### POST `/api/finance/withdraw`
**Payload:**
```json
{
  "amount_usdt": 100.0,
  "wallet_address": "0x742d35Cc..."
}
```
**Respuesta (202 Accepted):**
```json
{
  "withdrawal_id": "uuid",
  "status": "PENDING",
  "message": "Withdrawal request created..."
}
```

### GET `/api/finance/withdrawals`
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "amount_usdt": 100.0,
    "wallet_address": "0x...",
    "status": "PENDING",
    "blockchain_tx_hash": null,
    "created_at": "2025-12-09T..."
  }
]
```

## 🧪 Testing

### 1. Mock Data (Desarrollo)
```dart
// FinanceService genera datos simulados localmente
final performanceData = financeService.getPerformanceData();
// Retorna últimos 7 días de ganancias aleatorias
```

### 2. Prueba con Backend Real
```dart
// En WalletScreen initState
await financeService.fetchBalance(token: userToken);
```

### 3. Manejo de Errores
```dart
if (financeService.errorMessage.isNotEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(financeService.errorMessage))
  );
}
```

## 📱 Responsive Design

- **Mobile (< 600px)**: Layout vertical, 100% width
- **Tablet (600-900px)**: Cards side-by-side
- **Desktop (> 900px)**: Multi-column con sidebar

Implementado con `MediaQuery` y `LayoutBuilder` si es necesario.

## 🔐 Seguridad

- Tokens JWT extraídos del header `Authorization: Bearer {token}`
- Direcciones Ethereum validadas antes de envío
- Confirmación obligatoria de dirección correcta
- Tarifa transparente mostrada antes del retiro

## 🚀 Próximos Pasos

1. **Web3 Integration**: Transferencias reales de USDT en blockchain
2. **Biometric Auth**: Confirmación con huella/Face ID
3. **Historial Exportable**: Descargar transacciones como PDF/CSV
4. **Notificaciones**: Push cuando se completa un retiro
5. **Análisis Avanzado**: Gráficos de ingresos vs gastos

## 📞 Soporte

Para problemas con:
- **Backend**: Verificar endpoints en `/api/finance/*`
- **UI**: Revisar colores en `Color(0xFF...)`
- **State**: Debugging con `Provider.watch()`
- **Charts**: Consultar documentación de `fl_chart`
