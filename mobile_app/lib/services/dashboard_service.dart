import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_stats.dart';

/// Servicio para obtener datos del dashboard administrativo
class DashboardService {
  late final Dio _dio;
  static const String baseUrl = 'http://10.0.2.2:3000'; // Android Emulator
  String? _cachedToken;

  DashboardService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  /// Cargar el token desde SharedPreferences
  Future<String?> _getToken() async {
    if (_cachedToken != null) return _cachedToken;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('access_token');
    return _cachedToken;
  }

  /// Obtener headers con autorización
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtener estadísticas del dashboard administrativo
  /// 
  /// Hace un GET a /admin/dashboard y retorna un objeto DashboardStats
  /// Si falla, lanza una excepción con el mensaje del error
  Future<DashboardStats> getAdminStats() async {
    try {
      debugPrint('🔄 Obteniendo estadísticas del dashboard...');
      
      final headers = await _getHeaders();
      final token = await _getToken();
      
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await _dio.get(
        '/admin/dashboard',
        options: Options(headers: headers),
      );

      debugPrint('✅ Respuesta recibida: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final stats = DashboardStats.fromJson(response.data);
        debugPrint('📊 Stats: $stats');
        return stats;
      } else {
        throw Exception('Error: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      debugPrint('❌ Error Dio: ${e.message}');
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error: $e');
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Obtener actividad en vivo (modelos transmitiendo)
  Future<List<LiveActivityItem>> getLiveActivity() async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        '/admin/live-activity',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((item) => LiveActivityItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo actividad en vivo: $e');
      return [];
    }
  }

  /// Obtener alertas del sistema
  Future<List<SystemAlert>> getSystemAlerts() async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        '/admin/alerts',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((item) => SystemAlert.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo alertas: $e');
      return [];
    }
  }

  /// Marcar alerta como leída
  Future<void> markAlertAsRead(String alertId) async {
    try {
      final headers = await _getHeaders();
      await _dio.post(
        '/admin/alerts/$alertId/mark-read',
        options: Options(headers: headers),
      );
    } catch (e) {
      debugPrint('Error marcando alerta: $e');
    }
  }

  /// Limpiar token en caché (para logout)
  void clearCache() {
    _cachedToken = null;
  }

  /// Registrar producción diaria para una modelo (solo ADMIN)
  Future<void> registerProduction({
    required String modelEmail,
    required int tokens,
    required String platform,
  }) async {
    try {
      final headers = await _getHeaders();
      final token = await _getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final payload = {
        'model_email': modelEmail,
        'tokens': tokens,
        'platform': platform,
      };

      final response = await _dio.post(
        '/api/admin/production',
        data: payload,
        options: Options(headers: headers),
      );

      if (response.statusCode != 200) {
        throw Exception('Error ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    } catch (e) {
      throw Exception('Error registrando producción: $e');
    }
  }

  /// Aplicar sanción a una modelo (solo ADMIN)
  Future<double> penalizeModel({
    required String modelEmail,
    required String reason,
    required int xpPenalty,
  }) async {
    try {
      final headers = await _getHeaders();
      final token = await _getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final payload = {
        'model_email': modelEmail,
        'reason': reason,
        'xp_penalty': xpPenalty,
      };

      final response = await _dio.post(
        '/api/admin/penalize',
        data: payload,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return (data['new_xp'] as num?)?.toDouble() ?? 0.0;
      } else if (response.statusCode == 401) {
        debugPrint('⚠️ Token inválido (401): Vuelva a iniciar sesión con /api/auth/login');
        throw Exception('Token inválido. Por favor, inicie sesión nuevamente.');
      } else if (response.statusCode == 403) {
        debugPrint('❌ Permiso denegado (403): Se requiere rol ADMIN');
        throw Exception('Permiso denegado: Solo administradores pueden aplicar sanciones.');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        debugPrint('⚠️ DioException 401: Token expirado o inválido');
        throw Exception('Sesión expirada. Por favor, inicie sesión nuevamente.');
      }
      throw Exception('Error de red: ${e.message}');
    } catch (e) {
      throw Exception('Error aplicando sanción: $e');
    }
  }
}
