import 'package:uuid/uuid.dart';

Future<String> getDeviceId() async {
  // Fallback-Implementierung, falls weder web noch mobile verfügbar ist
  return const Uuid().v4();
}
