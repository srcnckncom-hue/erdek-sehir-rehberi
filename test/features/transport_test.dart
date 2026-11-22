import 'package:erdek_rehberi/core/time/calendar_date.dart';
import 'package:erdek_rehberi/features/transport/domain/transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final route = TransportRoute.fromJson({
    'id': 'erdek-avsa',
    'mode': 'ferry',
    'title': 'Erdek – Avşa',
    'from': 'Erdek',
    'to': 'Avşa',
    'timetables': [
      {
        'name': 'Kış',
        'validFrom': '2026-10-01',
        'validTo': '2027-05-31',
        'departures': [
          {'time': '16:00', 'days': [1, 2, 3, 4, 5, 6]},
          {'time': '09:00'},
        ],
      },
      {
        'name': 'Yaz',
        'validFrom': '2027-06-01',
        'validTo': '2027-09-30',
        'departures': [
          {'time': '08:00'},
        ],
      },
    ],
  });

  test('dönem seçimi (yaz/kış)', () {
    expect(route.timetableFor(const CalendarDate(2026, 11, 21))!.name, 'Kış');
    expect(route.timetableFor(const CalendarDate(2027, 7, 1))!.name, 'Yaz');
    expect(route.timetableFor(const CalendarDate(2027, 12, 1)), isNull);
  });

  test('seferler saate göre sıralı ve güne göre süzülür', () {
    // 23 Kasım 2026 Pazartesi
    expect(route.departuresOn(const CalendarDate(2026, 11, 23)).map((d) => d.time.toString()), ['09:00', '16:00']);
    // 29 Kasım 2026 Pazar
    expect(route.departuresOn(const CalendarDate(2026, 11, 29)).map((d) => d.time.toString()), ['09:00']);
  });

  test('sıradaki seferler ertesi güne taşar', () {
    // Pazartesi 17:00 → Salı 09:00, Salı 16:00, Çarşamba 09:00
    final next = upcomingDepartures(route, DateTime(2026, 11, 23, 17));
    expect(
      next.map((u) => '${u.date} ${u.departure.time}'),
      ['2026-11-24 09:00', '2026-11-24 16:00', '2026-11-25 09:00'],
    );
  });

  test('kalkış saatindeki sefer kaçmış sayılır', () {
    final next = upcomingDepartures(route, DateTime(2026, 11, 23, 9), limit: 1);
    expect(next.single.departure.time.toString(), '16:00');
  });

  group('duraklar ve harita bağlantısı', () {
    TransportRoute city(List<String> stops) => TransportRoute.fromJson({
          'id': 'c',
          'mode': 'city',
          'title': 'Otogar → Kamplar',
          'from': 'Otogar',
          'to': 'Kamplar',
          'stops': stops,
          'timetables': [
            {
              'name': 'T',
              'validFrom': '2026-01-01',
              'validTo': '2027-12-31',
              'departures': [
                {'time': '08:00', 'days': [1, 2, 3, 4, 5, 6, 7]},
              ],
            },
          ],
        });

    test('durak yoksa bağlantı yok', () {
      expect(route.stops, isEmpty);
      expect(route.mapsUrl(), isNull);
    });

    test('ilk ve son durak başlangıç ve varış olur', () {
      final uri = Uri.parse(city(['Pazar Alanı', 'Erdek Plajı', 'Ay Kamping']).mapsUrl()!);
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['origin'], 'Pazar Alanı, Erdek, Balıkesir');
      expect(uri.queryParameters['destination'], 'Ay Kamping, Erdek, Balıkesir');
      expect(uri.queryParameters['waypoints'], 'Erdek Plajı, Erdek, Balıkesir');
    });

    test('en fazla 9 ara durak gönderilir', () {
      final stops = [for (var i = 0; i < 17; i++) 'D$i'];
      final uri = Uri.parse(city(stops).mapsUrl()!);
      final wp = uri.queryParameters['waypoints']!.split('|');
      expect(wp, hasLength(9));
      expect(wp.first, 'D1, Erdek, Balıkesir');
      expect(wp.last, 'D15, Erdek, Balıkesir');
    });
  });
}
