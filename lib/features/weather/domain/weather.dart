/// Anlık hava durumu (MET Norway Locationforecast "compact").
class CurrentWeather {
  const CurrentWeather({
    required this.temperatureC,
    required this.symbolCode,
    required this.time,
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

    return CurrentWeather(
      temperatureC: (instant['air_temperature'] as num).toDouble(),
      symbolCode: summary?['symbol_code'] as String? ?? 'unknown',
      time: DateTime.parse(first['time'] as String),
    );
  }

  final double temperatureC;

  /// ör. "partlycloudy_day". İkon seçimi için de kullanılır.
  final String symbolCode;
  final DateTime time;

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
