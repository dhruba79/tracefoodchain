import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:trace_foodchain_app/main.dart';

class DigitalSignature {
  /// Creates a new signature for the given payload
  Future<String> generateSignature(String payload) async {
    // Sign payload with Ed25519
    final algorithm = Ed25519();
    // Get the keypair from the private key by using it as a seed
    final keyPair = await _getKeyPair();

    final payloadBytes = utf8.encode(payload);

    final signature = await algorithm.sign(
      payloadBytes,
      keyPair: keyPair,
    );
    return base64.encode(signature.bytes);
  }

  /// Returns the public key as a base64 encoded string
  Future<String> getPublicKey() async {
    final keyPair = await _getKeyPair();

    return base64.encode((await keyPair.extractPublicKey()).bytes);
  }

  Future<SimpleKeyPair> _getKeyPair() async {
    final keyBytes = await keyManager.getPrivateKey();
    if (keyBytes == null) throw Exception('Privater Schlüssel nicht gefunden');

    final algorithm = Ed25519();

    final keyPair = await algorithm.newKeyPairFromSeed(Uint8List.fromList(keyBytes));

    return keyPair;
  }
}
