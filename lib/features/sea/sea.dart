import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/data_result.dart';
import '../../core/time/calendar_date.dart';

/// Bir günün deniz bilgisi (Erdek Körfezi).
class SeaDay {
  const SeaDay({required this.date, this.waterTempC, this.waveHeightM, this.waveMaxM});

  factory SeaDay.fromJson(Map<String, dynamic> json) => SeaDay(
        date: CalendarDate.parse(json['date'] as String),
        waterTempC: (json['waterTempC'] as num?)?.toDouble(),
        waveHeightM: (json['waveHeightM'] as num?)?.toDouble(),
        waveMaxM: (json['waveMaxM'] as num?)?.toDouble(),
      );

  final CalendarDate date;

  /// Yüzey suyu sıcaklığı (günlük ortalama).
  final double? waterTempC;

  /// Belirgin dalga yüksekliği: gün ortalaması / en yüksek.
  final double? waveHeightM;
  final double? waveMaxM;

  /// Kabaca deniz durumu: 0 sakin (<0,5 m), 1 hafif (<1,25 m), 2 dalgalı.
  int? get seaState {
    final h = waveMaxM ?? waveHeightM;
    if (h == null) return null;
    if (h < 0.5) return 0;
    if (h < 1.25) return 1;
    return 2;
  }
}

/// Copernicus Marine'den günlük çekilen veri (data/sea.json, GitHub Pages).
class SeaData {
  const SeaData({required this.location, required this.days});

  factory SeaData.fromJson(Map<String, dynamic> json) => SeaData(
        location: json['location'] as String? ?? 'Erdek',
        days: [
          for (final d in json['days'] as List<dynamic>? ?? const [])
            SeaDay.fromJson(d as Map<String, dynamic>),
        ]..sort((a, b) => a.date.compareTo(b.date)),
      );

  final String location;
  final List<SeaDay> days;

  /// [today] ve sonrası (eski günler gösterilmez).
  List<SeaDay> from(CalendarDate today) => [for (final d in days) if (!d.date.isBefore(today)) d];
}

final seaDataProvider = StreamProvider<DataResult<SeaData>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('sea.json', SeaData.fromJson),
);
