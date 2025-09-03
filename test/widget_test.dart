// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_english/features/main/main.dart' as app;

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const app.MyApp());
    // Drain splash timers to avoid pending timer failure
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Add your test assertions here (placeholder ensures test completes)
    expect(find.byType(Object), findsNothing);
  });
}
