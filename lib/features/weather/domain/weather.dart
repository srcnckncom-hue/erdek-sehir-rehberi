/// Anlık hava durumu (MET Norway Locationforecast "compact").
class CurrentWeather {
  const CurrentWeather({
    required this.temperatureC,
    required this.symbolCode,
    required this.time,
    this.relativeHumidity,
    this.windSpeedMs,
    this.minTemperatureC,
    this.maxTemperatureC,
  });

  /// MET Norway compact yanıtının ilk zaman dilimini okur.
  factory CurrentWeather.fromMetCompact(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>;
    final timeseries = properties['timeseries'] as List<dynamic>;
    if (timeseries.isEmpty) {
      throw const FormatException('Hava durumu yanıtında zaman serisi yok');
    }
    final first = timeseries.first as Map<String, dynamic>;
    final data = first['data'] as Map<String, dynamic>;
    final instant = (data['instant'] as Map<String, dynamic>)['details']
        as Map<String, dynamic>;
    final summary = ((data['next_1_hours'] ?? data['next_6_hours'])
        as Map<String, dynamic>?)?['summary'] as Map<String, dynamic>?;

    // Önümüzdeki 24 saatin en düşük / en yüksek sıcaklığı ("14°/22°")
    final temps = <double>[];
    for (final entry in timeseries.take(24)) {
      final d = ((entry as Map<String, dynamic>)['data']
          as Map<String, dynamic>)['instant'] as Map<String, dynamic>;
      final t = (d['details'] as Map<String, dynamic>)['air_temperature'] as num?;
      if (t != null) temps.add(t.toDouble());
    }

    return CurrentWeather(
      temperatureC: (instant['air_temperature'] as num).toDouble(),
      symbolCode: summary?['symbol_code'] as String? ?? 'unknown',
      time: DateTime.parse(first['time'] as String),
      relativeHumidity: (instant['relative_humidity'] as num?)?.toDouble(),
      windSpeedMs: (instant['wind_speed'] as num?)?.toDouble(),
      minTemperatureC: temps.length > 1 ? temps.reduce((a, b) => a < b ? a : b) : null,
      maxTemperatureC: temps.length > 1 ? temps.reduce((a, b) => a > b ? a : b) : null,
    );
  }

  final double temperatureC;

  /// ör. "partlycloudy_day". İkon seçimi için de kullanılır.
  final String symbolCode;
  final DateTime time;

  /// Bağıl nem (%)
  final double? relativeHumidity;

  /// Rüzgâr hızı (m/s). Ekranda km/s gösterilir.
  final double? windSpeedMs;
  final double? minTemperatureC;
  final double? maxTemperatureC;

  int? get windSpeedKmh => windSpeedMs == null ? null : (windSpeedMs! * 3.6).round();

  int get roundedTemperature => temperatureC.round();

  bool get isNight => symbolCode.endsWith('_night');

  String get descriptionTr => weatherDescriptionTr(symbolCode);
}

/// MET Norway sembol kodunu Türkçe kısa açıklamaya çevirir.
String weatherDescriptionTr(String symbolCode) {
  final base = symbolCode.split('_').first;
  if (base.contains('thunder')) return 'Gök gürültülü';
  if (base.contains('sleet')) return 'Karla karışık yağmur';
  if (base.contains('snow')) return 'Kar yağışlı';
  if (base.contains('heavyrain')) return 'Kuvvetli yağmur';
  if (base.contains('lightrain')) return 'Hafif yağmur';
  if (base.contains('rain')) return 'Yağmurlu';
  if (base == 'fog') return 'Sisli';
  if (base == 'partlycloudy') return 'Parçalı bulutlu';
  if (base == 'cloudy') return 'Bulutlu';
  if (base == 'fair') return 'Az bulutlu';
  if (base == 'clearsky') return 'Açık';
  return 'Bilinmiyor';
}
