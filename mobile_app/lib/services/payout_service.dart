// ============================================================================
// Sweet Models Enterprise - Payout Service
// Servicio para liquidaciones y pagos a modelos
// ============================================================================

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayoutService {
  final Dio _dio;
  static const String baseUrl = 'http://localhost:3000';

  PayoutService() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Initialize service with auth token
  Future<void> _setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Process a payout/liquidation
  /// POST /api/admin/payout
  Future<PayoutResponse> processPayout({
    required String userId,
    required double amount,
    required String method,
    String? transactionRef,
    String? notes,
  }) async {
    await _setAuthHeader();
    
    try {
      final response = await _dio.post('/api/admin/payout', data: {
        'user_id': userId,
        'amount': amount,
        'method': method,
        'transaction_ref': transactionRef,
        'notes': notes,
      });

      return PayoutResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to process payout');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get payout history for a user
  /// GET /api/admin/payouts?user_id=xxx
  Future<PayoutHistoryResponse> getPayoutHistory(String userId) async {
    await _setAuthHeader();
    
    try {
      final response = await _dio.get(
        '/api/admin/payouts',
        queryParameters: {'user_id': userId},
      );

      return PayoutHistoryResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to fetch payout history');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get user balance details
  /// GET /api/admin/user-balance/:user_id
  Future<UserBalanceResponse> getUserBalance(String userId) async {
    await _setAuthHeader();
    
    try {
      final response = await _dio.get('/api/admin/user-balance/$userId');
      return UserBalanceResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to fetch user balance');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Cache payout data for offline access
  Future<void> cachePayoutHistory(String userId, PayoutHistoryResponse data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_payouts_$userId', jsonEncode(data.toJson()));
  }

  /// Get cached payout data
  Future<PayoutHistoryResponse?> getCachedPayoutHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_payouts_$userId');
    if (cached != null) {
      return PayoutHistoryResponse.fromJson(jsonDecode(cached));
    }
    return null;
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class PayoutResponse {
  final String payoutId;
  final String userId;
  final double amount;
  final String method;
  final String? transactionRef;
  final String? receiptUrl;
  final double newPendingBalance;
  final String status;
  final String message;
  final String createdAt;

  PayoutResponse({
    required this.payoutId,
    required this.userId,
    required this.amount,
    required this.method,
    this.transactionRef,
    this.receiptUrl,
    required this.newPendingBalance,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    return PayoutResponse(
      payoutId: json['payout_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String,
      transactionRef: json['transaction_ref'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      newPendingBalance: (json['new_pending_balance'] as num).toDouble(),
      status: json['status'] as String,
      message: json['message'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payout_id': payoutId,
      'user_id': userId,
      'amount': amount,
      'method': method,
      'transaction_ref': transactionRef,
      'receipt_url': receiptUrl,
      'new_pending_balance': newPendingBalance,
      'status': status,
      'message': message,
      'created_at': createdAt,
    };
  }
}

class PayoutHistoryResponse {
  final List<PayoutRecord> payouts;
  final double totalPaid;
  final int totalCount;

  PayoutHistoryResponse({
    required this.payouts,
    required this.totalPaid,
    required this.totalCount,
  });

  factory PayoutHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PayoutHistoryResponse(
      payouts: (json['payouts'] as List)
          .map((e) => PayoutRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPaid: (json['total_paid'] as num).toDouble(),
      totalCount: json['total_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payouts': payouts.map((e) => e.toJson()).toList(),
      'total_paid': totalPaid,
      'total_count': totalCount,
    };
  }
}

class PayoutRecord {
  final String id;
  final double amount;
  final String method;
  final String? transactionRef;
  final String? notes;
  final String? receiptUrl;
  final String status;
  final String createdAt;
  final String? createdByEmail;

  PayoutRecord({
    required this.id,
    required this.amount,
    required this.method,
    this.transactionRef,
    this.notes,
    this.receiptUrl,
    required this.status,
    required this.createdAt,
    this.createdByEmail,
  });

  factory PayoutRecord.fromJson(Map<String, dynamic> json) {
    return PayoutRecord(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String,
      transactionRef: json['transaction_ref'] as String?,
      notes: json['notes'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      createdByEmail: json['created_by_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'method': method,
      'transaction_ref': transactionRef,
      'notes': notes,
      'receipt_url': receiptUrl,
      'status': status,
      'created_at': createdAt,
      'created_by_email': createdByEmail,
    };
  }
}

class UserBalanceResponse {
  final String userId;
  final String email;
  final double pendingBalance;
  final double totalEarned;
  final double totalPaid;
  final String? lastPayoutDate;

  UserBalanceResponse({
    required this.userId,
    required this.email,
    required this.pendingBalance,
    required this.totalEarned,
    required this.totalPaid,
    this.lastPayoutDate,
  });

  factory UserBalanceResponse.fromJson(Map<String, dynamic> json) {
    return UserBalanceResponse(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      pendingBalance: (json['pending_balance'] as num).toDouble(),
      totalEarned: (json['total_earned'] as num).toDouble(),
      totalPaid: (json['total_paid'] as num).toDouble(),
      lastPayoutDate: json['last_payout_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'pending_balance': pendingBalance,
      'total_earned': totalEarned,
      'total_paid': totalPaid,
      'last_payout_date': lastPayoutDate,
    };
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider for PayoutService singleton
final payoutServiceProvider = Provider<PayoutService>((ref) {
  return PayoutService();
});

/// Provider for user balance (admin dashboard)
final userBalanceProvider = FutureProvider.family<UserBalanceResponse, String>((ref, userId) async {
  final service = ref.read(payoutServiceProvider);
  return await service.getUserBalance(userId);
});

/// Provider for payout history
final payoutHistoryProvider = FutureProvider.family<PayoutHistoryResponse, String>((ref, userId) async {
  final service = ref.read(payoutServiceProvider);
  return await service.getPayoutHistory(userId);
});

/// State notifier for payout operations
class PayoutNotifier extends StateNotifier<AsyncValue<PayoutResponse?>> {
  final PayoutService _service;

  PayoutNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> processPayout({
    required String userId,
    required double amount,
    required String method,
    String? transactionRef,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final result = await _service.processPayout(
        userId: userId,
        amount: amount,
        method: method,
        transactionRef: transactionRef,
        notes: notes,
      );
      
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for PayoutNotifier
final payoutNotifierProvider = StateNotifierProvider<PayoutNotifier, AsyncValue<PayoutResponse?>>((ref) {
  final service = ref.read(payoutServiceProvider);
  return PayoutNotifier(service);
});
