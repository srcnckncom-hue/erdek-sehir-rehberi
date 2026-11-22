import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/calendar_date.dart';
import '../../core/time/clock_time.dart';
import '../prayer/domain/prayer_times.dart';
import '../reminders/reminder_scheduler.dart';

/// Ramazan ayı tarihleri (Diyanet dinî günler takvimi). Her yıl buraya eklenir.
class RamadanPeriod {
  const RamadanPeriod({
    required this.hijriYear,
    required this.firstFast,
    required this.lastFast,
    required this.kadirNight,
    required this.eid,
  });

  final int hijriYear;

  /// İlk oruç günü (ilk sahur bir önceki gece).
  final CalendarDate firstFast;
  final CalendarDate lastFast;

  /// Diyanet takviminde Kadir Gecesi'nin yazıldığı gün.
  final CalendarDate kadirNight;

  /// Ramazan Bayramı 1. gün.
  final CalendarDate eid;

  int get dayCount => firstFast.daysUntil(lastFast) + 1;

  bool contains(CalendarDate date) => !date.isBefore(firstFast) && !date.isAfter(lastFast);

  /// 1'den başlayan oruç günü (Ramazan dışında null).
  int? dayNumber(CalendarDate date) => contains(date) ? firstFast.daysUntil(date) + 1 : null;
}

/// Kaynak: Diyanet İşleri Başkanlığı 2027 dinî günler takvimi
/// (1 Ramazan 1448 = 8 Şubat 2027, 29 gün, Kadir Gecesi 5 Mart, Bayram 9 Mart).
const ramadanPeriods = [
  RamadanPeriod(
    hijriYear: 1448,
    firstFast: CalendarDate(2027, 2, 8),
    lastFast: CalendarDate(2027, 3, 8),
    kadirNight: CalendarDate(2027, 3, 5),
    eid: CalendarDate(2027, 3, 9),
  ),
];

/// Bugünü kapsayan ya da sıradaki Ramazan (bayram sabahına kadar). Yoksa null.
RamadanPeriod? currentOrNextRamadan(CalendarDate today, [List<RamadanPeriod> periods = ramadanPeriods]) {
  for (final p in periods) {
    if (today.isBefore(p.eid)) return p;
  }
  return null;
}

/// Uygulamada Ramazan girişi ne zaman görünsün: başlangıçtan 90 gün önce → bayram.
bool showRamadanEntry(CalendarDate today, [List<RamadanPeriod> periods = ramadanPeriods]) {
  final p = currentOrNextRamadan(today, periods);
  return p != null && today.daysUntil(p.firstFast) <= 90;
}

/// Geri sayım hedefi: sahur (imsak) ya da iftar (akşam).
enum RamadanTarget { sahur, iftar }

class RamadanCountdown {
  const RamadanCountdown({required this.target, required this.date, required this.time, required this.remaining});

  final RamadanTarget target;
  final CalendarDate date;
  final ClockTime time;
  final Duration remaining;
}

/// Ramazan içinde sıradaki imsak ya da iftar. Veri yoksa / Ramazan bittiyse null.
RamadanCountdown? ramadanCountdown(RamadanPeriod period, PrayerTimesData data, DateTime erdekNow) {
  final today = CalendarDate.fromDateTime(erdekNow);
  final nowSeconds = erdekNow.hour * 3600 + erdekNow.minute * 60 + erdekNow.second;
  for (var offset = 0; offset <= 1; offset++) {
    final date = today.addDays(offset);
    if (!period.contains(date)) continue;
    final day = data.dayFor(date);
    if (day == null) continue;
    for (final (target, name) in const [
      (RamadanTarget.sahur, PrayerName.imsak),
      (RamadanTarget.iftar, PrayerName.aksam),
    ]) {
      final time = day.timeOf(name);
      final seconds = offset * 86400 + time.minutesOfDay * 60;
      if (seconds > nowSeconds) {
        return RamadanCountdown(
          target: target,
          date: date,
          time: time,
          remaining: Duration(seconds: seconds - nowSeconds),
        );
      }
    }
  }
  return null;
}

// ─── İftar bildirimi ──────────────────────────────────────────────────────

const _iftarKey = 'iftar_notifications';

/// İftar bildirimi açık mı (varsayılan kapalı).
final iftarNotificationsProvider = NotifierProvider<IftarNotificationsNotifier, bool>(IftarNotificationsNotifier.new);

class IftarNotificationsNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(reminderStoreProvider).read(_iftarKey) == '1';

  /// Açarken izin ister; izin yoksa kapalı kalır ve false döner.
  Future<bool> setEnabled(bool on) async {
    if (on && !await ref.read(reminderSchedulerProvider).requestPermission()) return false;
    state = on;
    await ref.read(reminderStoreProvider).write(_iftarKey, on ? '1' : '0');
    return true;
  }
}

/// iOS'un 64 bildirim sınırı için en fazla bu kadar gün önceden kurulur.
const maxIftarNotifications = 7;

/// İftar bildirimlerini yeniden kurar (uygulama açılışında ve ayar değişince).
/// [title] ve [body] (akşam saatiyle) çağıranın dilinde verilir.
Future<void> syncIftarNotifications({
  required ReminderScheduler scheduler,
  required PrayerTimesData? data,
  required bool enabled,
  required DateTime erdekNow,
  required String title,
  required String Function(String time) body,
  List<RamadanPeriod> periods = ramadanPeriods,
}) async {
  await scheduler.cancelRange(NotificationIds.iftarBase, NotificationIds.iftarEnd);
  if (!enabled || data == null) return;
  final today = CalendarDate.fromDateTime(erdekNow);
  final period = currentOrNextRamadan(today, periods);
  if (period == null) return;
  final nowMinutes = erdekNow.hour * 60 + erdekNow.minute;

  var count = 0;
  for (final day in [...data.days]..sort((a, b) => a.date.compareTo(b.date))) {
    if (!period.contains(day.date) || day.date.isBefore(today)) continue;
    final iftar = day.timeOf(PrayerName.aksam);
    if (day.date == today && iftar.minutesOfDay <= nowMinutes) continue;
    final d = day.date;
    await scheduler.schedule(
      id: NotificationIds.iftarBase + (d.year * 10000 + d.month * 100 + d.day) % 100000000,
      erdekAt: DateTime(d.year, d.month, d.day, iftar.hour, iftar.minute),
      title: title,
      body: body(iftar.toString()),
    );
    if (++count >= maxIftarNotifications) break;
  }
}
