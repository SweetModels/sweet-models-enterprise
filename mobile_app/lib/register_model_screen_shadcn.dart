import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';

/// Pantalla de Registro de Modelo
/// Diseño enterprise minimalista usando Shadcn UI Zinc palette
class RegisterModelScreen extends StatefulWidget {
  const RegisterModelScreen({Key? key}) : super(key: key);

  @override
  State<RegisterModelScreen> createState() => _RegisterModelScreenState();
}

class _RegisterModelScreenState extends State<RegisterModelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _otpSent = false;
  bool _phoneVerified = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.length < 10) {
      _showSnackBar('El teléfono debe tener al menos 10 dígitos', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _otpSent = true;
    });

    if (mounted) {
      _showSnackBar('📱 OTP enviado a ${_phoneController.text}');
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _phoneVerified = true);
          _showSnackBar('✅ Teléfono verificado exitosamente');
        }
      });
    }
  }

  Future<void> _registerModel() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_phoneVerified) {
      _showSnackBar('⚠️ Debes verificar tu teléfono primero', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService().registerModel(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text,
        nationalId: _nationalIdController.text,
        address: _addressController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('✅ Registro exitoso. Redirigiendo...');
        
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('❌ Error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444) // Red
            : const Color(0xFF22C55E), // Green
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Column(
          children: [
            // Header con back button
            _buildHeader(context),
            
            // Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isLargeScreen ? 48.0 : 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isLargeScreen ? 520 : double.infinity,
                    ),
                    child: _buildForm(isLargeScreen),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF27272A),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          ShadButton.ghost(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Text(
            'Registro de Modelo',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFAFAFA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isLargeScreen) {
    return ShadCard(
      backgroundColor: const Color(0xFF18181B),
      border: Border.all(
        color: const Color(0xFF27272A),
        width: 1,
      ),
      padding: EdgeInsets.all(isLargeScreen ? 48.0 : 32.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_add_outlined,
                  size: 40,
                  color: Color(0xFFFAFAFA),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Únete a Sweet Models',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFAFAFA),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa tu perfil profesional',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 32),

            // Nombre Completo
            _buildLabel('Nombre Completo'),
            ShadInput(
              controller: _nameController,
              placeholder: const Text('María García'),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.badge, size: 18, color: Color(0xFF71717A)),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFFAFAFA),
              ),
              validator: (value) {
                if (value.isEmpty) return 'El nombre es obligatorio';
                if (value.length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email
            _buildLabel('Correo Electrónico'),
            ShadInput(
              controller: _emailController,
              placeholder: const Text('maria@example.com'),
              keyboardType: TextInputType.emailAddress,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.email, size: 18, color: Color(0xFF71717A)),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFFAFAFA),
              ),
              validator: (value) {
                if (value.isEmpty) return 'El email es obligatorio';
                if (!value.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Teléfono con verificación
            _buildLabel('Teléfono'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _phoneController,
                    placeholder: const Text('3001234567'),
                    keyboardType: TextInputType.phone,
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        Icons.phone,
                        size: 18,
                        color: _phoneVerified
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF71717A),
                      ),
                    ),
                    suffix: _phoneVerified
                        ? const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Color(0xFF22C55E),
                            ),
                          )
                        : null,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFFAFAFA),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value.isEmpty) return 'El teléfono es obligatorio';
                      if (value.length < 10) return 'Mínimo 10 dígitos';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ShadButton(
                  onPressed: _phoneVerified || _isLoading ? null : _sendOTP,
                  size: ShadButtonSize.sm,
                  backgroundColor: _phoneVerified
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFFAFAFA),
                  child: _isLoading && !_phoneVerified
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF09090B),
                            ),
                          ),
                        )
                      : Text(
                          _phoneVerified ? 'Verificado' : 'Verificar',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF09090B),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Cédula
            _buildLabel('Cédula de Identidad'),
            ShadInput(
              controller: _nationalIdController,
              placeholder: const Text('123456789'),
              keyboardType: TextInputType.number,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.credit_card, size: 18, color: Color(0xFF71717A)),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFFAFAFA),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value.isEmpty) return 'La cédula es obligatoria';
                if (value.length < 6) return 'Cédula inválida';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Dirección
            _buildLabel('Dirección'),
            ShadInput(
              controller: _addressController,
              placeholder: const Text('Calle 123 #45-67'),
              maxLines: 2,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8, top: 12),
                child: Icon(Icons.home, size: 18, color: Color(0xFF71717A)),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFFAFAFA),
              ),
              validator: (value) {
                if (value.isEmpty) return 'La dirección es obligatoria';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Contraseña
            _buildLabel('Contraseña'),
            ShadInput(
              controller: _passwordController,
              placeholder: const Text('Mínimo 8 caracteres'),
              obscureText: _obscurePassword,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.lock, size: 18, color: Color(0xFF71717A)),
              ),
              suffix: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: const Color(0xFF71717A),
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFFAFAFA),
              ),
              validator: (value) {
                if (value.isEmpty) return 'La contraseña es obligatoria';
                if (value.length < 8) return 'Mínimo 8 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Confirmar Contraseña
            _buildLabel('Confirmar Contraseña'),
            ShadInput(
              controller: _confirmPasswordController,
              placeholder: const Text('Repite tu contraseña'),
              obscureText: _obscureConfirmPassword,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.lock_outline, size: 18, color: Color(0xFF71717A)),
              ),
              suffix: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: const Color(0xFF71717A),
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFFAFAFA),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Botón de Registro
            ShadButton(
              onPressed: _isLoading ? null : _registerModel,
              backgroundColor: const Color(0xFFFAFAFA),
              hoverBackgroundColor: const Color(0xFFE4E4E7),
              width: double.infinity,
              size: ShadButtonSize.lg,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF09090B),
                        ),
                      ),
                    )
                  : Text(
                      'Crear Cuenta',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF09090B),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Link a login
            Center(
              child: ShadButton.ghost(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  '¿Ya tienes cuenta? Inicia sesión',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFFAFAFA),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFFAFAFA),
        ),
      ),
    );
  }
}
