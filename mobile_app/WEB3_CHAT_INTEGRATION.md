# 🚀 Mobile App - Web3 + Chat + gRPC Integration

## 📦 Dependencias Agregadas

### Web3 (Blockchain)

```yaml
web3dart: ^2.7.1          # Cliente Ethereum/Web3
walletconnect_dart: ^2.0.0 # Conexión con Metamask/Phantom
convert: ^3.1.1            # Conversión de datos
pointycastle: ^3.7.3       # Criptografía

```

### gRPC (Backend Communication)

```yaml
grpc: ^3.0.2               # Cliente gRPC para conexión rápida

```

### Chat UI

```yaml
flutter_chat_ui: ^1.6.13   # Interfaz de chat lista para usar
uuid: ^4.0.0               # Generación de IDs únicos

```

## 📁 Estructura de Servicios

```

lib/
├── services/
│   ├── web3_service.dart   # 🌐 Servicio Web3
│   ├── grpc_client.dart    # 📡 Cliente gRPC
│   └── services.dart       # Índice de exportación
└── screens/
    └── home_screen.dart    # 🏠 Pantalla integrada

```

## 🔧 Servicios Implementados

### 1. Web3Service (`web3_service.dart`)

Maneja toda la interacción con wallets blockchain:

#### Funcionalidades:

- ✅ **Conectar Wallet**: WalletConnect, Metamask, Phantom
- ✅ **Firmar Mensajes**: Autenticación criptográfica
- ✅ **Ver Saldo**: ETH/tokens en tiempo real
- ✅ **Enviar Transacciones**: Transferencias de activos
- ✅ **Verificar Estado**: Confirmaciones de transacciones


#### Uso Básico:

```dart
// Conectar wallet
final web3Service = Web3Service();
final connected = await web3Service.connectWallet();

// Obtener saldo
final balance = await web3Service.getBalance();
print('Saldo: ${balance?.getValueInUnit(EtherUnit.ether)} ETH');

// Firmar mensaje
final signature = await web3Service.signMessage('Hello Web3');

// Desconectar
await web3Service.disconnectWallet();

```

#### Redes Soportadas:

- Ethereum Mainnet (Chain ID: 1)
- Ethereum Goerli Testnet (Chain ID: 5)
- Polygon Mainnet (Chain ID: 137)
- Polygon Mumbai Testnet (Chain ID: 80001)


### 2. GrpcClient (`grpc_client.dart`)

Conexión rápida con el backend Rust (puerto 50051):

#### Funcionalidades:

- ✅ **Health Check**: Verificar conectividad
- ✅ **Chat Stream**: Mensajes en tiempo real
- ✅ **Obtener Saldo**: Balance de usuario
- ✅ **Verificar Transacciones**: Estado de operaciones


#### Uso Básico:

```dart
// Conectar a gRPC
final grpcClient = GrpcClient();
await grpcClient.connect();

// Enviar mensaje de chat
await grpcClient.sendChatMessage(
  userId: 'user123',
  message: 'Hola!',
  channelId: 'general',
);

// Stream de mensajes
grpcClient.getChatStream('general').listen((message) {
  print('Nuevo mensaje: ${message.text}');
});

// Desconectar
await grpcClient.disconnect();

```

## 🏠 HomeScreen - Pantalla Principal

La pantalla principal tiene **3 tabs**:

### Tab 1: 🌐 Web3

- **Estado de Wallet**: Conectado/Desconectado
- **Dirección**: Muestra address corto
- **Botones**:
  - Conectar/Desconectar Wallet
  - Ver Saldo ETH
  - Firmar Mensaje
- **Info de Red**: Chain ID y nombre de red


### Tab 2: 💬 Chat

- **Estado gRPC**: Conectado/Desconectado a backend
- **Chat UI**: Interfaz completa con:
  - Burbujas de mensaje
  - Input de texto
  - Timestamps
  - Avatares de usuario


### Tab 3: ⚙️ Config

- Estado del servidor gRPC (localhost:50051)
- Info del ledger blockchain
- Versión de la app


## 🔌 Configuración Inicial

### 1. Providers en main.dart

```dart
import 'package:provider/provider.dart';
import 'services/services.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Web3Service()),
        ChangeNotifierProvider(create: (_) => GrpcClient()),
        // ... otros providers
      ],
      child: MyApp(),
    ),
  );
}

```

### 2. Configurar Claves API

#### Web3 (Infura/Alchemy)

En `web3_service.dart`:

```dart
final String _rpcUrl = 'https://mainnet.infura.io/v3/YOUR_INFURA_KEY';
final String _walletConnectProjectId = 'YOUR_WALLETCONNECT_PROJECT_ID';

```

#### gRPC Backend

En `grpc_client.dart`:

```dart
final String _host = 'localhost'; // O tu IP/dominio
final int _port = 50051;

```

## 📦 Instalación de Dependencias

```bash
cd mobile_app
flutter pub get

```

## 🧪 Testing

```bash

# Verificar análisis

flutter analyze

# Ejecutar en emulador

flutter run

# Build para Android

flutter build apk

# Build para iOS

flutter build ios

```

## 🔐 Seguridad

### Web3:

- ✅ Nunca almacenar private keys en la app
- ✅ Usar WalletConnect para conexiones seguras
- ✅ Validar todas las transacciones antes de firmar


### gRPC:

- ✅ Usar TLS en producción
- ✅ Autenticar requests con tokens
- ✅ Validar datos del servidor


## 🚀 Próximos Pasos

### Pendientes:

1. **Proto Files**: Definir contratos gRPC (.proto)
2. **Code Gen**: Generar clientes Dart desde proto
3. **TLS**: Configurar certificados para gRPC seguro
4. **Push Notifications**: Chat en tiempo real
5. **Offline Support**: Cache de mensajes y estados


### Mejoras Futuras:

- [ ] Soporte para Solana (Phantom wallet)
- [ ] NFT Gallery y marketplace
- [ ] ENS (Ethereum Name Service) support
- [ ] Multi-wallet management
- [ ] Transaction history con filtros
- [ ] Chat grupal y canales
- [ ] Encriptación E2E para chat
- [ ] Voice messages en chat


## 📖 Recursos

- [Web3Dart Docs](https://pub.dev/packages/web3dart)
- [WalletConnect Docs](https://docs.walletconnect.com/)
- [gRPC Flutter](https://grpc.io/docs/languages/dart/)
- [Flutter Chat UI](https://pub.dev/packages/flutter_chat_ui)
---
**Última actualización:** Diciembre 7, 2025
**Autor:** Desarrollador Flutter Senior
**Estado:** ✅ Configurado y listo para desarrollo
