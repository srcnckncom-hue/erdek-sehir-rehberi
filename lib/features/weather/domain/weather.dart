/// Anlık hava durumu (MET Norway Locationforecast "compact").
class CurrentWeather {
  const CurrentWeather({
    required this.temperatureC,
    required this.symbolCode,
    required this.time,
    this.relativeHumidity,
    this.windSpeedMs,
    this.windGustMs,
    this.windFromDegrees,
    this.minTemperatureC,
    this.maxTemperatureC,
    this.daily = const [],
    this.hourly = const [],
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
      windGustMs: (instant['wind_speed_of_gust'] as num?)?.toDouble(),
      windFromDegrees: (instant['wind_from_direction'] as num?)?.toDouble(),
      minTemperatureC: temps.length > 1 ? temps.reduce((a, b) => a < b ? a : b) : null,
      maxTemperatureC: temps.length > 1 ? temps.reduce((a, b) => a > b ? a : b) : null,
      daily: DailyForecast.fromMetTimeseries(timeseries),
      hourly: [
        for (final entry in timeseries.take(25))
          HourlyWeather.fromMetEntry(entry as Map<String, dynamic>),
      ],
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

  /// Hamle (yalnızca "complete" yanıtında; yoksa null).
  final double? windGustMs;

  /// Rüzgârın estiği yön (derece; 0 = kuzeyden, 90 = doğudan).
  final double? windFromDegrees;
  final double? minTemperatureC;
  final double? maxTemperatureC;

  /// Günlük tahmin (bugünden başlayarak; MET Norway yaklaşık 10 gün verir).
  final List<DailyForecast> daily;

  /// Önümüzdeki ~24 saat (saatlik).
  final List<HourlyWeather> hourly;

  int? get windGustKmh => windGustMs == null ? null : (windGustMs! * 3.6).round();

  int? get windSpeedKmh => windSpeedMs == null ? null : (windSpeedMs! * 3.6).round();

  int get roundedTemperature => temperatureC.round();

  bool get isNight => symbolCode.endsWith('_night');

  String get descriptionTr => weatherDescriptionTr(symbolCode);
}

/// Bir günün özeti (Erdek yerel günü).
class DailyForecast {
  const DailyForecast({
    required this.year,
    required this.month,
    required this.day,
    required this.minTemperatureC,
    required this.maxTemperatureC,
    required this.symbolCode,
    this.precipitationMm = 0,
    this.maxWindSpeedMs,
    this.maxWindGustMs,
    this.windFromDegrees,
  });

  /// Türkiye 2016'dan beri yıl boyu UTC+3 (yaz saati yok).
  static const _erdekOffset = Duration(hours: 3);

  /// MET Norway zaman serisini Erdek günlerine böler.
  ///
  ///  * min/maks: o günün anlık sıcaklıkları
  ///  * simge: yerel 12:00'ye en yakın kaydın 6 saatlik (yoksa 1 saatlik) özeti
  ///  * yağış: kayıtlar arası 1 saatse next_1_hours, değilse next_6_hours
  ///  * en az 2 kaydı olmayan gün (serinin son kırpık günü) atlanır.
  static List<DailyForecast> fromMetTimeseries(List<dynamic> timeseries) {
    final days = <String, _DayAccumulator>{};
    final order = <String>[];
    for (var i = 0; i < timeseries.length; i++) {
      final entry = timeseries[i] as Map<String, dynamic>;
      final utc = DateTime.parse(entry['time'] as String).toUtc();
      final local = utc.add(_erdekOffset);
      final key = '${local.year}-${local.month}-${local.day}';
      final acc = days.putIfAbsent(key, () {
        order.add(key);
        return _DayAccumulator(local.year, local.month, local.day);
      });

      final data = entry['data'] as Map<String, dynamic>;
      final details = (data['instant'] as Map<String, dynamic>)['details'] as Map<String, dynamic>;
      final t = (details['air_temperature'] as num?)?.toDouble();
      if (t != null) acc.temps.add(t);
      final wind = (details['wind_speed'] as num?)?.toDouble();
      if (wind != null && (acc.maxWind == null || wind > acc.maxWind!)) {
        acc
          ..maxWind = wind
          ..windFrom = (details['wind_from_direction'] as num?)?.toDouble();
      }
      final gust = (details['wind_speed_of_gust'] as num?)?.toDouble();
      if (gust != null && (acc.maxGust == null || gust > acc.maxGust!)) acc.maxGust = gust;

      final next1 = data['next_1_hours'] as Map<String, dynamic>?;
      final next6 = data['next_6_hours'] as Map<String, dynamic>?;

      // Yağış: bir sonraki kayıt 1 saat sonraysa saatlik miktar, değilse 6 saatlik.
      Duration? gap;
      if (i + 1 < timeseries.length) {
        final nextTime = DateTime.parse(
          (timeseries[i + 1] as Map<String, dynamic>)['time'] as String,
        ).toUtc();
        gap = nextTime.difference(utc);
      }
      final period = gap == const Duration(hours: 1) ? next1 : (next6 ?? next1);
      final amount = ((period?['details'] as Map<String, dynamic>?)?['precipitation_amount'] as num?)
          ?.toDouble();
      if (amount != null) acc.precipitation += amount;

      // Simge: yerel öğlene en yakın kayıt.
      final summary = ((next6 ?? next1)?['summary'] as Map<String, dynamic>?)?['symbol_code'] as String?;
      if (summary != null) {
        final distance = (local.hour - 12).abs();
        if (acc.symbolDistance == null || distance < acc.symbolDistance!) {
          acc
            ..symbol = summary
            ..symbolDistance = distance;
        }
      }
    }

    return [
      for (final key in order)
        if (days[key]!.temps.length >= 2) days[key]!.build(),
    ];
  }

  final int year;
  final int month;
  final int day;
  final double minTemperatureC;
  final double maxTemperatureC;

  /// MET Norway sembol kodu (gündüz hâli tercih edilir).
  final String symbolCode;
  final double precipitationMm;
  final double? maxWindSpeedMs;
  final double? maxWindGustMs;

  /// En kuvvetli rüzgârın estiği yön (derece).
  final double? windFromDegrees;

  int? get maxWindGustKmh => maxWindGustMs == null ? null : (maxWindGustMs! * 3.6).round();

  /// 1 = Pazartesi ... 7 = Pazar
  int get weekday => DateTime.utc(year, month, day).weekday;

  int? get maxWindKmh => maxWindSpeedMs == null ? null : (maxWindSpeedMs! * 3.6).round();

  /// Ekranda gösterilecek yağış (0,1 mm altı gösterilmez).
  bool get hasPrecipitation => precipitationMm >= 0.1;

  String get descriptionTr => weatherDescriptionTr(symbolCode);
}

class _DayAccumulator {
  _DayAccumulator(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;
  final temps = <double>[];
  double precipitation = 0;
  double? maxWind;
  double? maxGust;
  double? windFrom;
  String? symbol;
  int? symbolDistance;

  DailyForecast build() => DailyForecast(
        year: year,
        month: month,
        day: day,
        minTemperatureC: temps.reduce((a, b) => a < b ? a : b),
        maxTemperatureC: temps.reduce((a, b) => a > b ? a : b),
        // Günlük özet için gece simgesini gündüze çevir.
        symbolCode: (symbol ?? 'unknown').replaceAll('_night', '_day'),
        precipitationMm: precipitation,
        maxWindSpeedMs: maxWind,
        maxWindGustMs: maxGust,
        windFromDegrees: windFrom,
      );
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

/// Sembol kodunu çeviri anahtarına indirger (arb: weatherCondition).
String weatherConditionKey(String symbolCode) {
  final base = symbolCode.split('_').first;
  if (base.contains('thunder')) return 'thunder';
  if (base.contains('sleet')) return 'sleet';
  if (base.contains('snow')) return 'snow';
  if (base.contains('heavyrain')) return 'heavyrain';
  if (base.contains('lightrain')) return 'lightrain';
  if (base.contains('rain')) return 'rain';
  if (base == 'fog') return 'fog';
  if (base == 'partlycloudy') return 'partlycloudy';
  if (base == 'cloudy') return 'cloudy';
  if (base == 'fair') return 'fair';
  if (base == 'clearsky') return 'clearsky';
  return 'unknown';
}

/// Saatlik kayıt (Rüzgâr sekmesi).
class HourlyWeather {
  const HourlyWeather({
    required this.time,
    this.temperatureC,
    this.windSpeedMs,
    this.windGustMs,
    this.windFromDegrees,
    this.symbolCode,
  });

  factory HourlyWeather.fromMetEntry(Map<String, dynamic> entry) {
    final data = entry['data'] as Map<String, dynamic>;
    final d = (data['instant'] as Map<String, dynamic>)['details'] as Map<String, dynamic>;
    final next = (data['next_1_hours'] ?? data['next_6_hours']) as Map<String, dynamic>?;
    return HourlyWeather(
      time: DateTime.parse(entry['time'] as String),
      temperatureC: (d['air_temperature'] as num?)?.toDouble(),
      windSpeedMs: (d['wind_speed'] as num?)?.toDouble(),
      windGustMs: (d['wind_speed_of_gust'] as num?)?.toDouble(),
      windFromDegrees: (d['wind_from_direction'] as num?)?.toDouble(),
      symbolCode: (next?['summary'] as Map<String, dynamic>?)?['symbol_code'] as String?,
    );
  }

  /// UTC.
  final DateTime time;
  final double? temperatureC;
  final double? windSpeedMs;
  final double? windGustMs;
  final double? windFromDegrees;
  final String? symbolCode;

  /// Erdek saati (UTC+3).
  DateTime get erdekTime => time.toUtc().add(const Duration(hours: 3));

  int? get windKmh => windSpeedMs == null ? null : (windSpeedMs! * 3.6).round();

  int? get gustKmh => windGustMs == null ? null : (windGustMs! * 3.6).round();
}

/// Rüzgâr yönü: 8 ana yön (0 kuzey … 7 kuzeybatı). Esen yön = rüzgârın geldiği yön.
int windSector8(double fromDegrees) => (((fromDegrees % 360) + 22.5) ~/ 45) % 8;

/// Beaufort ölçeği (0–12), m/s'den.
int beaufort(double ms) {
  const limits = [0.3, 1.6, 3.4, 5.5, 8.0, 10.8, 13.9, 17.2, 20.8, 24.5, 28.5, 32.7];
  for (var i = 0; i < limits.length; i++) {
    if (ms < limits[i]) return i;
  }
  return 12;
}
