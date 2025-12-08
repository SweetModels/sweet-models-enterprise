import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle token refresh and automatic renewal
class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  
  final Dio _dio;
  
  TokenService(this._dio);
  
  /// Store tokens after login/refresh
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
    
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());
  }
  
  /// Get stored access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }
  
  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
  
  /// Check if access token is expired or about to expire (within 5 minutes)
  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_tokenExpiryKey);
    
    if (expiryStr == null) return true;
    
    final expiryTime = DateTime.parse(expiryStr);
    final now = DateTime.now();
    
    // Consider token expired if less than 5 minutes remaining
    return now.isAfter(expiryTime.subtract(const Duration(minutes: 5)));
  }
  
  /// Refresh the access token using refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      
      if (refreshToken == null) {
        print('No refresh token available');
        return false;
      }
      
      print('🔄 Refreshing access token...');
      
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        await storeTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresIn: data['expires_in'],
        );
        
        print('✅ Token refreshed successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Token refresh failed: $e');
      return false;
    }
  }
  
  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
  }
  
  /// Logout with server-side token revocation
  Future<void> logout() async {
    try {
      final refreshToken = await getRefreshToken();
      
      if (refreshToken != null) {
        await _dio.post(
          '/auth/logout',
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (e) {
      print('Logout API call failed: $e');
    } finally {
      await clearTokens();
    }
  }
}

/// Dio interceptor for automatic token refresh
class TokenInterceptor extends Interceptor {
  final TokenService tokenService;
  final Dio dio;
  
  TokenInterceptor(this.tokenService, this.dio);
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token injection for auth endpoints
    if (options.path.contains('/login') || 
        options.path.contains('/register') ||
        options.path.contains('/auth/refresh')) {
      return handler.next(options);
    }
    
    // Check if token is expired
    final isExpired = await tokenService.isTokenExpired();
    
    if (isExpired) {
      print('⏰ Token expired, attempting refresh...');
      final refreshed = await tokenService.refreshAccessToken();
      
      if (!refreshed) {
        print('❌ Token refresh failed, clearing session');
        await tokenService.clearTokens();
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Session expired. Please login again.',
            type: DioExceptionType.connectionTimeout,
          ),
        );
      }
    }
    
    // Inject access token
    final accessToken = await tokenService.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    
    return handler.next(options);
  }
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // If we get 401, try to refresh token once
    if (err.response?.statusCode == 401) {
      print('⚠️  401 Unauthorized - attempting token refresh');
      
      final refreshed = await tokenService.refreshAccessToken();
      
      if (refreshed) {
        // Retry the original request
        try {
          final accessToken = await tokenService.getAccessToken();
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $accessToken';
          
          final response = await dio.fetch(options);
          return handler.resolve(response);
        } catch (e) {
          print('❌ Retry failed after token refresh');
        }
      }
      
      // If refresh failed, clear tokens
      await tokenService.clearTokens();
    }
    
    return handler.next(err);
  }
}
