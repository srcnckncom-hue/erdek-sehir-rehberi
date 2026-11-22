import 'package:erdek_rehberi/core/time/calendar_date.dart';
import 'package:erdek_rehberi/features/businesses/domain/business.dart';
import 'package:erdek_rehberi/features/explore/domain/explore.dart';
import 'package:erdek_rehberi/features/map/map_screen.dart';
import 'package:erdek_rehberi/features/nearby/location_service.dart';
import 'package:erdek_rehberi/features/nearby/nearby_screen.dart';
import 'package:erdek_rehberi/features/nearby/points.dart';
import 'package:erdek_rehberi/features/pharmacy/domain/pharmacy.dart';
import 'package:erdek_rehberi/features/sea/sea.dart';
import 'package:erdek_rehberi/features/weather/domain/weather.dart';
import 'package:erdek_rehberi/features/weather/presentation/weather_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  group('Mesafe', () {
    test('haversine: Erdek merkez → Avşa ≈ 27 km', () {
      const avsa = GeoPoint(40.5106, 27.5047);
      final km = erdekCenter.distanceTo(avsa) / 1000;
      expect(km, closeTo(27, 3));
      expect(erdekCenter.distanceTo(erdekCenter), 0);
    });

    test('biçim', () {
      expect(formatDistance(347), '350 m');
      expect(formatDistance(1234), '1,2 km');
      expect(formatDistance(15600), '16 km');
    });
  });

  test('yerler: konumu olanlar yakından uzağa, olmayanlar sonda', () {
    final points = collectPoints(
      erdekNow: DateTime(2026, 11, 21, 18),
      pharmacyLabel: 'Nöbetçi',
      businesses: BusinessesData.fromJson({
        'categories': [
          {'id': 'k', 'title': 'Kafe'},
        ],
        'businesses': [
          {'id': 'uzak', 'name': 'Uzak', 'categoryId': 'k', 'latitude': 40.48, 'longitude': 27.80},
          {'id': 'yakin', 'name': 'Yakın', 'categoryId': 'k', 'latitude': 40.396, 'longitude': 27.794},
          {'id': 'konumsuz', 'name': 'Konumsuz', 'categoryId': 'k'},
        ],
      }),
      places: const PlacesData(places: []),
      pharmacy: const PharmacyData(pharmacies: [], duties: []),
    );
    final sorted = sortByDistance(points, erdekCenter);
    expect(sorted.map((e) => e.$1.title), ['Yakın', 'Uzak', 'Konumsuz']);
    expect(sorted.last.$2, isNull);
    expect(points.first.subtitle, 'Kafe');
    expect(points.first.toPin()['kind'], 'business');
  });

  test('deniz verisi: sıralı, bugünden itibaren, deniz durumu', () {
    final sea = SeaData.fromJson({
      'location': 'Erdek Körfezi',
      'days': [
        {'date': '2026-11-23', 'waterTempC': 15.9, 'waveMaxM': 1.6},
        {'date': '2026-11-21', 'waterTempC': 16.4, 'waveHeightM': 0.3, 'waveMaxM': 0.4},
        {'date': '2026-11-22', 'waveHeightM': 0.8},
      ],
    });
    final days = sea.from(const CalendarDate(2026, 11, 22));
    expect(days.map((d) => d.date.day), [22, 23]);
    expect(sea.days.first.seaState, 0);
    expect(days.first.seaState, 1);
    expect(days.last.seaState, 2);
    expect(days.first.waterTempC, isNull);
  });

  testWidgets('hava durumu sayfasında deniz bölümü', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 5000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const WeatherScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deniz'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sea_section')), findsOneWidget);
    expect(find.text('Deniz suyu 16°'), findsOneWidget);
    expect(find.textContaining('Copernicus'), findsOneWidget);
  });

  testWidgets('rüzgâr sekmesi: hız, yön, Beaufort', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 5000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const WeatherScreen(initialTab: WeatherTab.wind)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wind_section')), findsOneWidget);
    expect(find.text('Kuzeydoğu (Poyraz) yönünden'), findsOneWidget);
    expect(find.textContaining('bofor'), findsOneWidget);
  });

  test('Beaufort ve yön dilimleri', () {
    expect(beaufort(0.1), 0);
    expect(beaufort(5.0), 3);
    expect(beaufort(40), 12);
    expect(windSector8(0), 0);
    expect(windSector8(350), 0);
    expect(windSector8(45), 1);
    expect(windSector8(225), 5);
  });

  testWidgets('harita: iOS dışında liste, süzgeç çalışır', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 3000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const MapScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('map_fallback')), findsOneWidget);
    expect(find.text('Test Oteli'), findsOneWidget); // konumu olan tek işletme
    expect(find.text('Test Lokantası'), findsNothing); // konumu yok → haritada yok
  });

  testWidgets('yakınımdakiler: konum alınamazsa açıklama ve tekrar dene', (tester) async {
    await tester.pumpWidget(testApp(const NearbyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Konum alınamadı'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
  });
}
