import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:trace_foodchain_app/main.dart';

class KeyManager {
  final _storage = const FlutterSecureStorage();

  Future<bool> generateAndStoreKeys() async {
    try {
      debugPrint("Generating new Ed25519 keypair...");
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final privateKey = await keyPair.extractPrivateKeyBytes();

      debugPrint("Generated new keypair");
      debugPrint("Sending public key to server...");
      
      // Public Key an Server senden und auf Erfolg prüfen
      final success = await cloudSyncService.apiClient.sendPublicKeyToFirebase(publicKey.bytes);
      
      if (success) {
        debugPrint("Public key successfully stored in cloud, now storing private key securely...");
        // Nur wenn Cloud-Speicherung erfolgreich war, privaten Schlüssel lokal speichern
        await savePrivateKey(privateKey);
        debugPrint("Key initialization complete");
        return true;
      } else {
        debugPrint("Failed to store public key in cloud - aborting key storage");
        return false;
      }
    } catch (e) {
      debugPrint("Error during key generation/storage: $e");
      return false;
    }
  }

  /// Speichert den privaten Schlüssel sicher im Secure Storage
  Future<void> savePrivateKey(List<int> privateKeyBytes) async {
    final encodedKey = base64Encode(privateKeyBytes);
    await _storage.write(key: 'private_key', value: encodedKey);
    debugPrint("Private key stored securely!");
    print("Privater Schlüssel sicher gespeichert!");
  }

  /// Ruft den privaten Schlüssel sicher aus dem Secure Storage ab
  Future<List<int>?> getPrivateKey() async {
    final encodedKey = await _storage.read(key: 'private_key');
    if (encodedKey == null) {
      print("Kein gespeicherter Schlüssel gefunden!");
      return null;
    }
    return base64Decode(encodedKey);
  }
}


