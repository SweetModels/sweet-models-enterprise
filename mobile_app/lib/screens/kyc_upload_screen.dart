import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({Key? key}) : super(key: key);

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  String _documentType = 'cedula';
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final _cardBg = const Color(0xFF1A1A2E);
  final _dorado = const Color(0xFFD4AF37);
  final _rojo = const Color(0xFFE63946);

  static const String baseUrl = 'http://10.0.2.2:3000';

  final List<String> documentTypes = [
    'cedula',
    'pasaporte',
    'licencia',
  ];

  final Map<String, String> documentLabels = {
    'cedula': '🆔 Cédula de Identidad',
    'pasaporte': '📕 Pasaporte',
    'licencia': '🚗 Licencia de Conducción',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verificación de Identidad',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _cardBg,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📋 Instrucciones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _dorado.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📸 Cómo se verifica tu identidad',
                      style: GoogleFonts.poppins(
                        color: _dorado,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Selecciona el tipo de documento\n'
                      '2. Toma o sube una foto clara\n'
                      '3. Asegúrate que se vea bien tu cara\n'
                      '4. Envía para revisión\n'
                      '5. Te avisaremos cuando esté verificado',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 📄 Selector de tipo de documento
              Text(
                'Tipo de Documento',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _dorado.withOpacity(0.5), width: 1),
                ),
                child: DropdownButton<String>(
                  value: _documentType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: _cardBg,
                  items: documentTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          documentLabels[type] ?? type,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _documentType = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),

              // 📸 Área de carga/vista previa
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _dorado.withOpacity(0.4),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imageBytes != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imageBytes = null;
                                    _selectedImage = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _rojo,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 60,
                              color: _dorado,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Toca para capturar',
                              style: GoogleFonts.poppins(
                                color: _dorado,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'o sube desde tu galería',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // 📤 Barra de progreso
              if (_isUploading)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(_dorado),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        color: _dorado,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // 🚀 Botón de envío
              ElevatedButton(
                onPressed: (_imageBytes == null || _isUploading)
                    ? null
                    : _uploadDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dorado,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isUploading
                    ? Text(
                        'Enviando...',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : Text(
                        'ENVIAR DOCUMENTO',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // ℹ️ Nota importante
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'ℹ️ Tu documento será revisado en máximo 24 horas. Mantén la imagen clara y legible.',
                  style: GoogleFonts.poppins(
                    color: Colors.blue[200],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona una opción',
                style: GoogleFonts.poppins(
                  color: _dorado,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: _dorado),
                title: Text(
                  'Tomar foto',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _captureImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: _dorado),
                title: Text(
                  'Galería',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _selectFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      _showError('Error al capturar imagen: $e');
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _uploadDocument() async {
    if (_imageBytes == null || _selectedImage == null) {
      _showError('Selecciona una imagen primero');
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No hay sesión activa. Por favor, inicia sesión.');
      }

      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          _imageBytes!,
          filename: '${_documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'document_type': _documentType,
      });

      final response = await dio.post(
        '/api/model/upload-kyc',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        onSendProgress: (sent, total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${response.data['message'] ?? 'Documento enviado a revisión'}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {
          _imageBytes = null;
          _selectedImage = null;
          _uploadProgress = 0.0;
        });
        // Volver a pantalla anterior después de 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Error desconocido';
      _showError(errorMsg);
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: _rojo,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
