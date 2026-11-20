import 'package:erdek_rehberi/core/time/calendar_date.dart';
import 'package:erdek_rehberi/core/time/clock_time.dart';
import 'package:erdek_rehberi/features/prayer/domain/prayer_times.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _day(String date) => {
      'date': date,
      'imsak': '06:00',
      'gunes': '07:30',
      'ogle': '12:30',
      'ikindi': '15:00',
      'aksam': '17:30',
      'yatsi': '19:00',
    };

void main() {
  final data = PrayerTimesData.fromJson({
    'location': 'Erdek',
    'days': [_day('2026-11-21'), _day('2026-11-22')],
  });

  test('gün içindeki sıradaki vakit ve kalan süre', () {
    final next = findNextPrayer(data, DateTime(2026, 11, 21, 12, 0, 30))!;
    expect(next.name, PrayerName.ogle);
    expect(next.time, const ClockTime(12, 30));
    expect(next.remaining, const Duration(minutes: 29, seconds: 30));
  });

  test('tam vakit anında bir sonrakine geçer', () {
    final next = findNextPrayer(data, DateTime(2026, 11, 21, 15))!;
    expect(next.name, PrayerName.aksam);
  });

  test('yatsıdan sonra yarının imsakı', () {
    final next = findNextPrayer(data, DateTime(2026, 11, 21, 22))!;
    expect(next.name, PrayerName.imsak);
    expect(next.date, const CalendarDate(2026, 11, 22));
    expect(next.remaining, const Duration(hours: 8));
  });

  test('veri biterse null', () {
    expect(findNextPrayer(data, DateTime(2026, 11, 22, 22)), isNull);
    expect(findNextPrayer(data, DateTime(2027, 1, 1)), isNull);
  });

  test('aylık imsakiye sıralı', () {
    expect(data.month(2026, 11).map((d) => d.date.day), [21, 22]);
  });
}
