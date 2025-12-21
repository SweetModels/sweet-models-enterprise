import 'package:flutter/foundation.dart';

/// Modelo de datos para las estadísticas del dashboard administrativo
class DashboardStats {
  final int totalTokens;
  final double totalRevenueCop;
  final int activeModels;
  final int alertsCount;
  final String? message;
  final DateTime? lastUpdated;

  DashboardStats({
    required this.totalTokens,
    required this.totalRevenueCop,
    required this.activeModels,
    required this.alertsCount,
    this.message,
    this.lastUpdated,
  });

  /// Factory para convertir JSON a DashboardStats
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalTokens: json['total_tokens'] as int? ?? 0,
      totalRevenueCop: (json['total_revenue_cop'] as num?)?.toDouble() ?? 0.0,
      activeModels: json['active_models'] as int? ?? 0,
      alertsCount: json['alerts_count'] as int? ?? 0,
      message: json['message'] as String?,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
    );
  }

  /// Convertir DashboardStats a JSON
  Map<String, dynamic> toJson() => {
    'total_tokens': totalTokens,
    'total_revenue_cop': totalRevenueCop,
    'active_models': activeModels,
    'alerts_count': alertsCount,
    'message': message,
    'last_updated': lastUpdated?.toIso8601String(),
  };

  /// Crear instancia vacía (para estados iniciales)
  factory DashboardStats.empty() {
    return DashboardStats(
      totalTokens: 0,
      totalRevenueCop: 0.0,
      activeModels: 0,
      alertsCount: 0,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  String toString() => 'DashboardStats(tokens: $totalTokens, revenue: $totalRevenueCop, models: $activeModels, alerts: $alertsCount)';
}

/// Modelo para items de actividad en vivo
class LiveActivityItem {
  final String id;
  final String modelName;
  final String roomName;
  final int viewersCount;
  final String status; // 'streaming', 'idle', 'offline'
  final DateTime startedAt;

  LiveActivityItem({
    required this.id,
    required this.modelName,
    required this.roomName,
    required this.viewersCount,
    required this.status,
    required this.startedAt,
  });

  factory LiveActivityItem.fromJson(Map<String, dynamic> json) {
    return LiveActivityItem(
      id: json['id'] as String,
      modelName: json['model_name'] as String,
      roomName: json['room_name'] as String,
      viewersCount: json['viewers_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'idle',
      startedAt: DateTime.parse(json['started_at'] as String),
    );
  }
}

/// Modelo para alertas del sistema
class SystemAlert {
  final String id;
  final String type; // 'warning', 'error', 'info'
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  SystemAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory SystemAlert.fromJson(Map<String, dynamic> json) {
    return SystemAlert(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'info',
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}
