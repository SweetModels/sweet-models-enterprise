import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';

/// Servicio para conectar con el backend via gRPC (puerto 50051)
/// Proporciona comunicación rápida y eficiente con el servidor Rust
class GrpcClient extends ChangeNotifier {
  ClientChannel? _channel;
  bool _isConnected = false;
  String _lastError = '';

  bool get isConnected => _isConnected;
  String get lastError => _lastError;

  final String _host = 'localhost'; // O tu IP/dominio del servidor
  final int _port = 50051;

  /// 🔌 Conectar con el servidor gRPC
  Future<bool> connect() async {
    try {
      _channel = ClientChannel(
        _host,
        port: _port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );

      // Simular verificación de conexión
      _isConnected = true;
      _lastError = '';
      notifyListeners();
      
      debugPrint('✅ Conectado a gRPC servidor en $_host:$_port');
      return true;
    } catch (e) {
      _lastError = 'Error conectando: $e';
      _isConnected = false;
      notifyListeners();
      debugPrint('❌ Error conectando a gRPC: $e');
      return false;
    }
  }

  /// 💬 Enviar mensaje al chat
  Future<bool> sendChatMessage(String message, String userId) async {
    try {
      if (!_isConnected) {
        throw Exception('gRPC no conectado');
      }

      // Aquí irá la llamada real al servicio gRPC de chat
      // Por ahora es un esqueleto
      debugPrint('📨 Enviando mensaje: $message desde usuario: $userId');
      
      return true;
    } catch (e) {
      _lastError = 'Error enviando mensaje: $e';
      notifyListeners();
      debugPrint('❌ Error: $e');
      return false;
    }
  }

  /// 📖 Recibir stream de mensajes
  Stream<String> getChatStream(String channelId) async* {
    try {
      if (!_isConnected) {
        throw Exception('gRPC no conectado');
      }

      // Stream de mensajes del servidor
      // Implementar cuando tengamos el proto definido
      yield* const Stream.empty();
    } catch (e) {
      _lastError = 'Error obteniendo stream: $e';
      notifyListeners();
      debugPrint('❌ Error: $e');
    }
  }

  /// 💰 Obtener balance del usuario
  Future<double?> getUserBalance(String userId) async {
    try {
      if (!_isConnected) {
        throw Exception('gRPC no conectado');
      }

      // Llamada simulada - reemplazar con proto real
      debugPrint('💰 Obteniendo balance para usuario: $userId');
      return 1000.0; // Simulado
    } catch (e) {
      _lastError = 'Error obteniendo balance: $e';
      notifyListeners();
      debugPrint('❌ Error: $e');
      return null;
    }
  }

  /// 🔌 Desconectar
  Future<void> disconnect() async {
    try {
      await _channel?.shutdown();
      _isConnected = false;
      notifyListeners();
      debugPrint('✅ Desconectado de gRPC');
    } catch (e) {
      debugPrint('❌ Error desconectando: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
