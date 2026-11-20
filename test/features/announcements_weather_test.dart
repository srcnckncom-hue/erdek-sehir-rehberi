import 'package:erdek_rehberi/features/announcements/domain/announcement.dart';
import 'package:erdek_rehberi/features/weather/domain/weather.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Duyurular', () {
    final data = AnnouncementsData.fromJson({
      'items': [
        {
          'id': 'eski',
          'category': 'kesinti',
          'title': 'Bitti',
          'body': '-',
          'publishedAt': '2026-11-01T10:00:00+03:00',
          'endsAt': '2026-11-02T10:00:00+03:00',
        },
        {
          'id': 'genel',
          'category': 'bilinmeyen',
          'title': 'Kalıcı',
          'body': '-',
          'publishedAt': '2026-11-10T10:00:00+03:00',
        },
        {
          'id': 'yeni',
          'category': 'etkinlik',
          'title': 'Yeni',
          'body': '-',
          'publishedAt': '2026-11-20T10:00:00+03:00',
          'endsAt': '2026-12-01T00:00:00+03:00',
        },
      ],
    });

    test('süresi dolan çıkar, en yeni üstte', () {
      final now = DateTime.utc(2026, 11, 21);
      expect(data.activeAt(now).map((a) => a.id), ['yeni', 'genel']);
    });

    test('bilinmeyen kategori "genel" sayılır', () {
      expect(data.items[1].category, AnnouncementCategory.general);
    });
  });

  group('Hava durumu', () {
    test('MET Norway compact yanıtını okur', () {
      final weather = CurrentWeather.fromMetCompact({
        'properties': {
          'timeseries': [
            {
              'time': '2026-11-21T09:00:00Z',
              'data': {
                'instant': {
                  'details': {'air_temperature': 15.6},
                },
                'next_1_hours': {
                  'summary': {'symbol_code': 'partlycloudy_day'},
                },
              },
            },
          ],
        },
      });
      expect(weather.roundedTemperature, 16);
      expect(weather.descriptionTr, 'Parçalı bulutlu');
      expect(weather.isNight, isFalse);
    });

    test('nem, rüzgâr ve 24 saatlik min/maks', () {
      Map<String, dynamic> entry(String time, num t) => {
            'time': time,
            'data': {
              'instant': {
                'details': {'air_temperature': t, 'relative_humidity': 72.4, 'wind_speed': 3.3},
              },
              'next_1_hours': {
                'summary': {'symbol_code': 'cloudy'},
              },
            },
          };
      final weather = CurrentWeather.fromMetCompact({
        'properties': {
          'timeseries': [
            entry('2026-11-21T09:00:00Z', 16),
            entry('2026-11-21T10:00:00Z', 22.2),
            entry('2026-11-21T11:00:00Z', 13.8),
          ],
        },
      });
      expect(weather.relativeHumidity!.round(), 72);
      expect(weather.windSpeedKmh, 12);
      expect(weather.minTemperatureC!.round(), 14);
      expect(weather.maxTemperatureC!.round(), 22);
    });

    test('sembol kodu çevirileri', () {
      expect(weatherDescriptionTr('cloudy'), 'Bulutlu');
      expect(weatherDescriptionTr('lightrainshowers_night'), 'Hafif yağmur');
      expect(weatherDescriptionTr('heavyrainandthunder'), 'Gök gürültülü');
      expect(weatherDescriptionTr('clearsky_night'), 'Açık');
    });
  });
}
