import 'package:erdek_rehberi/core/time/calendar_date.dart';
import 'package:erdek_rehberi/core/time/clock_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarDate', () {
    test('ayrıştırır ve yazdırır', () {
      final date = CalendarDate.parse('2026-03-05');
      expect(date, const CalendarDate(2026, 3, 5));
      expect(date.toString(), '2026-03-05');
    });

    test('geçersiz günü reddeder', () {
      expect(() => CalendarDate.parse('2026-02-30'), throwsFormatException);
      expect(() => CalendarDate.parse('2026/02/01'), throwsFormatException);
    });

    test('ay ve yıl sınırında gün ekler', () {
      expect(const CalendarDate(2026, 12, 31).addDays(1), const CalendarDate(2027, 1, 1));
      expect(const CalendarDate(2027, 3, 1).addDays(-1), const CalendarDate(2027, 2, 28));
    });

    test('haftanın günü: 1 Pazartesi', () {
      // 23 Kasım 2026 Pazartesi
      expect(const CalendarDate(2026, 11, 23).weekday, 1);
      expect(const CalendarDate(2026, 11, 29).weekday, 7);
    });
  });

  group('ClockTime', () {
    test('ayrıştırır', () {
      expect(ClockTime.parse('08:30'), const ClockTime(8, 30));
      expect(ClockTime.parse('23:59').minutesOfDay, 23 * 60 + 59);
    });

    test('geçersiz biçimi reddeder', () {
      expect(() => ClockTime.parse('8:30'), throwsFormatException);
      expect(() => ClockTime.parse('24:00'), throwsFormatException);
    });
  });
}
