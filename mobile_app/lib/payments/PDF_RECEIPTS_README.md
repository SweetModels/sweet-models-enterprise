# 📄 Módulo de Recibos PDF - Documentación

## 📋 Descripción General

El módulo de recibos PDF permite generar, compartir y descargar comprobantes profesionales de pago en formato PDF. Los recibos incluyen:

- Logo y branding de "SWEET MODELS"
- Datos del modelo (nombre, monto)
- Método de pago utilizado
- ID de transacción único
- Información del administrador que procesó el pago
- Detalles bancarios (opcional)
- Timestamp de la transacción

## 📦 Dependencias Requeridas

```yaml
dependencies:
  # PDF generation
  pdf: ^3.10.0
  printing: ^5.11.0
  share_plus: ^7.2.0
```

### Instalación:

```bash
cd mobile_app
flutter pub get
```

## 🔧 Estructura del Código

### 1. Clase `PayoutReceipt`

Modelo de datos que contiene toda la información del recibo:

```dart
PayoutReceipt(
  modelName: 'Valentina García',
  amount: 500000,
  date: DateTime.now(),
  paymentMethod: 'Binance',
  transactionId: 'TXN-2025-12-06-001',
  processedBy: 'admin@sweetmodels.com',
  bankDetails: 'Binance: bnb1abc123...', // Opcional
)
```

### 2. Clase `PdfReceiptService`

Servicio principal que maneja la generación y distribución de PDFs.

#### Métodos disponibles:

#### `generateReceipt(PayoutReceipt receipt) → Future<Uint8List>`
Genera el PDF y retorna los bytes.

```dart
final pdfBytes = await PdfReceiptService.generateReceipt(receipt);
```

#### `shareReceipt(PayoutReceipt receipt) → Future<void>`
Abre el diálogo nativo de compartir (WhatsApp, correo, guardar, etc.)

```dart
await PdfReceiptService.shareReceipt(receipt);
```

#### `downloadReceipt(PayoutReceipt receipt) → Future<void>`
Descarga el PDF al almacenamiento del dispositivo.

```dart
await PdfReceiptService.downloadReceipt(receipt);
```

#### `printReceipt(PayoutReceipt receipt) → Future<void>`
Abre el visor de impresión nativa.

```dart
await PdfReceiptService.printReceipt(receipt);
```

### 3. Widget `ReceiptDownloadWidget`

Widget UI que proporciona botones para interactuar con los recibos.

## 📱 Cómo Integrar en tu Pantalla

### Ejemplo 1: Integración en `PayoutDialog`

```dart
import 'package:sweet_models_mobile/widgets/receipt_download_widget.dart';

class PayoutDialog extends StatelessWidget {
  final String modelName;
  final double amount;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          // ... Resto del contenido del diálogo ...
          
          SizedBox(height: 20),
          
          // Agregar widget de recibo
          ReceiptDownloadWidget(
            modelName: modelName,
            amount: amount,
            paymentMethod: 'Binance', // Cambiar según el método
            transactionId: 'TXN-2025-12-06-001',
            processedBy: 'admin@sweetmodels.com',
            bankDetails: 'Binance: bnb1abc123...',
          ),
        ],
      ),
    );
  }
}
```

### Ejemplo 2: Integración en `PayoutHistoryScreen`

```dart
import 'package:sweet_models_mobile/services/pdf_receipt_service.dart';

// En la tarjeta de historial de pagos
ListTile(
  trailing: IconButton(
    icon: Icon(Icons.receipt),
    onPressed: () async {
      final receipt = PayoutReceipt(
        modelName: payout['model_name'],
        amount: payout['amount'].toDouble(),
        date: DateTime.parse(payout['created_at']),
        paymentMethod: payout['payment_method'],
        transactionId: payout['payout_id'],
        processedBy: payout['processed_by'],
      );
      
      await PdfReceiptService.shareReceipt(receipt);
    },
  ),
)
```

## 🎨 Diseño del PDF

El PDF generado tiene la siguiente estructura:

```
┌─────────────────────────────────────┐
│  SWEET MODELS                       │
│  Enterprise System                  │
├─────────────────────────────────────┤
│  COMPROBANTE DE PAGO                │
│                                     │
│  ID Transacción: TXN-2025-12-06-001 │
├─────────────────────────────────────┤
│  CONCEPTO              │      VALOR  │
├─────────────────────────────────────┤
│  Modelo: Valentina G...│   $500.000  │
│  Método: Binance       │             │
│  Procesado por: admin@ │             │
│  Fecha: 06/12/2025     │             │
├─────────────────────────────────────┤
│  TOTAL PAGADO:         │   $500.000  │
├─────────────────────────────────────┤
│                                     │
│  INFORMACIÓN BANCARIA:              │
│  Binance: bnb1abc123...             │
│                                     │
│  Generado automáticamente por       │
│  Sweet Models Enterprise System     │
│  Este es un comprobante digital     │
│  válido.                            │
└─────────────────────────────────────┘
```

## 🔐 Permisos Requeridos

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso a tu galería para guardar recibos</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Necesitamos acceso para guardar recibos</string>
```

## 💡 Casos de Uso

### 1. Generar Recibo después de Pagar

```dart
// En el callback de pago exitoso
if (payoutResponse.success) {
  final receipt = PayoutReceipt(
    modelName: model.name,
    amount: payoutAmount,
    date: DateTime.now(),
    paymentMethod: selectedMethod,
    transactionId: payoutResponse.payoutId,
    processedBy: currentUser.email,
  );
  
  // Compartir automáticamente
  await PdfReceiptService.shareReceipt(receipt);
}
```

### 2. Botón "Descargar Recibo" en Historial

```dart
ElevatedButton(
  onPressed: () async {
    final receipt = PayoutReceipt.fromPayoutRecord(payout);
    await PdfReceiptService.downloadReceipt(receipt);
  },
  child: Text('📄 Descargar Recibo'),
)
```

### 3. Enviar Recibo por Correo (Integration Custom)

```dart
// Extender el servicio para enviar por correo
Future<void> emailReceipt(PayoutReceipt receipt, String toEmail) async {
  final pdfData = await PdfReceiptService.generateReceipt(receipt);
  
  // Integrar con servicio de correo (ej: SendGrid, Mailgun)
  await mailService.sendEmail(
    to: toEmail,
    subject: 'Comprobante de Pago - Sweet Models',
    attachments: [
      EmailAttachment(
        filename: 'Comprobante_${receipt.modelName}.pdf',
        mimeType: 'application/pdf',
        data: pdfData,
      ),
    ],
  );
}
```

## 🐛 Troubleshooting

### Error: "printing plugin not initialized"
- Solución: Asegurate de que el plugin esté instalado: `flutter pub get`

### PDF vacío o sin estilos
- Solución: Verificar que las fuentes de Google están disponibles (conexión a internet)

### No funciona compartir en Android
- Solución: Verificar permisos en `AndroidManifest.xml`

## 📊 Próximas Mejoras

- [ ] Integración con SendGrid para envío automático por correo
- [ ] Soporte para múltiples idiomas/localizaciones
- [ ] QR con referencia de pago para verificación
- [ ] Firma digital del administrador
- [ ] Reporte consolidado de pagos en PDF

## 📞 Soporte

Para preguntas o problemas, contacta a: dev@sweetmodels.com
