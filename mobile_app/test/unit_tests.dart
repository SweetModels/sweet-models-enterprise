import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_models_mobile/services/token_service.dart';
import 'package:sweet_models_mobile/services/notification_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TokenService Tests', () {
    late TokenService tokenService;
    late Dio dio;
    
    setUp(() {
      dio = Dio();
      tokenService = TokenService(dio);
      SharedPreferences.setMockInitialValues({});
    });
    
    test('Store and retrieve tokens', () async {
      await tokenService.storeTokens(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        expiresIn: 3600,
      );
      
      final accessToken = await tokenService.getAccessToken();
      final refreshToken = await tokenService.getRefreshToken();
      
      expect(accessToken, 'test_access_token');
      expect(refreshToken, 'test_refresh_token');
    });
    
    test('Check token expiration', () async {
      // Store token that expires in 1 second
      await tokenService.storeTokens(
        accessToken: 'test_token',
        refreshToken: 'refresh_token',
        expiresIn: 1,
      );
      
      // Should not be expired immediately
      final isExpired = await tokenService.isTokenExpired();
      expect(isExpired, false);
      
      // Wait for expiration
      await Future.delayed(const Duration(seconds: 2));
      
      final isExpiredNow = await tokenService.isTokenExpired();
      expect(isExpiredNow, true);
    });
    
    test('Clear tokens', () async {
      await tokenService.storeTokens(
        accessToken: 'test_token',
        refreshToken: 'refresh_token',
        expiresIn: 3600,
      );
      
      await tokenService.clearTokens();
      
      final accessToken = await tokenService.getAccessToken();
      expect(accessToken, null);
    });
  });
  
  group('NotificationService Tests', () {
    test('Parse notification from JSON', () {
      final json = {
        'id': '123',
        'user_id': '456',
        'title': 'Test Notification',
        'body': 'This is a test',
        'notification_type': 'info',
        'priority': 'normal',
        'read_at': null,
        'created_at': '2024-01-01T00:00:00Z',
        'data': null,
        'image_url': null,
        'action_url': null,
      };
      
      final notification = AppNotification.fromJson(json);
      
      expect(notification.id, '123');
      expect(notification.title, 'Test Notification');
      expect(notification.isUnread, true);
      expect(notification.isHighPriority, false);
    });
    
    test('Check high priority notifications', () {
      final normalNotif = AppNotification(
        id: '1',
        userId: '1',
        title: 'Normal',
        body: 'Normal notification',
        type: 'info',
        priority: 'normal',
        createdAt: DateTime.now(),
      );
      
      final urgentNotif = AppNotification(
        id: '2',
        userId: '1',
        title: 'Urgent',
        body: 'Urgent notification',
        type: 'warning',
        priority: 'urgent',
        createdAt: DateTime.now(),
      );
      
      expect(normalNotif.isHighPriority, false);
      expect(urgentNotif.isHighPriority, true);
    });
  });
  
  group('Payroll Calculation Tests', () {
    test('Calculate model payment', () {
      final tokens = 15000.0;
      final membersCount = 3;
      final trm = 4000.0;
      final tokenValueMultiplier = 0.05;
      
      final totalUsd = tokens * tokenValueMultiplier; // $750
      final totalCop = totalUsd * trm; // $3,000,000 COP
      final perModel = totalCop / membersCount; // $1,000,000 COP
      
      expect(perModel, 1000000.0);
    });
    
    test('Daily goal check', () {
      expect(goalAchieved(9500), false);
      expect(goalAchieved(10000), true);
      expect(goalAchieved(12000), true);
    });
  });
  
  group('Utility Function Tests', () {
    test('Format currency', () {
      final amount = 1234567.89;
      final formatted = formatCurrency(amount);
      
      expect(formatted, contains('\$'));
      expect(formatted, contains('1,234,567'));
    });
    
    test('Format tokens with K suffix', () {
      expect(formatTokens(500), '500');
      expect(formatTokens(1500), '1.5K');
      expect(formatTokens(15000), '15.0K');
      expect(formatTokens(150000), '150.0K');
    });
    
    test('Percentage calculation', () {
      final current = 7500.0;
      final goal = 10000.0;
      final percentage = (current / goal * 100).round();
      
      expect(percentage, 75);
    });
  });
}

// Helper functions for tests
bool goalAchieved(double tokens) => tokens >= 10000.0;

String formatCurrency(double amount) {
  final parts = amount.toStringAsFixed(2).split('.');
  final integerPart = parts[0];
  final decimalPart = parts[1];
  
  final formattedInteger = integerPart.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  
  return '\$$formattedInteger.$decimalPart';
}

String formatTokens(double tokens) {
  if (tokens < 1000) {
    return tokens.toStringAsFixed(0);
  } else {
    return '${(tokens / 1000).toStringAsFixed(1)}K';
  }
}
