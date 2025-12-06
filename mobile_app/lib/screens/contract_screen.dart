import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import '../api_service.dart';

class ContractScreen extends ConsumerStatefulWidget {
  const ContractScreen({super.key});

  @override
  ConsumerState<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends ConsumerState<ContractScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.white,
  );
  bool _submitting = false;
  Uint8List? _lastSignature;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dibuja tu firma antes de enviar.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final pngBytes = await _controller.toPngBytes();
      if (pngBytes == null) {
        throw Exception('No se pudo renderizar la firma.');
      }
      _lastSignature = pngBytes;

      final api = ref.read(apiServiceProvider);
      await api.signContract(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrato firmado con éxito.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al firmar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrato Legal'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Términos y Condiciones',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _legalText,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Firme aquí',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Signature(
                        controller: _controller,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _controller.clear,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Limpiar'),
                        ),
                        const SizedBox(width: 12),
                        if (_lastSignature != null)
                          const Text(
                            'Firma lista para enviar',
                            style: TextStyle(color: Colors.greenAccent),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitSignature,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_document),
                  label: Text(_submitting ? 'Enviando...' : 'Aceptar y Firmar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String _legalText =
    'Este contrato de prestación de servicios entre la Modelo y Sweet Models Enterprise establece las condiciones de colaboración, responsabilidades y confidencialidad. '
    'La modelo declara ser mayor de edad, autoriza el tratamiento de datos personales y acepta que la remuneración se calculará según tokens y métricas semanales. '
    'Sweet Models garantizará la seguridad de la información, realizará pagos oportunos y podrá realizar auditorías de calidad. '
    'La vigencia es anual con renovación automática salvo notificación expresa. '
    'Al firmar digitalmente, la modelo confirma que ha leído, comprendido y aceptado cada cláusula.';
