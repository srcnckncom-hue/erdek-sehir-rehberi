import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock_time.dart';
import '../domain/prayer_times.dart';

/// Kullanıcının vakit bildirimi tercihleri (yalnızca cihazda saklanır).
@immutable
class PrayerNotificationSettings {
  const PrayerNotificationSettings({
    this.enabled = false,
    this.minutesBefore = 10,
    this.prayers = defaultPrayers,
  });

  factory PrayerNotificationSettings.fromJsonString(String? raw) {
    if (raw == null) return const PrayerNotificationSettings();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PrayerNotificationSettings(
        enabled: json['enabled'] as bool? ?? false,
        minutesBefore: json['minutesBefore'] as int? ?? 10,
        prayers: {
          for (final key in (json['prayers'] as List<dynamic>? ?? const []).cast<String>())
            ...PrayerName.values.where((p) => p.jsonKey == key),
        },
      );
    } catch (_) {
      return const PrayerNotificationSettings();
    }
  }

  /// Güneş bir namaz vakti değil; varsayılan olarak kapalı.
  static const defaultPrayers = {
    PrayerName.imsak,
    PrayerName.ogle,
    PrayerName.ikindi,
    PrayerName.aksam,
    PrayerName.yatsi,
  };

  /// Seçilebilir "kaç dakika önce" değerleri (0 = vaktinde).
  static const minuteOptions = [0, 5, 10, 15, 30, 45];

  final bool enabled;
  final int minutesBefore;
  final Set<PrayerName> prayers;

  PrayerNotificationSettings copyWith({
    bool? enabled,
    int? minutesBefore,
    Set<PrayerName>? prayers,
  }) =>
      PrayerNotificationSettings(
        enabled: enabled ?? this.enabled,
        minutesBefore: minutesBefore ?? this.minutesBefore,
        prayers: prayers ?? this.prayers,
      );

  String toJsonString() => jsonEncode({
        'enabled': enabled,
        'minutesBefore': minutesBefore,
        'prayers': [for (final p in PrayerName.values) if (prayers.contains(p)) p.jsonKey],
      });

  @override
  bool operator ==(Object other) =>
      other is PrayerNotificationSettings &&
      other.enabled == enabled &&
      other.minutesBefore == minutesBefore &&
      setEquals(other.prayers, prayers);

  @override
  int get hashCode => Object.hash(enabled, minutesBefore, Object.hashAllUnordered(prayers));
}

/// Planlanacak tek bir bildirim (Erdek saatiyle alanlar).
@immutable
class PlannedPrayerNotification {
  const PlannedPrayerNotification({
    required this.id,
    required this.prayer,
    required this.prayerDate,
    required this.prayerTime,
    required this.fireDate,
    required this.fireTime,
    required this.minutesBefore,
  });

  /// Gün + vakit sırasından türetilen sabit kimlik (yyyyMMdd*10 + vakit).
  final int id;
  final PrayerName prayer;
  final CalendarDate prayerDate;
  final ClockTime prayerTime;
  final CalendarDate fireDate;
  final ClockTime fireTime;
  final int minutesBefore;
}

/// iOS en fazla 64 bekleyen yerel bildirime izin verir; pay bırakıyoruz.
const maxPendingPrayerNotifications = 60;

/// [erdekNow]'dan sonraki bildirimleri, en fazla [max] adet, sırayla planlar.
/// Uygulama her açıldığında ve veri/ayar değiştiğinde yeniden hesaplanır.
List<PlannedPrayerNotification> planPrayerNotifications({
  required PrayerTimesData data,
  required PrayerNotificationSettings settings,
  required DateTime erdekNow,
  int max = maxPendingPrayerNotifications,
}) {
  if (!settings.enabled || settings.prayers.isEmpty) return const [];

  final today = CalendarDate.fromDateTime(erdekNow);
  final nowMinutes = erdekNow.hour * 60 + erdekNow.minute;
  final days = data.days.where((d) => !d.date.isBefore(today.addDays(-1))).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final result = <PlannedPrayerNotification>[];
  for (final day in days) {
    for (final prayer in PrayerName.values) {
      if (!settings.prayers.contains(prayer)) continue;
      final time = day.timeOf(prayer);

      // Bildirim anı = vakit − X dk (gün sınırını geçebilir).
      var fireMinutes = time.minutesOfDay - settings.minutesBefore;
      var fireDate = day.date;
      while (fireMinutes < 0) {
        fireMinutes += 24 * 60;
        fireDate = fireDate.addDays(-1);
      }

      final isPast = fireDate.isBefore(today) ||
          (fireDate == today && fireMinutes <= nowMinutes);
      if (isPast) continue;

      result.add(
        PlannedPrayerNotification(
          id: (day.date.year * 10000 + day.date.month * 100 + day.date.day) * 10 + prayer.index,
          prayer: prayer,
          prayerDate: day.date,
          prayerTime: time,
          fireDate: fireDate,
          fireTime: ClockTime(fireMinutes ~/ 60, fireMinutes % 60),
          minutesBefore: settings.minutesBefore,
        ),
      );
      if (result.length >= max) return result;
    }
  }
  return result;
}
