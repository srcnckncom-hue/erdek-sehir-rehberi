import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/time/calendar_date.dart';
import '../../core/time/clock_time.dart';
import '../pharmacy/domain/duty_schedule.dart';
import '../pharmacy/domain/pharmacy.dart';
import '../prayer/domain/prayer_times.dart';

/// iOS ana ekran widget'ı (ios/ErdekWidget) için veri hazırlar ve App Group
/// üzerinden paylaşır. Widget kendi zaman çizelgesini bu veriden kurar;
/// uygulama birkaç gün açılmasa da doğru vakti gösterir.
abstract final class HomeWidgetSync {
  static const _channel = MethodChannel('erdek/widget');

  static const _names = {
    PrayerName.imsak: 'İmsak',
    PrayerName.gunes: 'Güneş',
    PrayerName.ogle: 'Öğle',
    PrayerName.ikindi: 'İkindi',
    PrayerName.aksam: 'Akşam',
    PrayerName.yatsi: 'Yatsı',
  };

  /// Erdek saati (UTC+3, yaz saati yok) → ISO zaman damgası.
  static String _stamp(CalendarDate d, ClockTime t) =>
      '${d}T${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00+03:00';

  /// Widget'a gidecek veri. [days] gün ileriye kadar vakitler ve nöbetler.
  static Map<String, dynamic> buildSnapshot({
    required DateTime erdekNow,
    PrayerTimesData? prayer,
    PharmacyData? pharmacy,
    bool pharmacyIsSample = false,
    int days = 7,
  }) {
    final today = CalendarDate.fromDateTime(erdekNow);
    final prayers = <Map<String, String>>[];
    for (var i = 0; i <= days; i++) {
      final day = prayer?.dayFor(today.addDays(i));
      if (day == null) continue;
      for (final name in PrayerName.values) {
        prayers.add({'name': _names[name]!, 'at': _stamp(day.date, day.timeOf(name))});
      }
    }

    final duties = <Map<String, dynamic>>[];
    if (pharmacy != null) {
      final first = dutyDateFor(erdekNow);
      const changeover = ClockTime(8, 30);
      for (var i = 0; i < days; i++) {
        final date = first.addDays(i);
        final onDuty = pharmacy.onDutyFor(date);
        if (onDuty.isEmpty) continue;
        duties.add({
          'from': _stamp(date, changeover),
          'to': _stamp(date.addDays(1), changeover),
          'names': [for (final p in onDuty) p.name],
        });
      }
    }

    return {
      'version': 1,
      'prayers': prayers,
      'duties': duties,
      'pharmacyIsSample': pharmacyIsSample,
    };
  }

  /// Yalnızca iOS'ta; hata olursa sessizce geçer (widget eski veriyle kalır).
  static Future<void> push(Map<String, dynamic> snapshot) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _channel.invokeMethod<void>('update', jsonEncode(snapshot));
    } on MissingPluginException {
      // widget hedefi olmayan derleme
    } on PlatformException {
      // App Group erişilemedi vb.
    }
  }
}
