import 'package:flutter/material.dart';
import 'package:sweet_models_mobile/services/pdf_receipt_service.dart';

/// Widget que proporciona botones para generar y compartir recibos PDF
class ReceiptDownloadWidget extends StatefulWidget {
  final String modelName;
  final double amount;
  final String paymentMethod;
  final String transactionId;
  final String processedBy;
  final String? bankDetails;

  const ReceiptDownloadWidget({
    Key? key,
    required this.modelName,
    required this.amount,
    required this.paymentMethod,
    required this.transactionId,
    required this.processedBy,
    this.bankDetails,
  }) : super(key: key);

  @override
  State<ReceiptDownloadWidget> createState() => _ReceiptDownloadWidgetState();
}

class _ReceiptDownloadWidgetState extends State<ReceiptDownloadWidget> {
  bool _isLoading = false;
  String? _errorMessage;

  /// Genera y comparte el recibo PDF
  Future<void> _generateAndShare() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final receipt = PayoutReceipt(
        modelName: widget.modelName,
        amount: widget.amount,
        date: DateTime.now(),
        paymentMethod: widget.paymentMethod,
        transactionId: widget.transactionId,
        processedBy: widget.processedBy,
        bankDetails: widget.bankDetails,
      );

      await PdfReceiptService.shareReceipt(receipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recibo compartido exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final errorMsg = _extractErrorMessage(e);
      
      setState(() {
        _errorMessage = errorMsg;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Descarga el recibo al almacenamiento local
  Future<void> _downloadReceipt() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final receipt = PayoutReceipt(
        modelName: widget.modelName,
        amount: widget.amount,
        date: DateTime.now(),
        paymentMethod: widget.paymentMethod,
        transactionId: widget.transactionId,
        processedBy: widget.processedBy,
        bankDetails: widget.bankDetails,
      );

      await PdfReceiptService.downloadReceipt(receipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recibo descargado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final errorMsg = _extractErrorMessage(e);
      
      setState(() {
        _errorMessage = errorMsg;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Imprime el recibo
  Future<void> _printReceipt() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final receipt = PayoutReceipt(
        modelName: widget.modelName,
        amount: widget.amount,
        date: DateTime.now(),
        paymentMethod: widget.paymentMethod,
        transactionId: widget.transactionId,
        processedBy: widget.processedBy,
        bankDetails: widget.bankDetails,
      );

      await PdfReceiptService.printReceipt(receipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Abriendo vista previa de impresión'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final errorMsg = _extractErrorMessage(e);
      
      setState(() {
        _errorMessage = errorMsg;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Extrae mensaje de error de diferentes tipos de excepción
  String _extractErrorMessage(dynamic error) {
    if (error is ArgumentError) {
      return error.message ?? 'Datos inválidos';
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Error desconocido';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mostrar mensaje de error si existe
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Botón Compartir Recibo
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _generateAndShare,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.share),
            label: Text(
              _isLoading ? 'Generando recibo...' : '📄 Compartir Recibo PDF',
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              disabledBackgroundColor: Colors.blue.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Botón Descargar Recibo
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _downloadReceipt,
            icon: const Icon(Icons.download),
            label: const Text(
              '💾 Descargar Recibo',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              disabledForegroundColor: Colors.blue.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Botón Imprimir Recibo
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _printReceipt,
            icon: const Icon(Icons.print),
            label: const Text(
              '🖨️ Imprimir Recibo',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              disabledForegroundColor: Colors.green.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
