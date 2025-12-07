import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Modelo que representa un comprobante de pago
class PayoutReceipt {
  final String modelName;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String transactionId;
  final String processedBy;
  final String? bankDetails;

  /// Constructor con validaciones básicas
  PayoutReceipt({
    required this.modelName,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.transactionId,
    required this.processedBy,
    this.bankDetails,
  }) {
    // Validaciones
    if (modelName.isEmpty) throw ArgumentError('modelName no puede estar vacío');
    if (amount <= 0) throw ArgumentError('amount debe ser mayor a 0');
    if (paymentMethod.isEmpty) throw ArgumentError('paymentMethod no puede estar vacío');
    if (transactionId.isEmpty) throw ArgumentError('transactionId no puede estar vacío');
    if (processedBy.isEmpty) throw ArgumentError('processedBy no puede estar vacío');
  }

  /// Crea una representación en string del recibo
  @override
  String toString() => 'PayoutReceipt(model: $modelName, amount: $amount, id: $transactionId)';
}

/// Servicio para generar, compartir e imprimir recibos en PDF
class PdfReceiptService {
  static const String _logoText = 'SWEET MODELS';
  static const String _companySubtitle = 'Enterprise System';
  static const String _validationMsg = 'Comprobante de Pago Válido';

  /// Genera un PDF con el comprobante de pago
  /// 
  /// Lanza [ArgumentError] si los datos del recibo son inválidos
  /// Lanza [PlatformException] si hay error en la generación del PDF
  static Future<Uint8List> generateReceipt(PayoutReceipt receipt) async {
    try {
      final pdf = pw.Document();

      final dateFormat = DateFormat('dd/MM/yyyy - hh:mm a', 'es_ES');
      final currencyFormat = NumberFormat.currency(
        locale: 'es_CO',
        symbol: '\$',
        decimalDigits: 0,
      );

      // Sanitizar datos para prevenir inyecciones
      final sanitizedModelName = _sanitizeText(receipt.modelName);
      final sanitizedPaymentMethod = _sanitizeText(receipt.paymentMethod);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Encabezado
                pw.Container(
                  alignment: pw.Alignment.center,
                  margin: pw.EdgeInsets.only(bottom: 30),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        _logoText,
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor(0.8, 0.2, 0.6), // Rosa/Magenta
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _companySubtitle,
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColor(0.5, 0.5, 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divisor
                pw.Divider(
                  thickness: 2,
                  color: PdfColor(0.8, 0.2, 0.6),
                ),

                pw.SizedBox(height: 20),

                // Título del comprobante
                pw.Container(
                  alignment: pw.Alignment.center,
                  margin: pw.EdgeInsets.only(bottom: 20),
                  child: pw.Text(
                    _validationMsg,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor(0.1, 0.1, 0.1),
                    ),
                  ),
                ),

                // Número de transacción
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ID Transacción:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      receipt.transactionId,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 15),

                // Tabla de detalles
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColor(0.8, 0.8, 0.8),
                      width: 1,
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      // Encabezado tabla
                      pw.Container(
                        color: PdfColor(0.95, 0.95, 0.95),
                        padding: pw.EdgeInsets.all(10),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                'CONCEPTO',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                'VALOR',
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Fila 1: Modelo
                      _buildTableRow(
                        'Modelo: $sanitizedModelName',
                        currencyFormat.format(receipt.amount.toInt()),
                      ),

                      // Fila 2: Método de pago
                      _buildTableRow(
                        'Método: $sanitizedPaymentMethod',
                        '',
                      ),

                      // Fila 3: Procesado por
                      _buildTableRow(
                        'Procesado por: ${_sanitizeText(receipt.processedBy)}',
                        '',
                      ),

                      // Fila 4: Fecha
                      _buildTableRow(
                        'Fecha: ${dateFormat.format(receipt.date)}',
                        '',
                      ),

                      // Divisor
                      pw.Divider(
                        height: 1,
                        color: PdfColor(0.8, 0.8, 0.8),
                      ),

                      // Total
                      pw.Container(
                        padding: pw.EdgeInsets.all(10),
                        color: PdfColor(0.98, 0.98, 0.98),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TOTAL PAGADO:',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              currencyFormat.format(receipt.amount.toInt()),
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor(0.2, 0.7, 0.2), // Verde
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Detalles bancarios (si existen)
                if (receipt.bankDetails != null && receipt.bankDetails!.isNotEmpty) ...[
                  pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColor(0.9, 0.9, 0.9),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INFORMACIÓN BANCARIA:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          _sanitizeText(receipt.bankDetails!),
                          style: pw.TextStyle(
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Pie de página
                pw.Spacer(),
                pw.Divider(
                  thickness: 1,
                  color: PdfColor(0.8, 0.8, 0.8),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Generado automáticamente por Sweet Models Enterprise System\nEste es un comprobante digital válido.',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor(0.6, 0.6, 0.6),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      throw PlatformException(
        code: 'PDF_GENERATION_ERROR',
        message: 'Error generando PDF: ${e.toString()}',
      );
    }
  }

  /// Widget auxiliar para filas de tabla
  static pw.Widget _buildTableRow(String label, String value) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor(0.95, 0.95, 0.95),
            width: 0.5,
          ),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Sanitiza texto para prevenir inyecciones
  static String _sanitizeText(String text) {
    return text
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .trim();
  }

  /// Abre el diálogo nativo de compartir con el PDF generado
  static Future<void> shareReceipt(PayoutReceipt receipt) async {
    try {
      final pdfData = await generateReceipt(receipt);
      final fileName =
          'Comprobante_${receipt.modelName}_${receipt.transactionId}.pdf'
              .replaceAll(' ', '_')
              .replaceAll('<', '')
              .replaceAll('>', '');

      await Share.shareXFiles(
        [
          XFile.fromData(
            pdfData,
            mimeType: 'application/pdf',
            name: fileName,
          ),
        ],
        subject: 'Comprobante de Pago - ${receipt.modelName}',
        text: 'Comprobante de pago por \$${receipt.amount.toStringAsFixed(0)}',
      );
    } on PlatformException catch (e) {
      throw PlatformException(
        code: 'SHARE_ERROR',
        message: 'Error compartiendo recibo: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado compartiendo recibo: ${e.toString()}');
    }
  }

  /// Abre el PDF en la aplicación de visualización nativa
  static Future<void> printReceipt(PayoutReceipt receipt) async {
    try {
      final pdfData = await generateReceipt(receipt);
      await Printing.layoutPdf(
        onLayout: (_) => pdfData,
      );
    } on PlatformException catch (e) {
      throw PlatformException(
        code: 'PRINT_ERROR',
        message: 'Error imprimiendo recibo: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado imprimiendo recibo: ${e.toString()}');
    }
  }

  /// Descarga el PDF al almacenamiento del dispositivo
  static Future<void> downloadReceipt(PayoutReceipt receipt) async {
    try {
      final pdfData = await generateReceipt(receipt);
      final fileName =
          'Comprobante_${receipt.modelName}_${receipt.transactionId}.pdf'
              .replaceAll(' ', '_')
              .replaceAll('<', '')
              .replaceAll('>', '');

      await Printing.sharePdf(
        bytes: pdfData,
        filename: fileName,
      );
    } on PlatformException catch (e) {
      throw PlatformException(
        code: 'DOWNLOAD_ERROR',
        message: 'Error descargando recibo: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado descargando recibo: ${e.toString()}');
    }
  }
}

class PdfReceiptService {
  static const String _logoText = 'SWEET MODELS';
  static const String _companySubtitle = 'Enterprise System';

  /// Genera un PDF con el comprobante de pago
  static Future<Uint8List> generateReceipt(PayoutReceipt receipt) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy - hh:mm a', 'es_ES');
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Encabezado
              pw.Container(
                alignment: pw.Alignment.center,
                margin: pw.EdgeInsets.only(bottom: 30),
                child: pw.Column(
                  children: [
                    pw.Text(
                      _logoText,
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor(0.8, 0.2, 0.6), // Rosa/Magenta
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _companySubtitle,
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor(0.5, 0.5, 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Divisor
              pw.Divider(
                thickness: 2,
                color: PdfColor(0.8, 0.2, 0.6),
              ),

              pw.SizedBox(height: 20),

              // Título del comprobante
              pw.Container(
                alignment: pw.Alignment.center,
                margin: pw.EdgeInsets.only(bottom: 20),
                child: pw.Text(
                  'COMPROBANTE DE PAGO',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor(0.1, 0.1, 0.1),
                  ),
                ),
              ),

              // Número de transacción
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'ID Transacción:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    receipt.transactionId,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 15),

              // Tabla de detalles
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColor(0.8, 0.8, 0.8),
                    width: 1,
                  ),
                ),
                child: pw.Column(
                  children: [
                    // Encabezado tabla
                    pw.Container(
                      color: PdfColor(0.95, 0.95, 0.95),
                      padding: pw.EdgeInsets.all(10),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'CONCEPTO',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              'VALOR',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Fila 1: Modelo
                    _buildTableRow(
                      'Modelo: ${receipt.modelName}',
                      currencyFormat.format(receipt.amount.toInt()),
                    ),

                    // Fila 2: Método de pago
                    _buildTableRow(
                      'Método: ${receipt.paymentMethod}',
                      '',
                    ),

                    // Fila 3: Procesado por
                    _buildTableRow(
                      'Procesado por: ${receipt.processedBy}',
                      '',
                    ),

                    // Fila 4: Fecha
                    _buildTableRow(
                      'Fecha: ${dateFormat.format(receipt.date)}',
                      '',
                    ),

                    // Divisor
                    pw.Divider(
                      height: 1,
                      color: PdfColor(0.8, 0.8, 0.8),
                    ),

                    // Total
                    pw.Container(
                      padding: pw.EdgeInsets.all(10),
                      color: PdfColor(0.98, 0.98, 0.98),
                      child: pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL PAGADO:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            currencyFormat.format(receipt.amount.toInt()),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor(0.2, 0.7, 0.2), // Verde
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Detalles bancarios (si existen)
              if (receipt.bankDetails != null) ...[
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColor(0.9, 0.9, 0.9),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INFORMACIÓN BANCARIA:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        receipt.bankDetails!,
                        style: pw.TextStyle(
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // Pie de página
              pw.Spacer(),
              pw.Divider(
                thickness: 1,
                color: PdfColor(0.8, 0.8, 0.8),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Generado automáticamente por Sweet Models Enterprise System\nEste es un comprobante digital válido.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor(0.6, 0.6, 0.6),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Widget auxiliar para filas de tabla
  static pw.Widget _buildTableRow(String label, String value) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor(0.95, 0.95, 0.95),
            width: 0.5,
          ),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Abre el diálogo nativo de compartir con el PDF generado
  static Future<void> shareReceipt(PayoutReceipt receipt) async {
    try {
      final pdfData = await generateReceipt(receipt);
      final fileName =
          'Comprobante_${receipt.modelName}_${receipt.transactionId}.pdf';

      // Compartir el PDF
      await Share.shareXFiles(
        [
          XFile.fromData(
            pdfData,
            mimeType: 'application/pdf',
            name: fileName,
          ),
        ],
        subject: 'Comprobante de Pago - ${receipt.modelName}',
        text: 'Comprobante de pago por \$${receipt.amount.toStringAsFixed(0)}',
      );
    } catch (e) {
      print('Error compartiendo recibo: $e');
      rethrow;
    }
  }

  /// Abre el PDF en la aplicación de visualización nativa
  static Future<void> printReceipt(PayoutReceipt receipt) async {
    try {
      final pdfData = await generateReceipt(receipt);
      await Printing.layoutPdf(
        onLayout: (_) => pdfData,
      );
    } catch (e) {
      print('Error imprimiendo recibo: $e');
      rethrow;
    }
  }

  /// Descarga el PDF al almacenamiento del dispositivo
  static Future<void> downloadReceipt(PayoutReceipt receipt) async {
    try {
      final pdfData = await generateReceipt(receipt);
      final fileName =
          'Comprobante_${receipt.modelName}_${receipt.transactionId}.pdf';

      await Printing.sharePdf(
        bytes: pdfData,
        filename: fileName,
      );
    } catch (e) {
      print('Error descargando recibo: $e');
      rethrow;
    }
  }
}
