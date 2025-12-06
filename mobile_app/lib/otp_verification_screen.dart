import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'api_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final VoidCallback onVerificationComplete;

  const OtpVerificationScreen({
    Key? key,
    required this.phone,
    required this.onVerificationComplete,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  late TextEditingController _otpController;
  late AnimationController _countdownController;
  int _countdownSeconds = 30;
  bool _isVerifying = false;
  String? _errorMessage;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );

    _countdownController.addListener(() {
      setState(() {
        _countdownSeconds = (30 * (1 - _countdownController.value)).ceil();
        if (_countdownSeconds == 0) {
          _canResend = true;
          _countdownController.stop();
        }
      });
    });

    _countdownController.forward();
  }

  Future<void> _verifyOtp(String code) async {
    if (code.length != 6) {
      setState(() => _errorMessage = 'Ingresa los 6 dígitos');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().verifyOtp(widget.phone, code);

      if (response['phone_verified'] == true) {
        // Mostrar animación de éxito
        _showSuccessAnimation();
        // Esperar 1.5 segundos y luego llamar el callback
        await Future.delayed(const Duration(milliseconds: 1500));
        widget.onVerificationComplete();
      } else {
        setState(() => _errorMessage = 'Código incorrecto. Intenta de nuevo.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    try {
      setState(() => _canResend = false);
      final response = await ApiService().sendOtp(widget.phone);

      if (response['success']) {
        // Reiniciar valores
        _otpController.clear();
        setState(() {
          _countdownSeconds = 30;
          _errorMessage = null;
        });

        // Reiniciar countdown
        _countdownController.reset();
        _startCountdown();

        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Código reenviado a tu teléfono'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'No se pudo reenviar el código');
    }
  }

  void _showSuccessAnimation() {
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
              child: Icon(
                Icons.check_circle,
                size: 100,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verificación Exitosa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _maskPhone(String phone) {
    // Muestra: +57 300****567
    if (phone.length < 4) return phone;
    final lastDigits = phone.substring(phone.length - 3);
    final maskedMiddle = '*' * (phone.length - 7);
    return '+${phone.substring(0, 2)} ${phone.substring(2, 5)}$maskedMiddle$lastDigits';
  }

  @override
  void dispose() {
    _otpController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevenir atrás durante verificación
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E27),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D1E33),
          elevation: 0,
          title: const Text('Verificar Teléfono'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icono
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1E33),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      size: 50,
                      color: Color(0xFFEB1555),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Títulos
                  const Text(
                    'Verificación de Identidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Hemos enviado un código a\n',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: _maskPhone(widget.phone),
                          style: const TextStyle(
                            color: Color(0xFFEB1555),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // PIN Code Fields
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    enableActiveFill: true,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 50,
                      fieldWidth: 45,
                      activeFillColor: const Color(0xFF1D1E33),
                      activeColor: const Color(0xFFEB1555),
                      inactiveFillColor: const Color(0xFF262D47),
                      inactiveColor: Colors.grey,
                      selectedFillColor: const Color(0xFF1D1E33),
                      selectedColor: const Color(0xFFEB1555),
                      errorBorderColor: Colors.red,
                    ),
                    onChanged: (value) {
                      setState(() => _errorMessage = null);
                      // Auto-verify cuando complete los 6 dígitos
                      if (value.length == 6 && !_isVerifying) {
                        _verifyOtp(value);
                      }
                    },
                    onCompleted: (value) {
                      // Verificar al completar
                      if (!_isVerifying) {
                        _verifyOtp(value);
                      }
                    },
                    beforeTextPaste: (text) => true,
                  ),

                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Loading indicator during verification
                  if (_isVerifying)
                    const Column(
                      children: [
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFEB1555),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Verificando...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Resend & Countdown
                  if (!_isVerifying)
                    Column(
                      children: [
                        if (_canResend)
                          GestureDetector(
                            onTap: _resendOtp,
                            child: const Text(
                              '¿No recibiste el código? Reenviar',
                              style: TextStyle(
                                color: Color(0xFFEB1555),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              const Text(
                                'Reenviar código en',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D1E33),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFEB1555),
                                  ),
                                ),
                                child: Text(
                                  '$_countdownSeconds segundos',
                                  style: const TextStyle(
                                    color: Color(0xFFEB1555),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                  const SizedBox(height: 40),

                  // Info Text
                  const Text(
                    'Los códigos son válidos por 10 minutos.\nIngresa el código de 6 dígitos que recibiste.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
