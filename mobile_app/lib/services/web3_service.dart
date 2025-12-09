import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

/// Servicio Web3 mínimo usando WalletConnect + Metamask/TrustWallet
class Web3Service extends ChangeNotifier {
  Web3Service() {
    _connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
        name: 'Sweet Models Enterprise',
        description: 'Autenticación Web3',
        url: 'https://sweetmodels.app',
        icons: ['https://sweetmodels.app/icon.png'],
      ),
    );

    _connector.on('disconnect', (_) {
      _session = null;
      _address = null;
      notifyListeners();
    });
  }

  late final WalletConnect _connector;
  SessionStatus? _session;
  String? _address;

  String? get walletAddress => _address;
  bool get isConnected => _connector.connected && _address != null;
  String? get connectedAddress => _address;
  String get chainId => 'ethereum'; // Retorna el chain ID actual

  /// Abre la app de la wallet y retorna la dirección pública
  Future<String?> connectWallet() async {
    try {
      if (_connector.connected && _address != null) {
        return _address;
      }

      _session = await _connector.createSession(onDisplayUri: (uri) async {
        final encoded = Uri.encodeComponent(uri);
        final metamaskDeepLink = 'https://metamask.app.link/wc?uri=$encoded';
        final trustWalletDeepLink = 'trustwallet://wc?uri=$uri';

        if (await canLaunchUrlString(metamaskDeepLink)) {
          await launchUrlString(metamaskDeepLink, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrlString(trustWalletDeepLink)) {
          await launchUrlString(trustWalletDeepLink, mode: LaunchMode.externalApplication);
        } else {
          await launchUrlString(uri, mode: LaunchMode.externalApplication);
        }
      });

      _address = _session?.accounts.isNotEmpty == true ? _session!.accounts.first : null;
      notifyListeners();
      return _address;
    } catch (e) {
      debugPrint('❌ Error conectando wallet: $e');
      return null;
    }
  }

  /// Solicita al usuario firmar un mensaje (nonce) y retorna la firma hex
  Future<String?> signMessage(String message) async {
    try {
      final address = _address ?? await connectWallet();
      if (address == null) throw Exception('Wallet no conectada');

      // personal_sign requiere el mensaje en hex
      final msgHex = '0x${bytesToHex(message.codeUnits)}';
      final sig = await _connector.sendCustomRequest(
        method: 'personal_sign',
        params: [msgHex, address],
      );

      return sig is String ? sig : sig?.toString();
    } catch (e) {
      debugPrint('❌ Error firmando: $e');
      return null;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connector.connected) {
        await _connector.killSession();
      }
      _session = null;
      _address = null;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error al desconectar: $e');
    }
  }

  /// Desconecta la wallet (alias para disconnect)
  Future<void> disconnectWallet() async => await disconnect();

  /// Obtiene el balance de la wallet (mock para ahora)
  Future<String> getBalance() async {
    try {
      if (_address == null) throw Exception('Wallet no conectada');
      // En producción, hacer llamada RPC real a eth_getBalance
      return '0.0 ETH'; // Mock
    } catch (e) {
      debugPrint('❌ Error obteniendo balance: $e');
      return '0.0 ETH';
    }
  }
}
