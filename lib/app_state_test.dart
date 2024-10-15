import 'package:flutter_test/flutter_test.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';

void main() {
  group('AppState', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('initial state', () {
      expect(appState.userRole, isNull);
      expect(appState.userId, isNull);
      expect(appState.isConnected, isFalse);
    });

    test('setUserRole updates userRole', () {
      appState.setUserRole('Farmer');
      expect(appState.userRole, 'Farmer');
    });

    test('setUserId updates userId', () {
      appState.setUserId("1");
      expect(appState.userId, "1");
    });

    test('setConnected updates isConnected', () {
      appState.setConnected(true);
      expect(appState.isConnected, isTrue);
    });
  });
}
