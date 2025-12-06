import 'package:flutter/material.dart';
import 'api_service.dart';
import 'otp_verification_screen.dart';
import 'identity_camera_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// PANTALLA DE REGISTRO MEJORADA CON OTP + KYC + CCTV
// ============================================================================

class RegisterModelScreenAdvanced extends StatefulWidget {
  const RegisterModelScreenAdvanced({Key? key}) : super(key: key);

  @override
  State<RegisterModelScreenAdvanced> createState() => _RegisterModelScreenAdvancedState();
}

class _RegisterModelScreenAdvancedState extends State<RegisterModelScreenAdvanced>
    with SingleTickerProviderStateMixin {
  // ── Controladores ──
  late TabController _tabController;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  // ── Estados ──
  int _currentStep = 0; // 0=Datos, 1=OTP, 2=KYC, 3=Resumen
  bool _isLoading = false;
  String? _errorMessage;
  bool _phoneVerified = false;
  Map<String, bool> _documentsUploaded = {
    'national_id_front': false,
    'national_id_back': false,
    'selfie': false,
    'proof_address': false,
  };
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────
  // PASO 1: VALIDAR DATOS BÁSICOS
  // ────────────────────────────────────────────────────────────────────────

  Future<void> _validateBasicInfo() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showError('Completa todos los campos');
      return;
    }

    // Validar email
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(_emailController.text)) {
      _showError('Email inválido');
      return;
    }

    // Validar contraseña (mínimo 8 caracteres, 1 mayúscula, 1 número)
    if (!RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(_passwordController.text)) {
      _showError('Contraseña: 8+ caracteres, 1 mayúscula, 1 número');
      return;
    }

    // Validar teléfono (10 dígitos)
    if (_phoneController.text.length != 10 ||
        !RegExp(r'^[0-9]+$').hasMatch(_phoneController.text)) {
      _showError('Teléfono: 10 dígitos');
      return;
    }

    // Pasar al siguiente paso
    setState(() {
      _currentStep = 1;
      _tabController.index = 1;
    });

    // Auto-enviar OTP
    _sendOtp();
  }

  // ────────────────────────────────────────────────────────────────────────
  // PASO 2: VERIFICACIÓN OTP
  // ────────────────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);

    try {
      final phone = '+57${_phoneController.text}';
      final response = await ApiService().sendOtp(phone);

      if (response['success']) {
        // Mostrar diálogo con OTP enviado
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📨 Código OTP enviado a $phone'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        _showError('No se pudo enviar OTP');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtpAndContinue() async {
    // Mostrar pantalla de verificación OTP
    final phone = '+57${_phoneController.text}';

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(
          phone: phone,
          onVerificationComplete: () {
            Navigator.pop(context, true);
          },
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _phoneVerified = true;
        _currentStep = 2;
        _tabController.index = 2;
      });
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // PASO 3: CAPTURA DE DOCUMENTOS KYC
  // ────────────────────────────────────────────────────────────────────────

  Future<void> _captureDocument(String documentType) async {
    // Mostrar pantalla de cámara
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => IdentityCameraScreen(
          documentType: documentType,
          userId: _userId ?? 'temp-user-id',
          onDocumentUploaded: () {
            Navigator.pop(context, true);
          },
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _documentsUploaded[documentType] = true;
        _errorMessage = null;
      });

      // Verificar si todos están completos
      if (_documentsUploaded.values.every((v) => v)) {
        _proceedToSummary();
      }
    }
  }

  bool get _allDocumentsUploaded =>
      _documentsUploaded.values.every((v) => v);

  void _proceedToSummary() {
    setState(() {
      _currentStep = 3;
      _tabController.index = 3;
    });
  }

  // ────────────────────────────────────────────────────────────────────────
  // PASO 4: COMPLETAR REGISTRO
  // ────────────────────────────────────────────────────────────────────────

  Future<void> _completeRegistration() async {
    setState(() => _isLoading = true);

    try {
      // Crear cuenta
      final registerResponse = await ApiService().register(
        _emailController.text,
        _passwordController.text,
      );

      if (registerResponse['success'] != false) {
        _userId = registerResponse['user_id'];

        // Guardar datos localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', _emailController.text);
        await prefs.setString('user_name', _nameController.text);
        await prefs.setString('user_phone', '+57${_phoneController.text}');

        // Mostrar confirmación
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registro completado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Ir a login
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        }
      } else {
        _showError('Email ya registrado');
      }
    } catch (e) {
      _showError('Error en registro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ────────────────────────────────────────────────────────────────────────

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1E33),
        elevation: 0,
        title: const Text('Registro de Modelo'),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : Column(
              children: [
                // Progress Indicator
                _buildProgressBar(),
                const SizedBox(height: 16),
                // Content
                Expanded(
                  child: IndexedStack(
                    index: _currentStep,
                    children: [
                      _buildStep1BasicInfo(),
                      _buildStep2OtpVerification(),
                      _buildStep3KycDocuments(),
                      _buildStep4Summary(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PASO 1: INFORMACIÓN BÁSICA
  // ─────────────────────────────────────────────────────────────────

  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Básica',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Correo Electrónico',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Nombre completo
          _buildTextField(
            controller: _nameController,
            label: 'Nombre Completo',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),

          // Teléfono
          _buildTextField(
            controller: _phoneController,
            label: 'Teléfono (10 dígitos)',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            prefixText: '+57 ',
          ),
          const SizedBox(height: 16),

          // Contraseña
          _buildTextField(
            controller: _passwordController,
            label: 'Contraseña (8+ caracteres)',
            icon: Icons.lock,
            obscureText: true,
          ),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 24),

          // Botón siguiente
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _validateBasicInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB1555),
              ),
              child: const Text(
                'Siguiente: Verificación OTP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PASO 2: VERIFICACIÓN OTP
  // ─────────────────────────────────────────────────────────────────

  Widget _buildStep2OtpVerification() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verificación por OTP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Recibirás un código de 6 dígitos en tu teléfono. Verifica en la siguiente pantalla.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Información del teléfono
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF262D47),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📱 Teléfono',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+57 ${_phoneController.text}',
                  style: const TextStyle(
                    color: Color(0xFFEB1555),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Estado
          if (_phoneVerified)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text(
                    'Teléfono verificado',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            )
          else
            const Text(
              '⏳ Esperando verificación...',
              style: TextStyle(color: Colors.white54),
            ),
          const SizedBox(height: 32),

          // Botón verificar
          if (!_phoneVerified)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _verifyOtpAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB1555),
                ),
                child: const Text(
                  'Ingresar Código OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          if (_phoneVerified) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 2;
                    _tabController.index = 2;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB1555),
                ),
                child: const Text(
                  'Siguiente: Capturar Documentos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PASO 3: CAPTURA DE DOCUMENTOS KYC
  // ─────────────────────────────────────────────────────────────────

  Widget _buildStep3KycDocuments() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capturar Documentos (KYC)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Completa la verificación de identidad capturando los siguientes documentos.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Documentos
          _buildDocumentCard(
            'national_id_front',
            'Frente de la Cédula',
            '📄 Documento de identidad (frente)',
          ),
          const SizedBox(height: 12),

          _buildDocumentCard(
            'national_id_back',
            'Dorso de la Cédula',
            '📄 Documento de identidad (reverso)',
          ),
          const SizedBox(height: 12),

          _buildDocumentCard(
            'selfie',
            'Foto de Rostro',
            '🤳 Foto tuya con expresión natural',
          ),
          const SizedBox(height: 12),

          _buildDocumentCard(
            'proof_address',
            'Comprobante de Domicilio',
            '📮 Factura, recibo o certificado (últimos 3 meses)',
          ),
          const SizedBox(height: 32),

          // Botón continuar
          if (_allDocumentsUploaded)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 3;
                    _tabController.index = 3;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB1555),
                ),
                child: const Text(
                  'Siguiente: Resumen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                '⏳ Completa todos los documentos para continuar',
                style: TextStyle(color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String docType, String title, String description) {
    final isUploaded = _documentsUploaded[docType] ?? false;

    return GestureDetector(
      onTap: isUploaded ? null : () => _captureDocument(docType),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUploaded 
              ? const Color(0xFF1D1E33).withOpacity(0.7) 
              : const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded ? Colors.green : const Color(0xFF262D47),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (isUploaded)
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 28,
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEB1555).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEB1555),
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFFEB1555),
                  size: 24,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isUploaded)
              const Text(
                '✅',
                style: TextStyle(fontSize: 20),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PASO 4: RESUMEN Y COMPLETAR
  // ─────────────────────────────────────────────────────────────────

  Widget _buildStep4Summary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Registro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Información personal
          _buildSummarySection(
            '👤 Información Personal',
            [
              ('Email', _emailController.text),
              ('Nombre', _nameController.text),
              ('Teléfono', '+57 ${_phoneController.text}'),
              ('Estado', 'Verificado ✅'),
            ],
          ),
          const SizedBox(height: 20),

          // Documentos
          _buildSummarySection(
            '📄 Documentos KYC',
            [
              ('Cédula (Frente)', _documentsUploaded['national_id_front']! ? '✅' : '⏳'),
              ('Cédula (Dorso)', _documentsUploaded['national_id_back']! ? '✅' : '⏳'),
              ('Selfie', _documentsUploaded['selfie']! ? '✅' : '⏳'),
              ('Comprobante', _documentsUploaded['proof_address']! ? '✅' : '⏳'),
            ],
          ),
          const SizedBox(height: 20),

          // Términos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue),
            ),
            child: const Text(
              '✓ Acepto los términos y condiciones\n✓ He verificado que todos los datos son correctos',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Botón completar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _completeRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Completar Registro',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, List<(String, String)> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF262D47),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      color: Color(0xFFEB1555),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // UI COMPONENTS
  // ─────────────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: const Color(0xFF1D1E33),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildProgressStep(1, 'Datos', _currentStep >= 0),
          _buildProgressStep(2, 'OTP', _currentStep >= 1),
          _buildProgressStep(3, 'KYC', _currentStep >= 2),
          _buildProgressStep(4, 'Resumen', _currentStep >= 3),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool completed) {
    final isActive = _currentStep >= step - 1;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEB1555) : const Color(0xFF262D47),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: completed && _currentStep > step - 1 ? 20 : 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String prefixText = '',
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: const Color(0xFFEB1555)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF262D47),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEB1555),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF1D1E33),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
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
          SizedBox(height: 16),
          Text(
            'Procesando...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NOTAS: ApiService ya tiene el método register() implementado
// ════════════════════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════════════════════
// NOTAS DE IMPLEMENTACIÓN
// ════════════════════════════════════════════════════════════════════════════
// 
// 1. Reemplazar la `RegisterModelScreen` actual con `RegisterModelScreenAdvanced`
// 2. Asegurarse de que ApiService tenga los métodos: register, sendOtp, verifyOtp, uploadKycDocument
// 3. El flujo es secuencial: Datos → OTP → KYC → Resumen
// 4. Cada paso puede ser revisado desde el progress bar
// 5. Los documentos deben completarse ANTES de ir al resumen
// 6. Al finalizar, se crea la cuenta y se redirige a login
//
// ════════════════════════════════════════════════════════════════════════════
