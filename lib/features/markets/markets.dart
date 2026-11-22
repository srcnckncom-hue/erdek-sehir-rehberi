import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/data_result.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/clock_time.dart';

/// Haftalık semt pazarı (data/markets.json). Gün: 1 Pazartesi … 7 Pazar.
@immutable
class Market {
  const Market({
    required this.id,
    required this.name,
    required this.weekday,
    this.startTime,
    this.endTime,
    this.place,
    this.latitude,
    this.longitude,
    this.months = const [],
    this.note,
  });

  factory Market.fromJson(Map<String, dynamic> json) => Market(
        id: json['id'] as String,
        name: json['name'] as String,
        weekday: json['weekday'] as int,
        startTime: switch (json['startTime']) { final String s when s.isNotEmpty => ClockTime.parse(s), _ => null },
        endTime: switch (json['endTime']) { final String s when s.isNotEmpty => ClockTime.parse(s), _ => null },
        place: _text(json['place']),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        months: [for (final m in json['months'] as List<dynamic>? ?? const []) m as int],
        note: _text(json['note']),
      );

  final String id;
  final String name;
  final int weekday;
  final ClockTime? startTime;
  final ClockTime? endTime;
  final String? place;
  final double? latitude;
  final double? longitude;

  /// Yalnızca bu aylarda kurulur (ör. yaz pazarı 6,7,8). Boşsa bütün yıl.
  final List<int> months;
  final String? note;

  bool get isSeasonal => months.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;

  bool isOn(CalendarDate date) => date.weekday == weekday && (months.isEmpty || months.contains(date.month));

  /// [from] dahil, kurulduğu ilk gün (en fazla 1 yıl ileri).
  CalendarDate? nextDate(CalendarDate from) {
    for (var i = 0; i < 366; i++) {
      final d = from.addDays(i);
      if (isOn(d)) return d;
    }
    return null;
  }

  /// Bugün kurulduysa bitti mi (bitiş saati yoksa 14:00 sayılır).
  bool isOverAt(DateTime now) {
    final end = endTime ?? const ClockTime(14, 0);
    return now.hour * 60 + now.minute >= end.minutesOfDay;
  }
}

class MarketsData {
  const MarketsData({required this.markets});

  factory MarketsData.fromJson(Map<String, dynamic> json) => MarketsData(
        markets: [
          for (final m in json['markets'] as List<dynamic>? ?? const []) Market.fromJson(m as Map<String, dynamic>),
        ],
      );

  final List<Market> markets;

  /// Bugün kurulan (henüz bitmemiş) pazarlar, başlangıç saatine göre.
  List<Market> todayOpen(DateTime now) {
    final today = CalendarDate.fromDateTime(now);
    return [for (final m in markets) if (m.isOn(today) && !m.isOverAt(now)) m]
      ..sort((a, b) => (a.startTime?.minutesOfDay ?? 0).compareTo(b.startTime?.minutesOfDay ?? 0));
  }

  /// Haftanın günlerine göre (1–7), yalnızca bu ay kurulanlar; boş günler yok.
  Map<int, List<Market>> byWeekday(CalendarDate today) {
    final out = <int, List<Market>>{};
    for (final m in markets) {
      final next = m.nextDate(today);
      if (next == null || today.daysUntil(next) > 6) continue;
      out.putIfAbsent(m.weekday, () => []).add(m);
    }
    return out;
  }
}

String? _text(Object? v) {
  final t = (v as String?)?.trim();
  return t == null || t.isEmpty ? null : t;
}

final marketsDataProvider = StreamProvider<DataResult<MarketsData>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('markets.json', MarketsData.fromJson),
);
