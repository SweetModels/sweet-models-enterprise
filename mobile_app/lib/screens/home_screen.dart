import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:web3dart/web3dart.dart';
import '../providers/auth_provider.dart';
import '../services/web3_service.dart';
import '../services/grpc_client.dart';
import '../main.dart' show web3ServiceProvider, grpcClientProvider;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<types.Message> _messages = [];
  final List<types.User> _users = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    try {
      final web3Service = ref.read(web3ServiceProvider);
      final grpcClient = ref.read(grpcClientProvider);

      // Conectar a Web3
      await web3Service.connectWallet();

      // Conectar a gRPC
      await grpcClient.connect();

      // Configurar usuarios del chat
      _setupChatUsers();

      setState(() {});
    } catch (e) {
      debugPrint('Error inicializando servicios: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: Text(
          'Sweet Models Enterprise',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00d4ff),
          ),
        ),
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.account_balance_wallet), text: 'Web3'),
                Tab(icon: Icon(Icons.chat), text: 'Chat'),
                Tab(icon: Icon(Icons.settings), text: 'Config'),
              ],
              labelColor: const Color(0xFF00d4ff),
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildWeb3Tab(),
                  _buildChatTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeb3Tab() {
    final web3Service = ref.watch(web3ServiceProvider);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF16213e),
          child: ListTile(
            leading: Icon(
              web3Service.isConnected ? Icons.check_circle : Icons.error,
              color: web3Service.isConnected ? Colors.green : Colors.red,
            ),
            title: const Text('Wallet Status', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              web3Service.isConnected
                  ? 'Conectado: ${web3Service.connectedAddress?.hex.substring(0, 10)}...'
                  : 'No conectado',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: web3Service.isConnected
              ? () => _showDisconnectDialog(context, web3Service)
              : () => _connectWallet(context, web3Service),
          icon: Icon(
            web3Service.isConnected ? Icons.logout : Icons.login,
          ),
          label: Text(
            web3Service.isConnected ? 'Desconectar' : 'Conectar Wallet',
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: web3Service.isConnected ? Colors.red : Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        if (web3Service.isConnected)
          OutlinedButton.icon(
            onPressed: () => _getBalance(context, web3Service),
            icon: const Icon(Icons.account_balance),
            label: const Text('Ver Saldo'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        const SizedBox(height: 12),
        if (web3Service.isConnected)
          OutlinedButton.icon(
            onPressed: () => _signMessage(context, web3Service),
            icon: const Icon(Icons.edit),
            label: const Text('Firmar Mensaje'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        const SizedBox(height: 24),
        Card(
          color: const Color(0xFF16213e),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información de Red',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chain ID: ${web3Service.chainId ?? 'No definido'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Network: ${_getNetworkName(web3Service.chainId)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatTab() {
    final grpcClient = ref.watch(grpcClientProvider);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(
                grpcClient.isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: grpcClient.isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                grpcClient.isConnected
                    ? 'Conectado a backend'
                    : 'Desconectado',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: Chat(
            messages: _messages,
            onSendPressed: _handleSendChatMessage,
            user: _users.isNotEmpty ? _users[0] : const types.User(id: 'user'),
            showUserNames: true,
            showUserAvatars: true,
            theme: const DefaultChatTheme(
              backgroundColor: Color(0xFF1a1a2e),
              primaryColor: Color(0xFF00d4ff),
              secondaryColor: Color(0xFF16213e),
              inputBackgroundColor: Color(0xFF16213e),
              inputTextColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    final grpcClient = ref.watch(grpcClientProvider);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF16213e),
          child: ListTile(
            title: const Text('gRPC Server', style: TextStyle(color: Colors.white)),
            subtitle: const Text('localhost:50051', style: TextStyle(color: Colors.grey)),
            trailing: Icon(
              grpcClient.isConnected
                  ? Icons.check_circle
                  : Icons.error,
              color: grpcClient.isConnected ? Colors.green : Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF16213e),
          child: ListTile(
            title: const Text('Backend Ledger', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Auditoría criptográfica', style: TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.shield, color: Color(0xFF00d4ff)),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF16213e),
          child: ListTile(
            title: const Text('API Endpoint', style: TextStyle(color: Colors.white)),
            subtitle: const Text('http://localhost:3000', style: TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.api, color: Color(0xFF00d4ff)),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Future<void> _connectWallet(
    BuildContext context,
    Web3Service web3Service,
  ) async {
    final connected = await web3Service.connectWallet();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          connected ? '✅ Wallet conectado' : '❌ Error conectando',
        ),
      ),
    );
  }

  Future<void> _showDisconnectDialog(
    BuildContext context,
    Web3Service web3Service,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Desconectar Wallet', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que deseas desconectar?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await web3Service.disconnectWallet();
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }

  Future<void> _getBalance(
    BuildContext context,
    Web3Service web3Service,
  ) async {
    try {
      final balance = await web3Service.getBalance();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saldo: ${balance?.getValueInUnit(EtherUnit.ether)} ETH'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _signMessage(
    BuildContext context,
    Web3Service web3Service,
  ) async {
    try {
      final signature = await web3Service.signMessage('Hello Web3');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            signature != null ? '✅ Mensaje firmado' : '❌ Error firmando',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _getNetworkName(String? chainId) {
    switch (chainId) {
      case '1':
        return 'Ethereum Mainnet';
      case '5':
        return 'Ethereum Goerli Testnet';
      case '137':
        return 'Polygon Mainnet';
      case '80001':
        return 'Polygon Mumbai Testnet';
      default:
        return 'Unknown Network';
    }
  }

  void _setupChatUsers() {
    _users.clear();
    _users.add(
      types.User(
        id: '1',
        firstName: 'Mi Usuario',
        imageUrl: 'https://i.pravatar.cc/150?img=1',
      ),
    );
    _users.add(
      types.User(
        id: '2',
        firstName: 'Soporte',
        imageUrl: 'https://i.pravatar.cc/150?img=2',
      ),
    );
  }

  void _handleSendChatMessage(types.PartialText message) {
    final msg = types.TextMessage(
      author: _users[0],
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );
    
    setState(() {
      _messages.insert(0, msg);
    });
    
    final grpcClient = ref.read(grpcClientProvider);
    grpcClient.sendChatMessage(message.text, _users[0].id);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
