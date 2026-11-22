import 'package:erdek_rehberi/features/beaches/beaches_screen.dart';
import 'package:erdek_rehberi/features/beaches/swim_score.dart';
import 'package:erdek_rehberi/features/explore/domain/explore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  group('Yüzme puanı', () {
    test('ideal yaz günü: 100, harika', () {
      final s = swimScoreFor(airC: 30, waterC: 25, waveM: 0.2, windMs: 3);
      expect(s.score, 100);
      expect(s.level, SwimLevel.great);
      expect(s.factors.every((f) => f.status == SwimFactorStatus.ok), isTrue);
    });

    test('serin su ve dalga: idare eder; etkenler uyarı/kötü', () {
      final s = swimScoreFor(airC: 26, waterC: 21, waveM: 0.7, windMs: 6);
      expect(s.score, 100 - 15 - 5 - 20 - 10);
      expect(s.level, SwimLevel.fair);
      final wave = s.factors.firstWhere((f) => f.kind == SwimFactorKind.wave);
      expect(wave.status, SwimFactorStatus.warn);
    });

    test('kış / fırtına: 0, uygun değil', () {
      final s = swimScoreFor(airC: 12, waterC: 14, waveM: 2, windMs: 14, thunder: true);
      expect(s.score, 0);
      expect(s.level, SwimLevel.poor);
      expect(s.factors.map((f) => f.kind), contains(SwimFactorKind.storm));
    });

    test('deniz verisi yoksa yalnızca hava/rüzgâr', () {
      final s = swimScoreFor(airC: 29, windMs: 4);
      expect(s.waterKnown, isFalse);
      expect(s.score, 100);
      expect(s.factors.map((f) => f.kind), [SwimFactorKind.air, SwimFactorKind.wind]);
    });
  });

  test('plaj olanakları: bilinmeyen kod atlanır', () {
    final p = Place.fromJson({
      'id': 'x',
      'title': 'X',
      'area': 'erdek',
      'category': 'plaj',
      'summary': 's',
      'paragraphs': ['p'],
      'amenities': ['mavi_bayrak', 'yok', 'otopark'],
    });
    expect(p.amenities, [BeachAmenity.blueFlag, BeachAmenity.parking]);
  });

  testWidgets('plajlar sayfası: puan kartı, yalnızca plajlar, süzgeç', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 5000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const BeachesScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('swim_score')), findsOneWidget);
    expect(find.text('Bugün uygun değil'), findsOneWidget); // kasım: su 16°, hava 19°
    expect(find.text('Su 16°'), findsOneWidget);
    expect(find.text('ÖRNEK Yer A'), findsOneWidget);
    expect(find.text('ÖRNEK Yer F'), findsOneWidget);
    expect(find.text('ÖRNEK Yer B'), findsNothing); // tarihi yer

    await tester.tap(find.text('Mavi Bayrak').first);
    await tester.pumpAndSettle();
    expect(find.text('ÖRNEK Yer A'), findsOneWidget);
    expect(find.text('ÖRNEK Yer F'), findsNothing);
  });
}
