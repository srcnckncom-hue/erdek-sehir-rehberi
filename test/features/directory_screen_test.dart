import 'package:erdek_rehberi/features/contacts/presentation/directory_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1170, 6000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const DirectoryScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets('telefonlar: 112 kartı ve kategoriler', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Rehber'), findsOneWidget);
    expect(find.text('Acil Çağrı 112'), findsOneWidget);
    expect(find.text('Kamu Kurumları'), findsOneWidget);
    expect(find.text('Erdek Belediyesi'), findsOneWidget);
    // 112 listede tekrar edilmez (yalnızca kırmızı kartta)
    expect(find.text('Acil Çağrı (Ambulans, İtfaiye, Polis, Jandarma)'), findsNothing);
  });

  testWidgets('duyurular: hepsi yeni, kategori filtresi çalışır', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Duyurular'));
    await tester.pumpAndSettle();

    expect(find.text('ÖRNEK: Planlı su kesintisi'), findsOneWidget);
    expect(find.text('Yeni'), findsNWidgets(3));

    await tester.tap(find.text('Kesinti').first);
    await tester.pumpAndSettle();

    expect(find.text('ÖRNEK: Planlı su kesintisi'), findsOneWidget);
    expect(find.text('ÖRNEK: Pazar günleri'), findsNothing);
  });
}
