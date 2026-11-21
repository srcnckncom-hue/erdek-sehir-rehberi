import 'package:erdek_rehberi/features/transport/presentation/transport_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  // Sabit veri (test/fixtures): feribot 09:00 her gün + 16:00 Pzt–Cmt;
  // otobüs 07:00–20:00 saat başı Pzt–Cmt. Şu an: 21.11.2026 Cumartesi 18:05.
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1170, 6000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const TransportScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets('feribot: bugünkü seferler geçmiş, sıradaki yarın 09:00', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Ulaşım'), findsOneWidget);
    expect(find.text('Erdek – Avşa'), findsOneWidget);
    expect(find.text('Yarın · 09:00'), findsOneWidget);
    expect(find.textContaining('14 sa 55 dk kaldı'), findsOneWidget);
    expect(find.text('Pzt 23'), findsOneWidget);
    expect(find.text('Sıradaki'), findsNothing); // bugün seçili, sıradaki yarın
  });

  testWidgets('otobüse geçiş: sıradaki bugün 19:00 ve vurgulu', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Otobüs'));
    await tester.pumpAndSettle();

    expect(find.text('Erdek – Bandırma'), findsOneWidget);
    expect(find.text('Bugün · 19:00'), findsOneWidget);
    expect(find.textContaining('55 dk kaldı'), findsOneWidget);
    expect(find.text('Sıradaki'), findsOneWidget);
  });

  testWidgets('yarın seçilince yarının seferleri, sıradaki vurgulu', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Yarın'));
    await tester.pumpAndSettle();

    // Pazar: yalnızca 09:00 (16:00 Pzt–Cmt)
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('16:00'), findsNothing);
    expect(find.text('Sıradaki'), findsOneWidget);
  });
}
