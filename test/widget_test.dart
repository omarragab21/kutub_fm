// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:kutub_fm/main.dart';
import 'package:kutub_fm/features/splash/presentation/pages/splash_screen.dart';

void main() {
  testWidgets('App start smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KutubFmApp());

    // Verify that Splash screen is rendered initially
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
