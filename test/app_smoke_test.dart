import 'package:erdek_rehberi/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_overrides.dart';

void main() {
  testWidgets('Uygulama açılır, ana sayfa veriyle dolar', (tester) async {
    await tester.pumpWidget(testScope(child: const ErdekApp()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Hızlı İşlemlerim'), findsOneWidget);
    expect(find.text('Şehir Hizmetleri'), findsOneWidget);
    // 21.11 nöbet kaydı örnek veride: ÖRNEK Eczane 1 — "Erdek'te bugün" kartı + nöbetçi eczane kartı
    expect(find.textContaining('ÖRNEK Eczane'), findsNWidgets(2));
    // 18:05 → sıradaki vakit Yatsı 19:00
    expect(find.text('Yatsı'), findsOneWidget);
    expect(find.text('55 dk kaldı'), findsOneWidget);
  });
}
