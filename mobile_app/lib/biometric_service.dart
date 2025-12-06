import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'user_email';

  /// Verifica si el dispositivo tiene hardware biométrico
  Future<bool> hasBiometricHardware() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si hay biometría inscrita (huella, FaceID, etc.)
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene los tipos de biometría disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Autentica al usuario con biometría
  Future<bool> authenticateWithBiometrics({
    String reason = 'Por favor, verifica tu identidad',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Habilita la autenticación biométrica y guarda el token
  Future<void> enableBiometricAuth({
    required String token,
    required String email,
  }) async {
    await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _emailKey, value: email);
  }

  /// Deshabilita la autenticación biométrica y elimina datos
  Future<void> disableBiometricAuth() async {
    await _secureStorage.delete(key: _biometricEnabledKey);
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _emailKey);
  }

  /// Verifica si la autenticación biométrica está habilitada
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Obtiene el token guardado si la autenticación biométrica está habilitada
  Future<String?> getStoredToken() async {
    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) return null;
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Obtiene el email guardado
  Future<String?> getStoredEmail() async {
    return await _secureStorage.read(key: _emailKey);
  }

  /// Intenta login con biometría
  Future<Map<String, dynamic>?> loginWithBiometrics() async {
    try {
      // Verificar si está habilitada
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) return null;

      // Obtener datos guardados
      final token = await getStoredToken();
      final email = await getStoredEmail();

      if (token == null || email == null) {
        await disableBiometricAuth();
        return null;
      }

      // Solicitar autenticación biométrica
      final authenticated = await authenticateWithBiometrics(
        reason: 'Inicia sesión con tu huella o FaceID',
      );

      if (!authenticated) return null;

      // Retornar datos de sesión
      return {
        'token': token,
        'email': email,
        'authenticated': true,
      };
    } catch (e) {
      return null;
    }
  }

  /// Obtiene un mensaje amigable del tipo de biometría disponible
  Future<String> getBiometricTypeMessage() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.isEmpty) {
      return 'autenticación biométrica';
    }

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    }

    if (biometrics.contains(BiometricType.fingerprint)) {
      return 'huella dactilar';
    }

    if (biometrics.contains(BiometricType.iris)) {
      return 'reconocimiento de iris';
    }

    return 'autenticación biométrica';
  }

  /// Verifica si el dispositivo y la biometría están listos
  Future<Map<String, dynamic>> checkBiometricStatus() async {
    final hasHardware = await hasBiometricHardware();
    final isAvailable = await isBiometricAvailable();
    final isEnabled = await isBiometricEnabled();
    final biometricType = await getBiometricTypeMessage();

    return {
      'hasHardware': hasHardware,
      'isAvailable': isAvailable,
      'isEnabled': isEnabled,
      'biometricType': biometricType,
    };
  }
}
