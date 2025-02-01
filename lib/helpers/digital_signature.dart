import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart' as pc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:trace_foodchain_app/main.dart';


class DigitalSignature {
  final _storage = const FlutterSecureStorage();

  /// Digitale Signatur mit private key und UUID erstellen
  Future<String> generateSignature(String payload) async {
    final keyBytes = await keyManager.getPrivateKey();
    if (keyBytes == null) throw Exception('Private key not found');

    final message = payload;

    // SHA-256 Hash der Nachricht erzeugen
    final messageHash = sha256.convert(utf8.encode(message)).bytes;

    // Convert key bytes to PEM format
    final keyString = String.fromCharCodes(keyBytes);

    // Beide Private Keys parsen
    final privateKey = _parsePrivateKey(keyString);

    // Signatur mit beiden Private Keys
    final signature1 = _signWithRSA(privateKey, messageHash);

    // Kombinierte Signatur (Base64-kodiert)
    final signature = base64.encode(signature1);

    return signature;
  }

  /// Private Key in RSA Format umwandeln
  pc.RSAPrivateKey _parsePrivateKey(String privateKeyPem) {
    final parser = encrypt.RSAKeyParser();
    return parser.parse(privateKeyPem) as pc.RSAPrivateKey;
  }

  /// RSA Signatur mit SHA-256
  List<int> _signWithRSA(pc.RSAPrivateKey privateKey, List<int> messageHash) {
    final signer = pc.Signer("SHA-256/RSA");
    final privParams = pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey);
    signer.init(true, privParams);
    return (signer.generateSignature(Uint8List.fromList(messageHash)) as pc.RSASignature).bytes;
  }
}
