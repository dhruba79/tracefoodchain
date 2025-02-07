import 'dart:html' as html;
import 'package:uuid/uuid.dart';

Future<String> getDeviceId() async {
  final storage = html.window.localStorage;
  var id = storage['deviceId'];
  if (id == null) {
    id = const Uuid().v4();
    storage['deviceId'] = id;
  }
  return id;
}
