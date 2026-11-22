import 'package:erdek_rehberi/features/trips/trips.dart';
import 'package:erdek_rehberi/features/trips/trips_screen.dart';
import 'package:erdek_rehberi/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

final _trip = TripRoute.fromJson({
  'id': 'r',
  'title': 'R',
  'type': 'yuruyus',
  'summary': 's',
  'difficulty': 'orta',
  'distanceKm': 6.5,
  'durationMin': 150,
  'stops': [
    {'name': 'A', 'latitude': 40.1, 'longitude': 27.1},
    {'name': 'B'},
    {'name': 'C', 'latitude': 40.2, 'longitude': 27.2},
    {'name': 'D', 'latitude': 40.3, 'longitude': 27.3},
  ],
  'path': [
    [40.1, 27.1],
    [40.15, 27.15],
    'bozuk',
  ],
});

void main() {
  test('duraklar, çizgi ve yol tarifi bağlantısı', () {
    expect(_trip.stopPoints, hasLength(3));
    expect(_trip.path, hasLength(2));
    expect(_trip.line, _trip.path);
    final url = Uri.parse(_trip.directionsUrl()!);
    expect(url.queryParameters['origin'], '40.10000,27.10000');
    expect(url.queryParameters['destination'], '40.30000,27.30000');
    expect(url.queryParameters['waypoints'], '40.20000,27.20000');
    expect(url.queryParameters['travelmode'], 'walking');
    expect(TripRoute.fromJson({'id': 'x', 'title': 'X', 'type': 'tekne', 'summary': 's'}).directionsUrl(), isNull);
  });

  test('özet metni', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    expect(TripStyle.stats(l10n, _trip), '6,5 km · 2 sa 30 dk · Orta');
  });

  testWidgets('rotalar sayfası → ayrıntı: duraklar, ipuçları', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 5000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const TripsScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trips_filter')), findsOneWidget);
    expect(find.text('Ada Turu'), findsOneWidget);

    await tester.tap(find.byKey(const Key('trip_kyzikos')));
    await tester.pumpAndSettle();
    expect(find.byType(TripDetailScreen), findsOneWidget);
    expect(find.text('Duraklar (3)'), findsOneWidget);
    expect(find.text('Hadrian Tapınağı'), findsOneWidget);
    expect(find.byKey(const Key('trip_directions')), findsOneWidget);
    expect(find.text('Su alın.'), findsOneWidget);
  });
}
