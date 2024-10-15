// web_utils.dart
// import 'dart:html' as html;
import 'package:crypto/crypto.dart';
import 'dart:convert';

String generateBrowserFingerprint() {
  final data = {
    "test": "text"
    // 'userAgent': html.window.navigator.userAgent,
    // 'language': html.window.navigator.language,
    // 'colorDepth': html.window.screen?.colorDepth,
    // 'deviceMemory': html.window.navigator.deviceMemory,
    // 'hardwareConcurrency': html.window.navigator.hardwareConcurrency,
    // 'screenResolution':
    //     '${html.window.screen?.width}x${html.window.screen?.height}',
    // 'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,
    // 'sessionStorage': html.window.sessionStorage,
    // 'localStorage': html.window.localStorage,
    // 'indexedDb': html.window.indexedDB != null,
    // 'cpuClass': html.window.navigator.hardwareConcurrency,
    // 'platform': html.window.navigator.platform,
  };

  final jsonData = jsonEncode(data);
  final bytes = utf8.encode(jsonData);
  return sha256.convert(bytes).toString();
}
