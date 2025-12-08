import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

/// Servicio para conectar con Metamask, Phantom y otros wallets Web3
/// Soporta: Ethereum, Polygon
class Web3Service extends ChangeNotifier {
  // Estado de conexión
  EthereumAddress? _connectedAddress;
  Web3Client? _web3Client;
  String? _chainId;
  bool _isConnected = false;

  // Getters
  EthereumAddress? get connectedAddress => _connectedAddress;
  bool get isConnected => _isConnected;
  String? get chainId => _chainId;

  final String _rpcUrl = 'https://mainnet.infura.io/v3/7e6c91e5d5a15b2f5c7d8e8c8d9e9e9e';

  Web3Service();

  /// 🔗 Conectar con WalletConnect v2 (Metamask, Phantom, etc.)
  Future<bool> connectWallet() async {
    try {
      // Simular conexión - en producción usar walletconnect_flutter_v2
      _connectedAddress = EthereumAddress.fromHex('0x742d35Cc6634C0532925a3b844Bc3e7d8c4eC7f6');
      _chainId = '1';
      _isConnected = true;
      
      // Inicializar Web3Client
      _web3Client = Web3Client(_rpcUrl, http.Client());
      
      notifyListeners();
      debugPrint('✅ Wallet conectado: ${_connectedAddress?.hex}');
      return true;
    } catch (e) {
      debugPrint('❌ Error conectando: $e');
      _isConnected = false;
      return false;
    }
  }

  /// ✍️ Firmar un mensaje con el wallet
  Future<String?> signMessage(String message) async {
    try {
      if (!_isConnected || _connectedAddress == null) {
        throw Exception('Wallet no conectado');
      }

      // Simular firma - en producción usar walletconnect_flutter_v2
      final signature = '0x' + List<int>.generate(65, (_) => 42).map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      
      debugPrint('✅ Mensaje firmado');
      return signature;
    } catch (e) {
      debugPrint('❌ Error firmando: $e');
      return null;
    }
  }

  /// 💰 Obtener balance de Ether
  Future<EtherAmount?> getBalance() async {
    try {
      if (_web3Client == null || _connectedAddress == null) {
        throw Exception('Wallet o cliente no inicializado');
      }

      final balance = await _web3Client!.getBalance(_connectedAddress!);
      debugPrint('💰 Balance: ${balance.getValueInUnit(EtherUnit.ether)} ETH');
      return balance;
    } catch (e) {
      debugPrint('❌ Error obteniendo balance: $e');
      return null;
    }
  }

  /// 💸 Enviar transacción
  Future<String?> sendTransaction({
    required String toAddress,
    required String amount,
    required String? privateKey,
  }) async {
    try {
      if (_web3Client == null || privateKey == null) {
        throw Exception('Configuración incompleta');
      }

      final credential = EthPrivateKey.fromHex(privateKey);
      final txHash = await _web3Client!.sendTransaction(
        credential,
        Transaction(
          to: EthereumAddress.fromHex(toAddress),
          value: EtherAmount.fromUnitAndValue(EtherUnit.ether, amount),
          gasPrice: EtherAmount.inWei(BigInt.one),
        ),
        chainId: int.tryParse(_chainId ?? '1'),
      );

      debugPrint('✅ Transacción enviada: $txHash');
      return txHash;
    } catch (e) {
      debugPrint('❌ Error en transacción: $e');
      return null;
    }
  }

  /// 🔌 Desconectar wallet
  Future<void> disconnectWallet() async {
    try {
      _isConnected = false;
      _connectedAddress = null;
      _chainId = null;
      _web3Client?.dispose();
      notifyListeners();
      debugPrint('✅ Wallet desconectado');
    } catch (e) {
      debugPrint('❌ Error desconectando: $e');
    }
  }

  @override
  void dispose() {
    _web3Client?.dispose();
    super.dispose();
  }
}
