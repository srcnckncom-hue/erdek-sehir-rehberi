import 'package:erdek_rehberi/features/explore/presentation/history_screen.dart';
import 'package:erdek_rehberi/features/explore/presentation/places_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view
      ..physicalSize = const Size(1170, 6000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(screen));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets('gezilecek yerler: liste, bölge ve tür filtresi', (tester) async {
    await pump(tester, const PlacesScreen());

    expect(find.text('Gezilecek Yerler'), findsOneWidget);
    for (final letter in ['A', 'B', 'C', 'D', 'E', 'F']) {
      expect(find.text('ÖRNEK Yer $letter'), findsOneWidget);
    }

    await tester.tap(find.text('Kapıdağ'));
    await tester.pumpAndSettle();
    expect(find.text('ÖRNEK Yer A'), findsNothing);
    expect(find.text('ÖRNEK Yer D'), findsOneWidget);

    await tester.tap(find.text('Plaj'));
    await tester.pumpAndSettle();
    expect(find.text('ÖRNEK Yer F'), findsOneWidget);
    expect(find.text('ÖRNEK Yer D'), findsNothing);
  });

  testWidgets('yer kartı ayrıntı sayfasını açar', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, const PlacesScreen());

    await tester.tap(find.text('ÖRNEK Yer A'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ÖRNEK paragraf 1: Yer A'), findsOneWidget);
    expect(find.text('Bilmeniz gerekenler'), findsOneWidget);
    expect(find.text('Fotoğraf yakında eklenecek'), findsOneWidget);
    // Koordinat/adres yok → yol tarifi düğmesi gösterilmez
    expect(find.text('Yol tarifi'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('ÖRNEK Yer B'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('erdek tarihi: giriş ve dönemler', (tester) async {
    await pump(tester, const HistoryScreen());

    expect(find.text('Erdek Tarihi'), findsOneWidget);
    expect(find.textContaining('ÖRNEK giriş'), findsOneWidget);
    for (var n = 1; n <= 4; n++) {
      expect(find.text('ÖRNEK Dönem $n'), findsOneWidget);
    }
  });
}
