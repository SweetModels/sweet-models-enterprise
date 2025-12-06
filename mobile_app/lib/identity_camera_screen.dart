import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'api_service.dart';

class IdentityCameraScreen extends StatefulWidget {
  final String documentType; // 'national_id_front', 'national_id_back', 'selfie', 'proof_address'
  final String userId;
  final VoidCallback onDocumentUploaded;

  const IdentityCameraScreen({
    Key? key,
    required this.documentType,
    required this.userId,
    required this.onDocumentUploaded,
  }) : super(key: key);

  @override
  State<IdentityCameraScreen> createState() => _IdentityCameraScreenState();
}

class _IdentityCameraScreenState extends State<IdentityCameraScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isUploading = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController.initialize();

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      print('Error initializing camera: $e');
      _showErrorDialog('No se pudo acceder a la cámara');
    }
  }

  Future<void> _takePicture() async {
    try {
      if (!_isCameraInitialized) return;

      final image = await _cameraController.takePicture();
      setState(() => _capturedImage = image);

      // Mostrar preview y opciones
      _showCapturePreview();
    } catch (e) {
      print('Error taking picture: $e');
      _showErrorDialog('No se pudo capturar la foto');
    }
  }

  void _showCapturePreview() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEB1555),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(_capturedImage!.path),
                  fit: BoxFit.cover,
                  height: 400,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Texto pregunta
            const Text(
              '¿La foto es legible?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _capturedImage = null);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Retomar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _uploadDocument();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEB1555),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument() async {
    if (_capturedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final imageFile = File(_capturedImage!.path);

      final response = await ApiService().uploadKycDocument(
        userId: widget.userId,
        documentType: widget.documentType,
        imageFile: imageFile,
      );

      if (response['success'] != false) {
        _showSuccessDialog(response['document_id'] ?? 'Documento subido exitosamente');
      } else {
        _showErrorDialog('Error al subir el documento');
      }
    } catch (e) {
      print('Upload error: $e');
      _showErrorDialog('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFEB1555)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String documentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 100,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Documento Subido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $documentId',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                widget.onDocumentUploaded();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB1555),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  String _getDocumentLabel() {
    const labels = {
      'national_id_front': 'Frente de la Cédula',
      'national_id_back': 'Dorso de la Cédula',
      'selfie': 'Foto de Rostro',
      'proof_address': 'Comprobante de Domicilio',
    };
    return labels[widget.documentType] ?? 'Documento';
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isUploading,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          elevation: 0,
          title: Text('Capturar: ${_getDocumentLabel()}'),
          centerTitle: true,
        ),
        body: _capturedImage != null
            ? Center(
                child: _isUploading
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 60,
                            width: 60,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFEB1555),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Subiendo documento...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.expand(),
              )
            : !_isCameraInitialized
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFEB1555),
                      ),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camera Preview
                      CameraPreview(_cameraController),

                      // Overlay con marco guía
                      _buildCameraOverlay(),

                      // Botón de captura
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _takePicture,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEB1555),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEB1555).withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Instrucciones
                      Positioned(
                        top: 40,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Alinea el documento dentro del marco',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Oscuridad alrededor del marco
        Container(
          color: Colors.black45,
        ),
        // Marco recortado
        Center(
          child: Container(
            width: 320,
            height: 480,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEB1555),
                width: 3,
              ),
            ),
            child: Stack(
              children: [
                // Esquinas decorativas
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFFEB1555),
                          width: 3,
                        ),
                        left: BorderSide(
                          color: const Color(0xFFEB1555),
                          width: 3,
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFFEB1555),
                          width: 3,
                        ),
                        right: BorderSide(
                          color: const Color(0xFFEB1555),
                          width: 3,
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFEB1555),
                          width: 3,
                        ),
                        left: BorderSide(
                          color: const Color(0xFFEB1555),
                          width: 3,
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFEB1555),
                          width: 3,
                        ),
                        right: BorderSide(
                          color: const Color(0xFFEB1555),
                          width: 3,
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
