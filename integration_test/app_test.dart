import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trace_foodchain_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('tap on the floating action button, verify counter',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify the initial state
      expect(find.text('Harvests'), findsOneWidget);

      // Tap the add button and trigger a frame
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify that the add harvest dialog appears
      expect(find.text('Add Harvest'), findsOneWidget);

      // TODO: Add more specific tests for adding a harvest and verifying it appears in the list
    });
  });
}
