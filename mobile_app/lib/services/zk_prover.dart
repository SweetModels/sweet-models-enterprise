import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// ZK Schnorr Prover (cliente) usando secp256k1
class ZkProver {
  /// Deriva llave privada determinística desde contraseña (no se guarda)
  BigInt derivePrivateKey(String password) {
    final digest = SHA256Digest().process(utf8.encode(password) as Uint8List);
    return decodeBigInt(digest) % ECCurve_secp256k1().n;
  }

  /// Registra el compromiso público Y = g^x
  ECPoint publicCommitment(String password) {
    final curve = ECCurve_secp256k1();
    final g = curve.G!;
    final x = derivePrivateKey(password);
    return g * x as ECPoint;
  }

  /// Genera la prueba (R, s) para un desafío c (hex string)
  ({ECPoint R, BigInt s}) prove(String password, String challengeHex) {
    final curve = ECCurve_secp256k1();
    final g = curve.G!;
    final n = curve.n;
    final rnd = Random.secure();
    final k = BigInt.from(rnd.nextInt(1 << 31)) % n; // simple randomness
    final R = g * k as ECPoint;
    final c = decodeBigInt(hexToBytes(challengeHex)) % n;
    final x = derivePrivateKey(password);
    final s = (k + c * x) % n;
    return (R: R, s: s);
  }

  /// Serializa ECPoint comprimido (33 bytes) a hex
  String pointToHex(ECPoint p) {
    return bytesToHex(p.getEncoded(true));
  }

  String scalarToHex(BigInt s) => bytesToHex(encodeBigIntAsUnsigned(s));
}

Uint8List hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < hex.length; i += 2) {
    result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }
  return result;
}

String bytesToHex(Uint8List bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

BigInt decodeBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}

Uint8List encodeBigIntAsUnsigned(BigInt number) {
  var _number = number;
  final result = <int>[];
  while (_number > BigInt.zero) {
    result.insert(0, (_number & BigInt.from(0xff)).toInt());
    _number = _number >> 8;
  }
  return Uint8List.fromList(result);
}
