import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:trace_foodchain_app/main.dart';

class DigitalSignature {
  /// Erzeugt eine digitale Signatur mit Ed25519
  Future<String> generateSignature(String payload) async {
    final keyBytes = await keyManager.getPrivateKey();
    if (keyBytes == null) throw Exception('Privater Schlüssel nicht gefunden');

    // Signiere das Payload direkt mit Ed25519
    final algorithm = Ed25519();
    // Erstelle ein KeyPair aus dem vorhandenen Seed (privater Schlüssel)
    final keyPair = await algorithm.newKeyPairFromSeed(Uint8List.fromList(keyBytes));
    final signature = await algorithm.sign(
      utf8.encode(payload),
      keyPair: keyPair,
    );
    return base64.encode(signature.bytes);
  }
}
