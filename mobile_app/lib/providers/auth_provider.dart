import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier(ref);
});

class UserNotifier extends StateNotifier<User?> {
  final Ref ref;

  UserNotifier(this.ref) : super(null) {
    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final userJson = await storage.read(key: 'user_data');
      if (userJson != null) {
        state = User.fromJson(Map<String, dynamic>.from(
          Map.from(userJson as Map? ?? {}),
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading stored user: $e');
      }
    }
  }

  Future<void> storeUser(User user) async {
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.write(key: 'user_data', value: user.toJson().toString());
      state = user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error storing user: $e');
      }
      rethrow;
    }
  }

  Future<void> clearUser() async {
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.delete(key: 'user_data');
      state = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing user: $e');
      }
      rethrow;
    }
  }

  bool get isAuthenticated => state != null;
  bool get isAdmin => state?.role == 'admin';
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref ref;
  late final ApiService _apiService;

  AuthNotifier(this.ref) : super(const AsyncValue.data(false)) {
    _apiService = ref.watch(apiServiceProvider);
    _checkServerHealth();
  }

  Future<void> _checkServerHealth() async {
    state = const AsyncValue.loading();
    try {
      final isHealthy = await _apiService.checkHealth();
      state = AsyncValue.data(isHealthy);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> setupAdmin() async {
    state = const AsyncValue.loading();
    try {
      // Llamar a setup_admin en el backend
      final response = await _apiService.postAuthenticatedRequest('/setup_admin', {});
      if (response.statusCode == 201 || response.statusCode == 200) {
        state = const AsyncValue.data(true);
      } else {
        throw Exception('Setup failed: ${response.statusCode}');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> refreshHealth() async {
    await _checkServerHealth();
  }
}
