import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: Text(
          'Sweet Models Enterprise',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00d4ff),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user != null ? user.email : 'Invitado',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF00d4ff),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              // Card de estado
              _buildStatusCard(user),
              const SizedBox(height: 24),
              // Acciones
              if (user != null) _buildActionsSection(),
              if (user == null) _buildGuestSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(User? user) {
    return Card(
      color: const Color(0xFF16213e),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle, color: Color(0xFF00d4ff), size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de Sesión',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user != null ? 'Autenticado' : 'No autenticado',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: user != null
                              ? const Color(0xFF00ff00)
                              : const Color(0xFFff0000),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  user != null ? Icons.check_circle : Icons.cancel,
                  color: user != null
                      ? const Color(0xFF00ff00)
                      : const Color(0xFFff0000),
                  size: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Cerrar Sesión',
          onPressed: () {
            ref.read(userProvider.notifier).clearUser();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sesión cerrada')),
            );
          },
          backgroundColor: const Color(0xFFff6b6b),
          textColor: Colors.white,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildGuestSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Iniciar Sesión',
          onPressed: () {
            // Navegar a login
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login - Pronto disponible')),
            );
          },
          backgroundColor: const Color(0xFF00d4ff),
          textColor: const Color(0xFF1a1a2e),
          width: double.infinity,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Registrarse',
          onPressed: () {
            // Navegar a registro
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registro - Pronto disponible')),
            );
          },
          backgroundColor: const Color(0xFFffa500),
          textColor: Colors.white,
          width: double.infinity,
        ),
      ],
    );
  }
}

// Usar en main.dart después de reemplazar SplashScreen
