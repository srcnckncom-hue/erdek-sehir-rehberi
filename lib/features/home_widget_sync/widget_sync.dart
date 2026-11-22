import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/platform/device.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/clock_time.dart';
import '../pharmacy/domain/duty_schedule.dart';
import '../pharmacy/domain/pharmacy.dart';
import '../prayer/domain/prayer_times.dart';
import '../transport/domain/transport.dart';

/// iOS ana ekran ve kilit ekranı widget'ları (ios/ErdekWidget) için veri hazırlar ve App Group
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
    TransportData? transport,
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

    // Erdek'ten kalkan feribot ve otobüs seferleri (bugün + yarın).
    final departures = <Map<String, String>>[];
    if (transport != null) {
      final nowMinutes = erdekNow.hour * 60 + erdekNow.minute;
      for (final mode in const [TransportMode.ferry, TransportMode.bus]) {
        for (final route in transport.outboundByMode(mode)) {
          for (var i = 0; i <= 1; i++) {
            final date = today.addDays(i);
            for (final d in route.departuresOn(date)) {
              if (i == 0 && d.time.minutesOfDay <= nowMinutes) continue;
              departures.add({
                'mode': mode.jsonValue,
                'route': '${route.from} → ${route.to}',
                'at': _stamp(date, d.time),
              });
            }
          }
        }
      }
      departures.sort((a, b) => a['at']!.compareTo(b['at']!));
      if (departures.length > 40) departures.removeRange(40, departures.length);
    }

    return {
      'version': 2,
      'departures': departures,
      'prayers': prayers,
      'duties': duties,
      'pharmacyIsSample': pharmacyIsSample,
    };
  }

  /// iOS ve Android'de; hata olursa sessizce geçer (widget eski veriyle kalır).
  static Future<void> push(Map<String, dynamic> snapshot) async {
    if (!isAndroidDevice && (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS)) return;
    try {
      await _channel.invokeMethod<void>('update', jsonEncode(snapshot));
    } on MissingPluginException {
      // widget hedefi olmayan derleme
    } on PlatformException {
      // App Group erişilemedi vb.
    }
  }
}
