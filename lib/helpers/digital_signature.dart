import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart' as pc;
import 'package:crypto/crypto.dart';
import 'package:trace_foodchain_app/main.dart';


class DigitalSignature {
   /// Create digital signature with private key and UUID
  Future<String> generateSignature(String payload) async {
    final keyBytes = await keyManager.getPrivateKey();
    if (keyBytes == null) throw Exception('Private key not found');

    final message = payload;

    // Generate SHA-256 hash of the message
    final messageHash = sha256.convert(utf8.encode(message)).bytes;

    // Convert key bytes to PEM format
    final keyString = String.fromCharCodes(keyBytes);

    // Parse both private keys
    final privateKey = _parsePrivateKey(keyString);

    // Generate signature with private key and hash
    final signature1 = _signWithRSA(privateKey, messageHash);

    // Signature (Base64-encoded)
    final signature = base64.encode(signature1);

    return signature;
  }

  /// Convert private key to RSA format
  pc.RSAPrivateKey _parsePrivateKey(String privateKeyPem) {
    final parser = encrypt.RSAKeyParser();
    return parser.parse(privateKeyPem) as pc.RSAPrivateKey;
  }

  /// RSA signature with SHA-256
  List<int> _signWithRSA(pc.RSAPrivateKey privateKey, List<int> messageHash) {
    final signer = pc.Signer("SHA-256/RSA");
    final privParams = pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey);
    signer.init(true, privParams);
    return (signer.generateSignature(Uint8List.fromList(messageHash)) as pc.RSASignature).bytes;
  }
}
