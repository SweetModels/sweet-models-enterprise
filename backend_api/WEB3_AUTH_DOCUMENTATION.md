# 🔐 Web3 Authentication - Sweet Models Enterprise

## 📋 Descripción

Sistema de autenticación descentralizada que permite a los usuarios iniciar sesión usando sus wallets de criptomonedas sin necesidad de contraseñas tradicionales.

## 🌐 Blockchains Soportadas

- ✅ **Ethereum** (Mainnet, Goerli, Sepolia)
- ✅ **Polygon** (Mainnet, Mumbai)
- ✅ **Binance Smart Chain** (BSC)
- ✅ **Solana** (Mainnet, Devnet)

## 🔄 Flujo de Autenticación

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant Backend
    participant Redis
    participant DB
    
    User->>Frontend: Click "Connect Wallet"
    Frontend->>User: Request wallet connection
    User->>Frontend: Approve wallet
    Frontend->>Backend: GET /auth/web3/nonce/{address}
    Backend->>Redis: Generate & store nonce
    Redis-->>Backend: Nonce stored
    Backend-->>Frontend: Return nonce + message
    Frontend->>User: Request signature
    User->>Frontend: Sign message
    Frontend->>Backend: POST /auth/web3/verify {address, signature}
    Backend->>Redis: Retrieve nonce
    Backend->>Backend: Verify signature
    Backend->>DB: Get or create user
    Backend->>Backend: Generate JWT tokens
    Backend-->>Frontend: Return tokens + user_id
    Frontend->>User: Authenticated ✅
```

## 📡 API Endpoints

### 1. Generar Nonce

```http
GET /auth/web3/nonce/{wallet_address}
```

**Ejemplo de Respuesta:**

```json
{
  "nonce": "a3f5e9d2c8b1...",
  "message": "Sign this message to authenticate with Sweet Models Enterprise.\n\nNonce: a3f5e9d2c8b1...\nTimestamp: 1702345678",
  "expires_in": 300
}
```

### 2. Verificar Firma

```http
POST /auth/web3/verify
Content-Type: application/json
```

**Request Body:**

```json
{
  "wallet_address": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
  "signature": "0x1234567890abcdef...",
  "blockchain": "ethereum",
  "chain_id": 1
}
```

**Response:**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "wallet_address": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
  "is_new_user": false
}
```

### 3. Refrescar Token

```http
POST /auth/web3/refresh
Content-Type: application/json
```

**Request Body:**

```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 4. Desconectar Wallet

```http
POST /auth/web3/disconnect
Content-Type: application/json
```

**Request Body:**

```json
{
  "wallet_address": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
}
```

## 💻 Ejemplos de Código Frontend

### JavaScript/TypeScript (Ethers.js)

```typescript
import { ethers } from 'ethers';

async function authenticateWithWallet() {
  // 1. Connect wallet
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  const address = await signer.getAddress();
  
  // 2. Get nonce from backend
  const nonceResponse = await fetch(`https://api.sweetmodels.com/auth/web3/nonce/${address}`);
  const { nonce, message } = await nonceResponse.json();
  
  // 3. Sign message
  const signature = await signer.signMessage(message);
  
  // 4. Verify signature with backend
  const verifyResponse = await fetch('https://api.sweetmodels.com/auth/web3/verify', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      wallet_address: address,
      signature: signature,
      blockchain: 'ethereum',
      chain_id: await provider.getNetwork().then(n => n.chainId)
    })
  });
  
  const { access_token, user_id } = await verifyResponse.json();
  
  // 5. Store token
  localStorage.setItem('access_token', access_token);
  localStorage.setItem('user_id', user_id);
  
  console.log('✅ Authenticated with wallet:', address);
}
```

### Solana (web3.js)

```typescript
import { Connection, PublicKey } from '@solana/web3.js';
import bs58 from 'bs58';

async function authenticateWithSolanaWallet() {
  // 1. Connect Phantom wallet
  const { solana } = window as any;
  await solana.connect();
  const publicKey = solana.publicKey.toString();
  
  // 2. Get nonce
  const nonceResponse = await fetch(`https://api.sweetmodels.com/auth/web3/nonce/${publicKey}`);
  const { nonce, message } = await nonceResponse.json();
  
  // 3. Sign message
  const encodedMessage = new TextEncoder().encode(message);
  const { signature } = await solana.signMessage(encodedMessage, 'utf8');
  const signatureBase58 = bs58.encode(signature);
  
  // 4. Verify
  const verifyResponse = await fetch('https://api.sweetmodels.com/auth/web3/verify', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      wallet_address: publicKey,
      signature: signatureBase58,
      blockchain: 'solana'
    })
  });
  
  const { access_token } = await verifyResponse.json();
  localStorage.setItem('access_token', access_token);
  
  console.log('✅ Authenticated with Solana wallet');
}
```

### Flutter/Dart

```dart
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> authenticateWithWallet(Credentials credentials) async {
  final address = await credentials.extractAddress();
  
  // 1. Get nonce
  final nonceResponse = await http.get(
    Uri.parse('https://api.sweetmodels.com/auth/web3/nonce/${address.hex}'),
  );
  final nonceData = json.decode(nonceResponse.body);
  final message = nonceData['message'];
  
  // 2. Sign message
  final signature = await credentials.signPersonalMessage(
    Uint8List.fromList(utf8.encode(message)),
  );
  final signatureHex = '0x${bytesToHex(signature)}';
  
  // 3. Verify signature
  final verifyResponse = await http.post(
    Uri.parse('https://api.sweetmodels.com/auth/web3/verify'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'wallet_address': address.hex,
      'signature': signatureHex,
      'blockchain': 'ethereum',
    }),
  );
  
  final authData = json.decode(verifyResponse.body);
  final accessToken = authData['access_token'];
  
  // Store token
  await secureStorage.write(key: 'access_token', value: accessToken);
  
  print('✅ Authenticated!');
}
```

## 🔒 Seguridad

### Características de Seguridad

1. **Nonce de Un Solo Uso**
   - Cada nonce expira en 5 minutos
   - Se elimina después de usarse
   - Previene ataques de replay

2. **Verificación Criptográfica**
   - EVM: Recuperación de dirección desde firma ECDSA
   - Solana: Verificación Ed25519
   - Valida que la firma fue creada por el propietario de la wallet

3. **JWT Tokens**
   - Access token: 24 horas
   - Refresh token: 30 días
   - Firmados con secret configurable

4. **Audit Log**
   - Todas las autenticaciones se registran
   - Incluye: IP, User-Agent, timestamp
   - Permite revocar sesiones

### Variables de Entorno

```bash
# JWT Secret (CAMBIAR EN PRODUCCIÓN)
JWT_SECRET=your-super-secret-key-change-this-in-production

# Redis para nonces
REDIS_URL=redis://127.0.0.1:6379

# PostgreSQL para usuarios
DATABASE_URL=postgresql://user:pass@localhost/sweetmodels
```

## 📊 Base de Datos

### Tabla: users

```sql
-- Columnas Web3
wallet_address VARCHAR(255) UNIQUE
blockchain_type VARCHAR(50)  -- 'ethereum', 'solana', 'polygon', 'binance'
last_login_at TIMESTAMPTZ
```

### Tabla: web3_auth_logs

```sql
CREATE TABLE web3_auth_logs (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    wallet_address VARCHAR(255),
    blockchain_type VARCHAR(50),
    signature VARCHAR(512),
    nonce VARCHAR(64),
    ip_address INET,
    user_agent TEXT,
    authenticated_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    revoked BOOLEAN DEFAULT FALSE
);
```

## 🧪 Testing

### Probar con curl

```bash
# 1. Obtener nonce
WALLET="0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
curl "http://localhost:8080/auth/web3/nonce/$WALLET"

# 2. Firmar mensaje (en frontend con MetaMask)
# ...

# 3. Verificar firma
curl -X POST http://localhost:8080/auth/web3/verify \
  -H "Content-Type: application/json" \
  -d '{
    "wallet_address": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
    "signature": "0x...",
    "blockchain": "ethereum"
  }'
```

## 🚀 Despliegue

### Configuración en Producción

1. **Cambiar JWT_SECRET**:
   ```bash
   openssl rand -hex 32
   ```

2. **Configurar CORS**:
   ```rust
   let cors = CorsLayer::new()
       .allow_origin("https://app.sweetmodels.com".parse::<HeaderValue>().unwrap())
       .allow_methods([Method::GET, Method::POST])
       .allow_headers([AUTHORIZATION, CONTENT_TYPE]);
   ```

3. **Rate Limiting**:
   ```rust
   // Limitar generación de nonces: 5 por minuto por IP
   // Limitar verificaciones: 3 por minuto por wallet
   ```

## 📈 Monitoreo

### Métricas Clave

- Autenticaciones exitosas por blockchain
- Autenticaciones fallidas (firma inválida)
- Nonces expirados
- Sesiones activas por usuario
- Tiempo promedio de autenticación

### Consultas SQL Útiles

```sql
-- Usuarios por blockchain
SELECT blockchain_type, COUNT(*) 
FROM users 
WHERE wallet_address IS NOT NULL 
GROUP BY blockchain_type;

-- Sesiones activas
SELECT * FROM active_web3_sessions;

-- Autenticaciones en última hora
SELECT COUNT(*), blockchain_type 
FROM web3_auth_logs 
WHERE authenticated_at > NOW() - INTERVAL '1 hour' 
GROUP BY blockchain_type;
```

## 🐛 Solución de Problemas

### Error: "Invalid signature"

**Causa**: El mensaje firmado no coincide con el esperado

**Solución**:
- Verificar que el nonce no haya expirado (< 5 min)
- Asegurarse de firmar el mensaje exacto devuelto por `/nonce`
- Verificar que el timestamp sea reciente

### Error: "Nonce not found"

**Causa**: El nonce expiró o no existe

**Solución**:
- Solicitar un nuevo nonce
- Verificar que Redis esté funcionando
- Reducir el tiempo entre obtener nonce y verificar firma

### Error: "Invalid wallet address"

**Causa**: Formato de dirección incorrecto

**Solución**:
- Ethereum: Debe comenzar con `0x` + 40 caracteres hex
- Solana: 32-44 caracteres base58
- Verificar checksums (Ethereum EIP-55)

## 📚 Referencias

- [EIP-191: Signed Data Standard](https://eips.ethereum.org/EIPS/eip-191)
- [EIP-712: Typed Structured Data](https://eips.ethereum.org/EIPS/eip-712)
- [Solana Message Signing](https://docs.solana.com/developing/clients/javascript-api#signing-messages)
- [ethers.rs Documentation](https://docs.rs/ethers/latest/ethers/)

---

**🎯 Estado**: ✅ Production Ready  
**🔒 Seguridad**: Auditoría recomendada antes de mainnet  
**📅 Última actualización**: Diciembre 2025
