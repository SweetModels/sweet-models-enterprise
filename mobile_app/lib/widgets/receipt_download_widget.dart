import 'package:flutter/material.dart';
import 'package:sweet_models_mobile/services/pdf_receipt_service.dart';

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

  Future<void> _generateAndShare() async {
    setState(() => _isLoading = true);

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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error generando recibo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadReceipt() async {
    setState(() => _isLoading = true);

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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error descargando recibo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
