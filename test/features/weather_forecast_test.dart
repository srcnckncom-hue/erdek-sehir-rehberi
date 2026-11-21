import 'package:erdek_rehberi/features/weather/domain/weather.dart';
import 'package:erdek_rehberi/features/weather/presentation/weather_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

/// MET Norway compact biçiminde kayıt.
Map<String, dynamic> _entry(
  DateTime utc,
  double temp, {
  String symbol = 'cloudy',
  double rain1 = 0,
  double rain6 = 0,
  double wind = 2,
}) =>
    {
      'time': utc.toIso8601String(),
      'data': {
        'instant': {
          'details': {'air_temperature': temp, 'wind_speed': wind},
        },
        'next_1_hours': {
          'summary': {'symbol_code': symbol},
          'details': {'precipitation_amount': rain1},
        },
        'next_6_hours': {
          'summary': {'symbol_code': symbol},
          'details': {'precipitation_amount': rain6},
        },
      },
    };

void main() {
  test('günlere böler (Erdek saati), min/maks, yağış, öğlen simgesi', () {
    final series = <Map<String, dynamic>>[
      // 21.11 yerel 21:00 ve 22:00 (saatlik)
      _entry(DateTime.utc(2026, 11, 21, 18), 14, rain1: 0.5, rain6: 9),
      _entry(DateTime.utc(2026, 11, 21, 19), 13, rain1: 0.5, rain6: 9),
      // 22.11 yerel 03, 09, 15, 21 (6 saatlik)
      _entry(DateTime.utc(2026, 11, 22, 0), 10, symbol: 'clearsky_night', rain6: 1),
      _entry(DateTime.utc(2026, 11, 22, 6), 12, symbol: 'rain', rain6: 2, wind: 8),
      _entry(DateTime.utc(2026, 11, 22, 12), 18, symbol: 'partlycloudy_day', rain6: 0),
      _entry(DateTime.utc(2026, 11, 22, 18), 11, symbol: 'cloudy', rain6: 0.4),
      // 23.11 tek kayıt → atlanır
      _entry(DateTime.utc(2026, 11, 23, 0), 9),
    ];

    final days = DailyForecast.fromMetTimeseries(series);
    expect(days.length, 2);

    final first = days[0];
    expect((first.day, first.minTemperatureC, first.maxTemperatureC), (21, 13.0, 14.0));
    // 18→19 arası 1 saat: 0.5; 19→00 arası 5 saat: 6 saatlik 9 → 9.5
    expect(first.precipitationMm, closeTo(9.5, 0.001));

    final second = days[1];
    expect((second.day, second.minTemperatureC, second.maxTemperatureC), (22, 10.0, 18.0));
    expect(second.precipitationMm, closeTo(3.4, 0.001));
    expect(second.maxWindKmh, 29);
    // Yerel 09 ve 15 öğlene eşit uzaklıkta → ilk bulunan (09: yağmur)
    expect(second.symbolCode, 'rain');
    expect(second.weekday, DateTime.sunday);
  });

  test('gece simgesi gündüze çevrilir', () {
    final days = DailyForecast.fromMetTimeseries([
      _entry(DateTime.utc(2026, 11, 22, 9), 12, symbol: 'clearsky_night'),
      _entry(DateTime.utc(2026, 11, 22, 10), 13, symbol: 'clearsky_night'),
    ]);
    expect(days.single.symbolCode, 'clearsky_day');
    expect(weatherConditionKey(days.single.symbolCode), 'clearsky');
  });

  testWidgets('hava durumu sayfası: şu an + günler', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 4000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const WeatherScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Hava Durumu'), findsOneWidget);
    expect(find.text('16°'), findsOneWidget);
    expect(find.text('Parçalı bulutlu'), findsOneWidget);
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Yarın'), findsOneWidget);
    expect(find.textContaining('günlük tahmin'), findsWidgets);
  });
}
