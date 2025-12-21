import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:typed_data';
import 'models/financial_candle.dart';
import 'models/model_home.dart';

// Provider para ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Modelos de datos
class LoginResponse {
  final String token;
  final String? refreshToken;
  final String? tokenType;
  final int? expiresIn;
  final String role;
  final String userId;
  final String? name;

  LoginResponse({
    required this.token,
    this.refreshToken,
    this.tokenType,
    this.expiresIn,
    required this.role,
    required this.userId,
    this.name,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String? ?? json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      tokenType: json['token_type'] as String?,
      expiresIn: json['expires_in'] as int?,
      role: json['role'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String?,
    );
  }
}

class GroupData {
  final String name;
  final String platform;
  final double totalTokens;
  final int membersCount;
  final double payoutPerMemberCop;
  final DateTime createdAt;

  GroupData({
    required this.name,
    required this.platform,
    required this.totalTokens,
    required this.membersCount,
    required this.payoutPerMemberCop,
    required this.createdAt,
  });

  factory GroupData.fromJson(Map<String, dynamic> json) {
    return GroupData(
      name: json['name'] as String,
      platform: json['platform'] as String,
      totalTokens: (json['total_tokens'] as num).toDouble(),
      membersCount: json['members_count'] as int,
      payoutPerMemberCop: (json['payout_per_member_cop'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

class FinancialPlan {
  final double totalAmount;
  final double stocksPercentage;
  final double bondsPercentage;
  final double cashPercentage;
  final double stocksAmount;
  final double bondsAmount;
  final double cashAmount;
  final String riskTolerance;

  FinancialPlan({
    required this.totalAmount,
    required this.stocksPercentage,
    required this.bondsPercentage,
    required this.cashPercentage,
    required this.stocksAmount,
    required this.bondsAmount,
    required this.cashAmount,
    required this.riskTolerance,
  });

  factory FinancialPlan.fromJson(Map<String, dynamic> json) {
    return FinancialPlan(
      totalAmount: (json['total_amount'] as num).toDouble(),
      stocksPercentage: (json['stocks_percentage'] as num).toDouble(),
      bondsPercentage: (json['bonds_percentage'] as num).toDouble(),
      cashPercentage: (json['cash_percentage'] as num).toDouble(),
      stocksAmount: (json['stocks_amount'] as num).toDouble(),
      bondsAmount: (json['bonds_amount'] as num).toDouble(),
      cashAmount: (json['cash_amount'] as num).toDouble(),
      riskTolerance: json['risk_tolerance'] as String,
    );
  }
}

class DashboardData {
  final List<GroupData> groups;
  final double totalTokens;
  final int totalMembers;
  final double totalPayoutCop;
  final double trmUsed;

  DashboardData({
    required this.groups,
    required this.totalTokens,
    required this.totalMembers,
    required this.totalPayoutCop,
    required this.trmUsed,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      groups: (json['groups'] as List)
          .map((g) => GroupData.fromJson(g as Map<String, dynamic>))
          .toList(),
      totalTokens: (json['total_tokens'] as num).toDouble(),
      totalMembers: json['total_members'] as int,
      totalPayoutCop: (json['total_payout_cop'] as num).toDouble(),
      trmUsed: (json['trm_used'] as num).toDouble(),
    );
  }
}

class ApiService {
  // Producción en Railway con HTTPS seguro
  static const String baseUrl = 'https://sweet-models-enterprise-production.up.railway.app/';
  
  late final Dio _dio;
  String? _accessToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Interceptor para agregar token a todas las peticiones
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_accessToken == null) {
          _accessToken = await _getStoredToken();
        }
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('❌ API Error: ${error.message}');
        if (error.response?.statusCode == 401) {
          // Token expirado, limpiar sesión
          logout();
        }
        return handler.next(error);
      },
    ));
  }

  // Obtener token almacenado
  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Guardar token
  Future<void> _saveToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // Limpiar token (logout)
  Future<void> logout() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
  }

  // Login
  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final loginResponse = LoginResponse.fromJson(response.data);
      
      // Guardar token y datos del usuario
      await _saveToken(loginResponse.token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', loginResponse.role);
      await prefs.setString('user_id', loginResponse.userId);
      await prefs.setString('user_email', email);

      print('✅ Login exitoso: ${loginResponse.role}');
      return loginResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error en login');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }

  // Registro
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'email': email,
          'password': password,
        },
      );

      print('✅ Registro exitoso');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error en registro');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }

  // Obtener datos del Dashboard
  Future<DashboardData> getDashboardData() async {
    try {
      final response = await _dio.get('/dashboard');
      
      print('✅ Dashboard data received: ${response.data}');
      return DashboardData.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        print('❌ Dashboard error: ${e.response?.data}');
        throw Exception(e.response?.data.toString() ?? 'Error al cargar dashboard');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }

  // ============================================================================
  // MODERATOR ENDPOINTS
  // ============================================================================

  Future<List<Map<String, dynamic>>> fetchModeratorGroups() async {
    try {
      final response = await _dio.get('/api/mod/groups');
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Error al cargar grupos (${response.statusCode})');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Error de conexión');
    }
  }

  Future<bool> registerProduction({
    required String groupId,
    required String date,
    required double tokens,
  }) async {
    try {
      final response = await _dio.post(
        '/api/mod/production',
        data: {
          'group_id': groupId,
          'date': date,
          'tokens': tokens,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      throw Exception('Error ${response.statusCode}: ${response.data}');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Error de conexión');
    }
  }

  // Verificar si hay sesión activa
  Future<bool> hasActiveSession() async {
    final token = await _getStoredToken();
    return token != null && token.isNotEmpty;
  }

  // Obtener rol del usuario
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  // Calcular plan financiero
  Future<FinancialPlan> calculateFinancialPlan(
    double amount,
    String riskTolerance,
  ) async {
    try {
      final response = await _dio.post(
        '/api/financial_planning',
        data: {
          'amount': amount,
          'risk_tolerance': riskTolerance,
        },
      );

      print('✅ Financial plan calculated');
      return FinancialPlan.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error calculating plan');
      } else {
        throw Exception('Connection error: ${e.message}');
      }
    }
  }

  // Registro avanzado de modelo
  Future<Map<String, dynamic>> registerModel({
    required String email,
    required String password,
    required String phone,
    required String address,
    required String nationalId,
  }) async {
    try {
      final response = await _dio.post(
        '/register_model',
        data: {
          'email': email,
          'password': password,
          'phone': phone,
          'address': address,
          'national_id': nationalId,
        },
      );

      print('✅ Modelo registrado exitosamente');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Error en registro de modelo');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }

  // Obtener cámaras (solo admin)
  Future<Map<String, dynamic>> getCameras() async {
    try {
      final response = await _dio.get('/admin/cameras');
      
      print('✅ Cámaras obtenidas: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error al cargar cámaras');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }

  // Obtener TRM actual
  Future<Map<String, dynamic>> getCurrentTRM() async {
    try {
      final response = await _dio.get('/admin/trm');
      
      print('✅ TRM actual: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error al obtener TRM');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }

  // Actualizar TRM (solo admin)
  Future<Map<String, dynamic>> updateTRM(double trmValue) async {
    try {
      final response = await _dio.post(
        '/admin/trm',
        data: {'trm_value': trmValue},
      );

      print('✅ TRM actualizado: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error al actualizar TRM');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }

  // Calcular nómina con sistema Doble TRM
  Future<Map<String, dynamic>> calculatePayroll({
    required double groupTokens,
    required int membersCount,
    double? manualTrm,
  }) async {
    try {
      final data = {
        'group_tokens': groupTokens,
        'members_count': membersCount,
      };
      
      if (manualTrm != null) {
        data['manual_trm'] = manualTrm;
      }

      final response = await _dio.post('/api/payroll/calculate', data: data);

      print('✅ Nómina calculada: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error al calcular nómina');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // NUEVOS MÉTODOS PARA PANTALLAS AVANZADAS
  // ════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await _dio.post(
        '/auth/send-otp',
        data: {'phone': phone},
      );
      print('✅ OTP sent: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error sending OTP');
      } else {
        throw Exception('Connection error: ${e.message}');
      }
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {'phone': phone, 'code': code},
      );
      print('✅ OTP verified: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error verifying OTP');
      } else {
        throw Exception('Connection error: ${e.message}');
      }
    }
  }

  Future<Map<String, dynamic>> uploadKycDocument({
    required String userId,
    required String documentType,
    required File imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'document_type': documentType,
        'file': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _dio.post(
        '/upload/kyc',
        data: formData,
      );

      print('✅ Document uploaded: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error uploading document');
      } else {
        throw Exception('Connection error: ${e.message}');
      }
    }
  }

  Future<List<FinancialCandle>> getFinancialHistory() async {
    try {
      final response = await _dio.get(
        '/api/admin/financial-history',
      );
      print('✅ Financial history fetched: ${response.data}');
      
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => FinancialCandle.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error fetching financial data');
      } else {
        throw Exception('Connection error: ${e.message}');
      }
    }
  }

  Future<ModelHomeStats> getModelHomeStats() async {
    try {
      final response = await _dio.get('/api/model/home');
      return ModelHomeStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error al cargar el home de modelo');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }

  Future<Map<String, dynamic>> signContract(Uint8List signatureBytes) async {
    try {
      final formData = FormData.fromMap({
        'signature': MultipartFile.fromBytes(
          signatureBytes,
          filename: 'signature.png',
        ),
      });

      final response = await _dio.post('/api/model/sign-contract', data: formData);
      return (response.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error al firmar contrato');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }

  Future<Map<String, dynamic>> linkSocialAccount({
    required String platform,
    required String handle,
  }) async {
    try {
      final response = await _dio.post(
        '/api/model/social',
        data: {
          'platform': platform,
          'handle': handle,
        },
      );

      return (response.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error al vincular red social');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }
}
