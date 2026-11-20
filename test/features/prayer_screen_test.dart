import 'package:erdek_rehberi/features/prayer/presentation/prayer_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  testWidgets('sıradaki vakit, bugünün vakitleri, bildirim ve imsakiye', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 7000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Sabit veri (test/fixtures): vakitler 06:00 · 07:30 · 12:30 · 15:00 · 17:30 · 19:00
    await tester.pumpWidget(testApp(const PrayerScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Namaz Vakitleri'), findsOneWidget);
    expect(find.text('Yatsı · 19:00'), findsOneWidget);
    expect(find.text('55 dk kaldı'), findsOneWidget);
    expect(find.text('Bugünün Vakitleri'), findsOneWidget);
    expect(find.text('Vakit bildirimleri'), findsOneWidget);
    expect(find.text('Kapalı'), findsOneWidget);
    expect(find.text('İmsakiye'), findsOneWidget);
    expect(find.text('Kasım 2026'), findsOneWidget);
    // İmsakiyede bugünün satırı
    expect(find.text('21 Cmt'), findsOneWidget);
  });
}
