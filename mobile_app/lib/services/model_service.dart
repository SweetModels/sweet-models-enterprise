import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/model_home_screen.dart';

class ModelService {
  static const String baseUrl = 'http://10.0.2.2:3000';
  late final Dio _dio;

  ModelService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  Future<List<PenaltyEvent>> getRecentPenalties() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final headers = _getHeaders(token);
      final response = await _dio.get(
        '/api/model/penalties/recent',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final list = data['penalties'] as List<dynamic>? ?? [];
        return list.map((e) => PenaltyEvent.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load penalties: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching penalties: $e');
    }
  }

  /// Fetch model statistics from backend
  Future<ModelStats> getModelStats() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final headers = _getHeaders(token);
      final response = await _dio.get(
        '/api/model/stats',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return ModelStats.fromJson(response.data);
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching model stats: $e');
    }
  }

  /// Get authorization token from SharedPreferences
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      throw Exception('Failed to retrieve token: $e');
    }
  }

  /// Build authorization headers
  Map<String, String> _getHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Clear cached data if needed
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Add any cache clearing logic here
      // For example, removing cached stats
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Close Dio instance
  void dispose() {
    _dio.close();
  }
}

class PenaltyEvent {
  final String id;
  final String reason;
  final int xpDeduction;
  final DateTime createdAt;

  PenaltyEvent({
    required this.id,
    required this.reason,
    required this.xpDeduction,
    required this.createdAt,
  });

  factory PenaltyEvent.fromJson(Map<String, dynamic> json) {
    return PenaltyEvent(
      id: json['id'] as String,
      reason: json['reason'] as String,
      xpDeduction: json['xp_deduction'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
