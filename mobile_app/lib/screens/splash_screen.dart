import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkServerStatus();
  }

  Future<void> _checkServerStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      ref.read(authStateProvider.notifier).refreshHealth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o título
            Text(
              'Sweet Models',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00d4ff),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enterprise',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFffa500),
              ),
            ),
            const SizedBox(height: 60),
            // Estado del servidor
            authState.when(
              data: (isHealthy) {
                return Column(
                  children: [
                    if (isHealthy)
                      const _StatusIndicator(
                        icon: Icons.check_circle,
                        label: 'Servidor conectado',
                        color: Color(0xFF00ff00),
                      )
                    else
                      const _StatusIndicator(
                        icon: Icons.error,
                        label: 'Servidor desconectado',
                        color: Color(0xFFff0000),
                      ),
                    const SizedBox(height: 40),
                    if (isHealthy)
                      ElevatedButton(
                        onPressed: () {
                          // Navegar a login
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Login - Pronto disponible')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00d4ff),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Iniciar Sesión',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1a1a2e),
                          ),
                        ),
                      )
                    else
                      Text(
                        'Por favor, inicia el servidor backend',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFFff0000),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const _LoadingIndicator(),
              error: (error, stack) => Column(
                children: [
                  const _StatusIndicator(
                    icon: Icons.warning,
                    label: 'Error de conexión',
                    color: Color(0xFFff9800),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFff9800),
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
}

class _StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusIndicator({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 16),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00d4ff)),
        ),
        const SizedBox(height: 24),
        Text(
          'Conectando...',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF00d4ff),
          ),
        ),
      ],
    );
  }
}
