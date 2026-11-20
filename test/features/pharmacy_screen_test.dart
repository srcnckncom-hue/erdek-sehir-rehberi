import 'package:erdek_rehberi/features/pharmacy/presentation/pharmacy_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, DateTime now) async {
    tester.view
      ..physicalSize = const Size(1170, 4500)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const PharmacyScreen(), now: now));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets('18:05 → bugünün nöbetçisi ve önümüzdeki günler', (tester) async {
    await pumpScreen(tester, DateTime(2026, 11, 21, 18, 5));

    expect(find.text('21 Kasım 08:30 – 22 Kasım 08:30'), findsOneWidget);
    // Kartta + 25 Kasım satırında (örnek veride 4'lü sıra)
    expect(find.text('ÖRNEK Eczane 1'), findsNWidgets(2));
    expect(find.text('Pazar, 22 Kasım'), findsOneWidget);
    expect(find.text('Gitmeden önce telefonla teyit edin.'), findsOneWidget);
    expect(find.text('Ara'), findsOneWidget);
    expect(find.text('Yol tarifi'), findsOneWidget);
  });

  testWidgets('gece 03:00 → bir önceki günün nöbetçisi', (tester) async {
    await pumpScreen(tester, DateTime(2026, 11, 22, 3));

    expect(find.text('21 Kasım 08:30 – 22 Kasım 08:30'), findsOneWidget);
    expect(find.text('ÖRNEK Eczane 1'), findsNWidgets(2));
  });

  testWidgets('kayıt olmayan gün → boş durum ve 112', (tester) async {
    await pumpScreen(tester, DateTime(2027, 6, 1, 12));

    expect(find.text('Bugün için nöbet kaydı yok'), findsOneWidget);
    expect(find.text("112'yi ara"), findsOneWidget);
  });
}
