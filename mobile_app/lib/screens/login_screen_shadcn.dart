import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';
import '../api_service.dart';
import '../services/web3_service.dart';

class LoginScreenShadcn extends StatefulWidget {
  const LoginScreenShadcn({Key? key}) : super(key: key);

  @override
  State<LoginScreenShadcn> createState() => _LoginScreenShadcnState();
}

class _LoginScreenShadcnState extends State<LoginScreenShadcn> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _web3Service = Web3Service();

  bool _isLoading = false;
  bool _isWeb3Loading = false;
  bool _passwordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithWeb3() async {
    setState(() => _isWeb3Loading = true);
    try {
      final address = await _web3Service.connectWallet();
      if (!mounted) return;
      setState(() => _isWeb3Loading = false);

      if (address != null) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Wallet conectada'),
            description: Text('Dirección: ${address.substring(0, 10)}...${address.substring(address.length - 8)}'),
          ),
        );
        
        // Navigate to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error de conexión'),
            description: const Text('No se pudo conectar la wallet'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isWeb3Loading = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Error Web3'),
          description: Text('$e'),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Campos requeridos'),
          description: Text('Por favor completa todos los campos'),
        ),
      );
      return;
    }

    if (!_emailController.text.contains('@')) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Email inválido'),
          description: Text('Por favor ingresa un email válido'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // La respuesta es un LoginResponse objeto, no un Map
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('✅ Login exitoso'),
          description: const Text('Bienvenido'),
        ),
      );
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Error de autenticación'),
          description: Text('$e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ShadCard(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 32),
                    
                    // Email Input
                    _buildEmailInput(),
                    const SizedBox(height: 16),
                    
                    // Password Input
                    _buildPasswordInput(),
                    const SizedBox(height: 16),
                    
                    // Remember Me Row
                    _buildRememberMeRow(),
                    const SizedBox(height: 24),
                    
                    // Login Button
                    _buildLoginButton(),
                    const SizedBox(height: 16),
                    
                    // Divider
                    _buildDivider(),
                    const SizedBox(height: 16),
                    
                    // Web3 Button
                    _buildWeb3Button(),
                    const SizedBox(height: 24),
                    
                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: const Icon(
            Icons.diamond_outlined,
            size: 32,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Sweet Models',
          style: AppTheme.textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Enterprise Management Platform',
          style: AppTheme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: AppTheme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        ShadInput(
          controller: _emailController,
          placeholder: const Text('nombre@empresa.com'),
          keyboardType: TextInputType.emailAddress,
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.mail_outline,
              size: 18,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contraseña',
          style: AppTheme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        ShadInput(
          controller: _passwordController,
          placeholder: const Text('Tu contraseña'),
          obscureText: !_passwordVisible,
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.lock_outline,
              size: 18,
              color: AppTheme.textMuted,
            ),
          ),
          suffix: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: AppTheme.textMuted,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRememberMeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ShadCheckbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value;
                });
              },
            ),
            const SizedBox(width: 8),
            Text(
              'Recordarme',
              style: AppTheme.textTheme.labelMedium,
            ),
          ],
        ),
        ShadButton.ghost(
          onPressed: () {
            // TODO: Implementar recuperación de contraseña
          },
          child: Text(
            '¿Olvidaste tu contraseña?',
            style: AppTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ShadButton(
      onPressed: _isLoading ? null : _handleLogin,
      size: ShadButtonSize.lg,
      width: double.infinity,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Iniciar sesión'),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'O CONTINUAR CON',
            style: AppTheme.textTheme.labelSmall,
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.border)),
      ],
    );
  }

  Widget _buildWeb3Button() {
    return ShadButton.secondary(
      onPressed: _isWeb3Loading ? null : _loginWithWeb3,
      size: ShadButtonSize.lg,
      width: double.infinity,
      child: _isWeb3Loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Conectar Wallet Web3',
                  style: AppTheme.textTheme.labelLarge,
                ),
              ],
            ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿No tienes cuenta? ',
              style: AppTheme.textTheme.bodySmall,
            ),
            ShadButton.ghost(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text(
                'Regístrate',
                style: AppTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '© 2025 Sweet Models Enterprise',
          style: AppTheme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: Text(
                'Términos',
                style: AppTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            Text(' · ', style: AppTheme.textTheme.bodySmall),
            TextButton(
              onPressed: () {},
              child: Text(
                'Privacidad',
                style: AppTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            Text(' · ', style: AppTheme.textTheme.bodySmall),
            TextButton(
              onPressed: () {},
              child: Text(
                'Soporte',
                style: AppTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
