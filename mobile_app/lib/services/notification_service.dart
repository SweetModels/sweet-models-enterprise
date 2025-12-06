import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Notification model
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String priority;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionUrl;
  
  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.readAt,
    required this.createdAt,
    this.data,
    this.imageUrl,
    this.actionUrl,
  });
  
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      body: json['body'],
      type: json['notification_type'],
      priority: json['priority'],
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      data: json['data'] as Map<String, dynamic>?,
      imageUrl: json['image_url'],
      actionUrl: json['action_url'],
    );
  }
  
  bool get isUnread => readAt == null;
  
  bool get isHighPriority => priority == 'high' || priority == 'urgent';
}

/// Service to handle in-app notifications
class NotificationService {
  final Dio _dio;
  
  NotificationService(this._dio);
  
  /// Fetch notifications from server
  Future<Map<String, dynamic>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        '/api/notifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (unreadOnly) 'unread': 'true',
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        final notifications = (data['notifications'] as List)
            .map((n) => AppNotification.fromJson(n))
            .toList();
        
        return {
          'notifications': notifications,
          'unread_count': data['unread_count'] ?? 0,
          'total': data['total'] ?? 0,
        };
      }
      
      return {'notifications': <AppNotification>[], 'unread_count': 0, 'total': 0};
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return {'notifications': <AppNotification>[], 'unread_count': 0, 'total': 0};
    }
  }
  
  /// Mark notifications as read
  Future<bool> markAsRead(List<String> notificationIds) async {
    try {
      final response = await _dio.post(
        '/api/notifications/mark-read',
        data: {'notification_ids': notificationIds},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error marking notifications as read: $e');
      return false;
    }
  }
  
  /// Register device token for push notifications
  Future<bool> registerDeviceToken({
    required String token,
    required String platform,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final response = await _dio.post(
        '/api/notifications/register-device',
        data: {
          'token': token,
          'platform': platform,
          'device_info': deviceInfo,
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error registering device token: $e');
      return false;
    }
  }
  
  /// Cache notifications locally for offline access
  Future<void> cacheNotifications(List<AppNotification> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => {
        'id': n.id,
        'user_id': n.userId,
        'title': n.title,
        'body': n.body,
        'notification_type': n.type,
        'priority': n.priority,
        'read_at': n.readAt?.toIso8601String(),
        'created_at': n.createdAt.toIso8601String(),
        'data': n.data,
        'image_url': n.imageUrl,
        'action_url': n.actionUrl,
      }).toList();
      
      await prefs.setString('cached_notifications', json.encode(jsonList));
    } catch (e) {
      print('Error caching notifications: $e');
    }
  }
  
  /// Get cached notifications for offline mode
  Future<List<AppNotification>> getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_notifications');
      
      if (cached != null) {
        final jsonList = json.decode(cached) as List;
        return jsonList.map((n) => AppNotification.fromJson(n)).toList();
      }
    } catch (e) {
      print('Error loading cached notifications: $e');
    }
    
    return [];
  }
}
