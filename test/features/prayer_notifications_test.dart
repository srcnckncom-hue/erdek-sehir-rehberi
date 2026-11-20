import 'package:erdek_rehberi/core/time/calendar_date.dart';
import 'package:erdek_rehberi/core/time/clock_time.dart';
import 'package:erdek_rehberi/features/prayer/domain/prayer_times.dart';
import 'package:erdek_rehberi/features/prayer/notifications/prayer_notification_plan.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _day(String date, {String imsak = '06:00'}) => {
      'date': date,
      'imsak': imsak,
      'gunes': '07:30',
      'ogle': '12:30',
      'ikindi': '15:00',
      'aksam': '17:30',
      'yatsi': '19:00',
    };

PrayerTimesData _data(List<Map<String, dynamic>> days) =>
    PrayerTimesData.fromJson({'location': 'Erdek', 'days': days});

void main() {
  final data = _data([
    for (var d = 1; d <= 30; d++) _day('2026-11-${d.toString().padLeft(2, '0')}'),
  ]);

  test('kapalıyken hiç bildirim yok', () {
    final plan = planPrayerNotifications(
      data: data,
      settings: const PrayerNotificationSettings(),
      erdekNow: DateTime(2026, 11, 21, 18, 5),
    );
    expect(plan, isEmpty);
  });

  test('10 dk önce: sıradaki yatsı 18:50, sonra yarının imsakı 05:50; güneş yok', () {
    final plan = planPrayerNotifications(
      data: data,
      settings: const PrayerNotificationSettings(enabled: true),
      erdekNow: DateTime(2026, 11, 21, 18, 5),
    );
    expect(plan.first.prayer, PrayerName.yatsi);
    expect(plan.first.fireDate, const CalendarDate(2026, 11, 21));
    expect(plan.first.fireTime, const ClockTime(18, 50));
    expect(plan[1].prayer, PrayerName.imsak);
    expect(plan[1].fireTime, const ClockTime(5, 50));
    expect(plan.any((n) => n.prayer == PrayerName.gunes), isFalse);
  });

  test('bildirim anı geçmişse atlanır', () {
    final plan = planPrayerNotifications(
      data: data,
      settings: const PrayerNotificationSettings(enabled: true, minutesBefore: 0),
      erdekNow: DateTime(2026, 11, 21, 19),
    );
    expect(plan.first.prayer, PrayerName.imsak);
    expect(plan.first.prayerDate, const CalendarDate(2026, 11, 22));
  });

  test('gece yarısını geçen bildirim bir önceki güne düşer', () {
    final plan = planPrayerNotifications(
      data: _data([_day('2026-11-22', imsak: '00:05')]),
      settings: const PrayerNotificationSettings(
        enabled: true,
        minutesBefore: 30,
        prayers: {PrayerName.imsak},
      ),
      erdekNow: DateTime(2026, 11, 21, 20),
    );
    expect(plan.single.fireDate, const CalendarDate(2026, 11, 21));
    expect(plan.single.fireTime, const ClockTime(23, 35));
  });

  test('iOS sınırı: en fazla 60 bildirim, kimlikler tekil', () {
    final plan = planPrayerNotifications(
      data: data,
      settings: const PrayerNotificationSettings(enabled: true),
      erdekNow: DateTime(2026, 11, 1),
    );
    expect(plan, hasLength(maxPendingPrayerNotifications));
    expect(plan.map((n) => n.id).toSet(), hasLength(plan.length));
  });

  test('ayarlar JSON gidiş-dönüş', () {
    const settings = PrayerNotificationSettings(
      enabled: true,
      minutesBefore: 15,
      prayers: {PrayerName.ogle, PrayerName.aksam},
    );
    expect(PrayerNotificationSettings.fromJsonString(settings.toJsonString()), settings);
    expect(PrayerNotificationSettings.fromJsonString('bozuk'), const PrayerNotificationSettings());
  });
}
