import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

// ============================================================================
// DATA MODELS
// ============================================================================

/// Respuesta de login desde el backend
class LoginResponse {
  final String token; // Cambio de accessToken a token
  final String? tokenType;
  final int? expiresIn;
  final String role;
  final String userId;
  final String? refreshToken;
  final String? name;

  LoginResponse({
    required this.token,
    this.tokenType,
    this.expiresIn,
    required this.role,
    required this.userId,
    this.refreshToken,
    this.name,
  });

  /// Convierte JSON a LoginResponse
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String? ?? json['access_token'] as String,
      tokenType: json['token_type'] as String?,
      expiresIn: json['expires_in'] as int?,
      role: json['role'] as String,
      userId: json['user_id'] as String,
      refreshToken: json['refresh_token'] as String?,
      name: json['name'] as String?,
    );
  }

  @override
  String toString() => 'LoginResponse(role: $role, userId: $userId)';
}

/// Respuesta de registro desde el backend
class RegisterResponse {
  final String userId;
  final String email;
  final String role;

  RegisterResponse({
    required this.userId,
    required this.email,
    required this.role,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }

  @override
  String toString() => 'RegisterResponse(email: $email, role: $role)';
}

// ============================================================================
// API SERVICE
// ============================================================================

/// Servicio para comunicarse con el backend Rust
class ApiService {
  /// Base URL del backend
  late final String baseUrl;
  
  /// Token JWT almacenado en memoria
  String? _accessToken;
  
  /// Datos del usuario autenticado
  LoginResponse? _currentUser;

  ApiService() {
    // Detectar si es emulador Android o plataforma nativa
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:3000'; // Emulador Android
    } else if (Platform.isIOS) {
      baseUrl = 'http://localhost:3000'; // Simulator iOS
    } else {
      baseUrl = 'http://localhost:3000'; // Fallback
    }

    debugPrint('🔌 ApiService initialized with baseUrl: $baseUrl');
  }

  // ============================================================================
  // PROPIEDADES
  // ============================================================================

  /// Retorna true si el usuario está autenticado
  bool get isAuthenticated => _accessToken != null;

  /// Retorna el token actual
  String? get accessToken => _accessToken;

  /// Retorna la información del usuario autenticado
  LoginResponse? get currentUser => _currentUser;

  /// Retorna headers HTTP con autenticación
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// Permite inyectar un token persistido (ej: SharedPreferences)
  void setAccessToken(String token) {
    _accessToken = token;
  }

  // ============================================================================
  // AUTENTICACIÓN
  // ============================================================================

  /// Login con email y contraseña
  /// Retorna true si el login fue exitoso
  Future<bool> login(String email, String password) async {
    try {
      debugPrint('🔐 Attempting login for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      debugPrint('📡 Login response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parsear respuesta
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = LoginResponse.fromJson(data);
        _accessToken = _currentUser!.token;

        debugPrint('✅ Login successful');
        debugPrint('🎫 JWT Access Token: ${_accessToken!.substring(0, 50)}...');
        debugPrint('⏰ Expira en: ${_currentUser!.expiresIn} segundos (${_currentUser!.expiresIn ~/ 3600} horas)');
        debugPrint('👤 Role: ${_currentUser!.role}');
        debugPrint('🆔 User ID: ${_currentUser!.userId}');

        return true;
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized: Invalid credentials');
        return false;
      } else {
        debugPrint('❌ Login error: ${response.statusCode}');
        debugPrint('📝 Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Login exception: $e');
      return false;
    }
  }

  /// Registra un nuevo usuario
  /// Retorna true si el registro fue exitoso
  Future<bool> register(String email, String password) async {
    try {
      debugPrint('📝 Attempting registration for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      debugPrint('📡 Registration response: ${response.statusCode}');

      if (response.statusCode == 201) {
        // Parsear respuesta
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final regResponse = RegisterResponse.fromJson(data);

        debugPrint('✅ Registration successful');
        debugPrint('👤 Email: ${regResponse.email}');
        debugPrint('🆔 User ID: ${regResponse.userId}');
        debugPrint('📊 Role: ${regResponse.role}');

        return true;
      } else if (response.statusCode == 409) {
        debugPrint('❌ Conflict: Email already registered');
        return false;
      } else {
        debugPrint('❌ Registration error: ${response.statusCode}');
        debugPrint('📝 Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Registration exception: $e');
      return false;
    }
  }

  /// Verifica si el token actual es válido
  Future<bool> verifyToken() async {
    if (_accessToken == null) {
      debugPrint('❌ No token available');
      return false;
    }

    try {
      debugPrint('🔍 Verifying token...');

      final response = await http.get(
        Uri.parse('$baseUrl/verify_token'),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Token is valid');
        return true;
      } else {
        debugPrint('❌ Token verification failed: ${response.statusCode}');
        _accessToken = null;
        _currentUser = null;
        return false;
      }
    } catch (e) {
      debugPrint('❌ Token verification exception: $e');
      return false;
    }
  }

  /// Logout - elimina el token
  void logout() {
    debugPrint('🚪 Logging out user: ${_currentUser?.userId}');
    _accessToken = null;
    _currentUser = null;
    debugPrint('✅ Logout successful');
  }

  // ============================================================================
  // HEALTH CHECK
  // ============================================================================

  /// Verifica que el backend esté disponible
  Future<bool> checkHealth() async {
    try {
      debugPrint('💓 Checking backend health...');

      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'ok') {
          debugPrint('✅ Backend is healthy');
          return true;
        }
      }

      debugPrint('❌ Backend health check failed');
      return false;
    } catch (e) {
      debugPrint('❌ Health check exception: $e');
      return false;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Realiza una petición GET con autenticación
  Future<http.Response> getAuthenticatedRequest(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      return response;
    } catch (e) {
      debugPrint('❌ GET request exception: $e');
      rethrow;
    }
  }

  /// Realiza una petición POST con autenticación
  Future<http.Response> postAuthenticatedRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      return response;
    } catch (e) {
      debugPrint('❌ POST request exception: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MODERATOR ENDPOINTS
  // ============================================================================

  /// Obtiene los grupos asignados al moderador actual
  Future<List<Map<String, dynamic>>> fetchModeratorGroups() async {
    final response = await getAuthenticatedRequest('/api/mod/groups');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception('Failed to fetch groups (${response.statusCode})');
  }

  /// Registra producción diaria para un grupo
  Future<bool> registerProduction({
    required String groupId,
    required String date,
    required double tokens,
  }) async {
    final response = await postAuthenticatedRequest(
      '/api/mod/production',
      {
        'group_id': groupId,
        'date': date,
        'tokens': tokens,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    }

    // Intentar extraer mensaje de error legible
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Error ${response.statusCode}');
    } catch (_) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider global para ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Provider para el estado de autenticación
final authStateProvider = StateProvider<bool>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.isAuthenticated;
});

/// Provider para el usuario actual
final currentUserProvider = StateProvider<LoginResponse?>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.currentUser;
});

/// Provider para el token actual
final accessTokenProvider = StateProvider<String?>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.accessToken;
});
