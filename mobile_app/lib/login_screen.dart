import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'api_service.dart';
import 'biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/web3_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometricService = BiometricService();
  final _web3Service = Web3Service();

  bool _isLoading = false;
  bool _isWeb3Loading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  String _biometricType = '';

  @override
  void initState() {
    super.initState();
    // Biometría deshabilitada en Windows (flutter_secure_storage no configurado)
    // _checkBiometricStatus();
    // _attemptBiometricLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    // DESHABILITADO EN WINDOWS - flutter_secure_storage no configurado
    // final status = await _biometricService.checkBiometricStatus();
    setState(() {
      _biometricAvailable = false;  // Deshabilitado en Windows
      _biometricType = '';
    });
  }

  Future<void> _attemptBiometricLogin() async {
    // DESHABILITADO - flutter_secure_storage no configurado en Windows
    return;
  }

  Future<void> _loginWithWeb3() async {
    setState(() => _isWeb3Loading = true);
    try {
      final address = await _web3Service.connectWallet();
      if (!mounted) return;
      setState(() => _isWeb3Loading = false);

      if (address != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet conectada: $address'),
            backgroundColor: const Color(0xFF0B84FF),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo conectar la wallet'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isWeb3Loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error Web3: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final token = response.accessToken;
      final role = response.role;
      final userId = response.userId;

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);  // Cambiado de 'auth_token' a 'access_token'
      await prefs.setString('user_email', _emailController.text.trim());
      await prefs.setString('user_role', role);
      await prefs.setString('user_id', userId);

      if (mounted) {
        setState(() => _isLoading = false);

        // BIOMETRICS DESHABILITADO EN WINDOWS (flutter_secure_storage no configurado)
        // final isBiometricEnabled = await _biometricService.isBiometricEnabled();
        // if (!isBiometricEnabled && _biometricAvailable) { ... }

        // Navegar a MainScreen (navegación adaptativa) después de login exitoso
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showBiometricEnableDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        icon: Icon(
          _biometricType.contains('Face') ? Icons.face : Icons.fingerprint,
          size: 60,
          color: const Color(0xFFEB1555),
        ),
        title: const Text(
          '¿Activar Login Biométrico?',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'La próxima vez podrás iniciar sesión usando $_biometricType sin necesidad de escribir tu contraseña.',
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Ahora no',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEB1555),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Sí, activar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // Zinc-950 (Negro puro)
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 48.0 : 24.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 420 : double.infinity,
              ),
              child: ShadCard(
                backgroundColor: const Color(0xFF18181B), // Zinc-900
                border: Border.all(
                  color: const Color(0xFF27272A), // Zinc-800
                  width: 1,
                ),
                padding: EdgeInsets.all(isLargeScreen ? 48.0 : 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          size: 48,
                          color: Color(0xFFFAFAFA),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'Sweet Models',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFAFAFA),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ENTERPRISE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF71717A), // Zinc-500
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email Input
                      ShadInput(
                        controller: _emailController,
                        placeholder: const Text('Email'),
                        keyboardType: TextInputType.emailAddress,
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 8),
                          child: Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: Color(0xFF71717A),
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFFFAFAFA),
                          fontSize: 15,
                        ),
                        decoration: ShadDecoration(
                          border: ShadBorder.all(
                            color: const Color(0xFF27272A),
                            width: 1,
                          ),
                          focusedBorder: ShadBorder.all(
                            color: const Color(0xFFFAFAFA),
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Input
                      ShadInput(
                        controller: _passwordController,
                        placeholder: const Text('Contraseña'),
                        obscureText: _obscurePassword,
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 8),
                          child: Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: Color(0xFF71717A),
                          ),
                        ),
                        suffix: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ShadButton.ghost(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: const Color(0xFF71717A),
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            size: ShadButtonSize.sm,
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFFFAFAFA),
                          fontSize: 15,
                        ),
                        decoration: ShadDecoration(
                          border: ShadBorder.all(
                            color: const Color(0xFF27272A),
                            width: 1,
                          ),
                          focusedBorder: ShadBorder.all(
                            color: const Color(0xFFFAFAFA),
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Button (Primary - Blanco)
                      ShadButton(
                        onPressed: _isLoading ? null : _login,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF09090B)),
                                ),
                              )
                            : const Text(
                                'Ingresar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF09090B),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Web3 Wallet Button (Outline)
                      ShadButton.outline(
                        onPressed: _isWeb3Loading ? null : _loginWithWeb3,
                        width: double.infinity,
                        size: ShadButtonSize.lg,
                        icon: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                        ),
                        child: _isWeb3Loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFAFAFA)),
                                ),
                              )
                            : const Text(
                                'Conectar Web3 Wallet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFF27272A),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'o',
                              style: TextStyle(
                                color: Color(0xFF71717A),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFF27272A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Register Link
                      ShadButton.ghost(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/register_model');
                        },
                        width: double.infinity,
                        child: const Text(
                          '¿No tienes cuenta? Regístrate como modelo',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFA1A1AA),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
