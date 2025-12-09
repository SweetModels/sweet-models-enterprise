import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';
import 'groups_screen.dart';
import 'financial_planning_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'screens/login_screen_shadcn.dart';
import 'screens/main_screen_enhanced.dart'; // ⭐ Pantalla principal mejorada con animaciones
import 'register_model_screen.dart';
import 'register_model_screen_shadcn.dart'; // ⭐ Nuevo registro con Shadcn UI
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
    return ShadApp.material(
      title: 'Sweet Models Enterprise',
      debugShowCheckedModeBanner: false,
      
      // 🎨 Shadcn Theme Configuration
      themeMode: ThemeMode.dark,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
      ),
      darkTheme: AppTheme.shadcnTheme,
      
      // 📱 Material Theme Fallback
      materialThemeBuilder: (context, theme) => AppTheme.materialTheme,
      
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreenShadcn(), // 🎨 Pantalla de login con Shadcn
        '/main': (context) => const MainScreen(),     // ⭐ Navegación adaptativa con animaciones
        '/login': (context) => const LoginScreen(),   // Pantalla original (fallback)
        '/dashboard': (context) => const DashboardScreen(),
        '/register': (context) => const RegisterScreen(),
        '/register_model': (context) => const RegisterModelScreenShadcn(), // ⭐ Registro Shadcn UI
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
