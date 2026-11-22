import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/time/calendar_date.dart';
import '../sea/sea.dart';
import '../weather/data/weather_repository.dart';

/// "Bugün denize girilir mi?" sonucu.
enum SwimLevel { great, good, fair, poor }

/// Puanı oluşturan bir etken ve durumu (ekranda renkli etiket).
enum SwimFactorKind { water, air, wave, wind, rain, storm }

enum SwimFactorStatus { ok, warn, bad }

@immutable
class SwimFactor {
  const SwimFactor(this.kind, this.status, [this.value]);

  final SwimFactorKind kind;
  final SwimFactorStatus status;

  /// Su/hava °C, dalga m, rüzgâr m/sn (yağmur ve fırtınada null).
  final double? value;
}

@immutable
class SwimScore {
  const SwimScore({required this.score, required this.factors, required this.waterKnown});

  /// 0–100.
  final int score;
  final List<SwimFactor> factors;

  /// Su sıcaklığı bilinmiyorsa puan yalnızca hava/rüzgâra göre (ekranda not).
  final bool waterKnown;

  SwimLevel get level => switch (score) {
        >= 75 => SwimLevel.great,
        >= 55 => SwimLevel.good,
        >= 35 => SwimLevel.fair,
        _ => SwimLevel.poor,
      };
}

/// Basit, açıklanabilir puan: 100'den başlar, her etkene göre düşer.
/// Eşikler yüzücü konforuna göre (Marmara, yaz): su 24°+ / hava 28°+ / dalga < 0,3 m / rüzgâr < 5 m/sn ideal.
SwimScore swimScoreFor({
  required double airC,
  double? waterC,
  double? waveM,
  double? windMs,
  bool rain = false,
  bool thunder = false,
}) {
  var score = 100;
  final factors = <SwimFactor>[];

  void add(SwimFactorKind kind, double? value, int penalty, {required int warnFrom, required int badFrom}) {
    score -= penalty;
    final status = penalty >= badFrom
        ? SwimFactorStatus.bad
        : penalty >= warnFrom
            ? SwimFactorStatus.warn
            : SwimFactorStatus.ok;
    factors.add(SwimFactor(kind, status, value));
  }

  if (waterC != null) {
    add(
      SwimFactorKind.water,
      waterC,
      switch (waterC) { >= 24 => 0, >= 22 => 5, >= 20 => 15, >= 18 => 30, >= 16 => 50, _ => 70 },
      warnFrom: 15,
      badFrom: 30,
    );
  }
  add(
    SwimFactorKind.air,
    airC,
    switch (airC) { >= 28 => 0, >= 24 => 5, >= 20 => 15, >= 16 => 35, _ => 50 },
    warnFrom: 15,
    badFrom: 35,
  );
  if (waveM != null) {
    add(
      SwimFactorKind.wave,
      waveM,
      switch (waveM) { < 0.3 => 0, < 0.5 => 5, < 1.0 => 20, < 1.5 => 40, _ => 60 },
      warnFrom: 20,
      badFrom: 40,
    );
  }
  if (windMs != null) {
    add(
      SwimFactorKind.wind,
      windMs,
      switch (windMs) { < 5 => 0, < 8 => 10, < 11 => 25, _ => 45 },
      warnFrom: 10,
      badFrom: 25,
    );
  }
  if (thunder) {
    add(SwimFactorKind.storm, null, 60, warnFrom: 1, badFrom: 1);
  } else if (rain) {
    add(SwimFactorKind.rain, null, 20, warnFrom: 1, badFrom: 30);
  }
  return SwimScore(score: score.clamp(0, 100), factors: factors, waterKnown: waterC != null);
}

/// Bugünün puanı: hava (anlık + bugünkü en yüksek), rüzgâr (hamle varsa o),
/// yağış/fırtına (bugünkü tahmin), deniz suyu ve dalga (Copernicus).
final todaySwimScoreProvider = Provider<SwimScore?>((ref) {
  final w = ref.watch(currentWeatherProvider).value?.data;
  if (w == null) return null;
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
  final today = CalendarDate.fromDateTime(now);
  final day = w.daily.where((d) => d.year == today.year && d.month == today.month && d.day == today.day).firstOrNull;
  final sea = ref.watch(seaDataProvider).value?.data.from(today).where((d) => d.date == today).firstOrNull;
  final air = [w.temperatureC, ?day?.maxTemperatureC].reduce((a, b) => a > b ? a : b);
  final symbols = [w.symbolCode, ?day?.symbolCode];
  return swimScoreFor(
    airC: air,
    waterC: sea?.waterTempC,
    waveM: sea?.waveMaxM ?? sea?.waveHeightM,
    windMs: w.windSpeedMs ?? w.windGustMs,
    rain: day?.hasPrecipitation ?? w.symbolCode.contains('rain'),
    thunder: symbols.any((s) => s.contains('thunder')),
  );
});
