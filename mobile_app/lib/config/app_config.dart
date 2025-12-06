// Configuración de la aplicación Flutter
// Cambiar valores según el entorno (desarrollo, staging, producción)

class AppConfig {
  // Entorno actual
  static const String environment = 'development';

  // URLs del backend
  // IMPORTANTE: Para Android Emulator usa 10.0.2.2
  //             Para iOS Simulator usa localhost
  //             Para dispositivo físico usa la IP de tu máquina
  static const String backendUrl = 'http://10.0.2.2:3000';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Almacenamiento seguro
  static const String userStorageKey = 'user_data';
  static const String tokenStorageKey = 'auth_token';
  static const String refreshTokenStorageKey = 'refresh_token';

  // Configuración de UI
  static const String appName = 'Sweet Models Enterprise';
  static const String appVersion = '1.0.0';

  // Endpoints de API
  static const String healthEndpoint = '/health';
  static const String setupAdminEndpoint = '/setup_admin';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String getUserEndpoint = '/api/users/me';
  static const String updateProfileEndpoint = '/api/users/profile';

  // Validación
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;

  // Colores personalizados
  static const Map<String, int> customColors = {
    'primaryBlue': 0xFF00d4ff,
    'secondaryOrange': 0xFFffa500,
    'darkBg': 0xFF1a1a2e,
    'darkCard': 0xFF16213e,
    'successGreen': 0xFF00ff00,
    'errorRed': 0xFFff0000,
    'warningOrange': 0xFFff9800,
  };

  // Cambiar URL para producción o staging
  static String getBackendUrl({String? override}) {
    if (override != null) return override;
    
    switch (environment) {
      case 'production':
        return 'https://api.sweetmodels.com';
      case 'staging':
        return 'https://staging-api.sweetmodels.com';
      default:
        return backendUrl;
    }
  }

  // Debug mode
  static bool get isDebugMode => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
}
