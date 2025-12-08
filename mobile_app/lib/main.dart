import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';
import 'groups_screen.dart';
import 'financial_planning_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'register_model_screen.dart';
import 'camera_monitor_screen.dart';
import 'otp_verification_screen.dart';
import 'identity_camera_screen.dart';
import 'cctv_grid_screen.dart';
import 'register_model_screen_advanced.dart';
import 'screens/admin_stats_screen.dart';
import 'screens/model_home_screen.dart';
import 'screens/contract_screen.dart';
import 'screens/moderator_console_screen.dart';
import 'services/web3_service.dart';
import 'services/grpc_client.dart';
// import 'package:media_kit/media_kit.dart'; // Temporalmente deshabilitado

// Providers Riverpod
final web3ServiceProvider = ChangeNotifierProvider<Web3Service>((ref) => Web3Service());
final grpcClientProvider = ChangeNotifierProvider<GrpcClient>((ref) => GrpcClient());

void main() {
  // Inicializar media_kit para reproducción de video
  // MediaKit.ensureInitialized(); // Deshabilitado hasta configurar libmpv-2.dll
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Detectar si está corriendo en Windows
  bool get _isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweet Models Enterprise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEB1555),
          secondary: Color(0xFF00D4FF),
          surface: Color(0xFF1D1E33),
          error: Color(0xFFFF3B30),
          onPrimary: Color(0xFFFFFFFF),
          onSecondary: Color(0xFF000000),
          onSurface: Color(0xFFFFFFFF),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        cardTheme: CardTheme(
          elevation: 8,
          color: const Color(0xFF1D1E33),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1D1E33),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/register': (context) => const RegisterScreen(),
        '/register_model': (context) => const RegisterModelScreen(),
        '/groups': (context) => const GroupsScreen(),
        '/financial_planning': (context) => const FinancialPlanningScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/cameras': (context) => const CameraMonitorScreen(),
        '/cctv_grid': (context) => const CctvGridScreen(),
        '/admin_stats': (context) => const AdminStatsScreen(),
        '/register_advanced': (context) => const RegisterModelScreenAdvanced(),
        '/model/home': (context) => const ModelHomeScreen(),
        '/model/contract': (context) => const ContractScreen(),
        '/moderator/console': (context) => const ModeratorConsoleScreen(),
        '/otp_verify': (context) {
          // Obtener argumentos de la ruta
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return OtpVerificationScreen(
            phone: args?['phone'] ?? '+573001234567',
            onVerificationComplete: args?['onComplete'] ?? () {},
          );
        },
        '/identity_camera': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return IdentityCameraScreen(
            documentType: args?['documentType'] ?? 'national_id_front',
            userId: args?['userId'] ?? '',
            onDocumentUploaded: args?['onComplete'] ?? () {},
          );
        },
      },
    );
  }
}
