import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutub_fm/features/audio_library/presentation/pages/audio_library_screen.dart';

void main() {
  Widget buildSubject() {
    return const MaterialApp(home: AudioLibraryScreen());
  }

  void useMobileViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('shows only favorites and bookmarks as primary tabs', (
    tester,
  ) async {
    useMobileViewport(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('المفضلة'), findsOneWidget);
    expect(find.text('الإشارات'), findsOneWidget);
    expect(find.text('التنزيلات'), findsNothing);
    expect(find.text('كتب'), findsOneWidget);
    expect(find.text('بودكاست'), findsOneWidget);
    expect(find.text('ريلز'), findsOneWidget);
  });

  testWidgets('switches between favorite content and bookmarks', (
    tester,
  ) async {
    useMobileViewport(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('بودكاست'));
    await tester.pumpAndSettle();
    expect(find.text('البرامج المفضلة'), findsOneWidget);

    await tester.tap(find.text('الإشارات'));
    await tester.pumpAndSettle();
    expect(find.text('الأمير الصغير'), findsOneWidget);
    expect(find.text('كتب'), findsNothing);
  });
}
