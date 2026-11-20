import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/env.dart';
import '../../../app/providers.dart';
import '../../../core/config/erdek_location.dart';
import '../../../core/data/data_result.dart';
import '../../../core/data/json_sources.dart';
import '../domain/weather.dart';

abstract interface class WeatherRepository {
  Stream<DataResult<CurrentWeather>> watch();
}

/// MET Norway (api.met.no) — ücretsiz, ticari kullanım dahil, CC BY 4.0.
///
/// Kullanım koşulları gereği:
///  * Her istekte iletişim bilgisi içeren User-Agent gönderilir.
///  * Yanıttaki `Expires` saatinden önce yeniden istenmez (önbellek).
///  * Uygulamada "Hava durumu: MET Norway" atfı gösterilir (UI adımında).
class MetNorwayWeatherRepository implements WeatherRepository {
  MetNorwayWeatherRepository({
    required this.dio,
    required this.cache,
    required this.userAgent,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const cacheKey = 'weather:met-norway';
  static const endpoint =
      'https://api.met.no/weatherapi/locationforecast/2.0/compact';

  /// Expires başlığı yoksa en az bu kadar bekle.
  static const fallbackTtl = Duration(minutes: 30);

  final Dio dio;
  final JsonCache cache;
  final String userAgent;
  final DateTime Function() _now;

  @override
  Stream<DataResult<CurrentWeather>> watch() async* {
    DataResult<CurrentWeather>? local;
    DateTime? expires;

    final cached = await cache.read(cacheKey);
    if (cached != null) {
      try {
        final stored = jsonDecode(cached.body) as Map<String, dynamic>;
        expires = DateTime.parse(stored['expires'] as String);
        local = _result(
          stored['payload'] as String,
          DataOrigin.cache,
          cached.fetchedAt,
        );
      } catch (_) {
        local = null;
        expires = null;
      }
    }
    if (local != null) yield local;

    // Önbellek hâlâ geçerliyse istek atma (MET kullanım koşulu).
    if (local != null && expires != null && _now().isBefore(expires)) return;

    try {
      if (userAgent.isEmpty) {
        throw StateError('WEATHER_USER_AGENT tanımlı değil.');
      }
      final response = await dio.get<String>(
        endpoint,
        queryParameters: {
          'lat': ErdekLocation.latitude.toStringAsFixed(4),
          'lon': ErdekLocation.longitude.toStringAsFixed(4),
        },
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': userAgent},
        ),
      );
      final payload = response.data;
      if (payload == null || payload.isEmpty) {
        throw StateError('Hava durumu yanıtı boş.');
      }
      final fetchedAt = _now();
      final fresh = _result(payload, DataOrigin.network, fetchedAt);
      final newExpires = _parseExpires(response.headers.value('expires')) ??
          fetchedAt.add(fallbackTtl);
      await cache.write(
        cacheKey,
        CachedJson(
          body: jsonEncode({
            'expires': newExpires.toUtc().toIso8601String(),
            'payload': payload,
          }),
          fetchedAt: fetchedAt,
        ),
      );
      yield fresh;
    } catch (error, stackTrace) {
      if (local == null) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      yield local.withRefreshError(error);
    }
  }

  DataResult<CurrentWeather> _result(
    String payload,
    DataOrigin origin,
    DateTime? fetchedAt,
  ) {
    final weather = CurrentWeather.fromMetCompact(
      jsonDecode(payload) as Map<String, dynamic>,
    );
    return DataResult(
      data: weather,
      origin: origin,
      isSample: false,
      updatedAt: weather.time,
      fetchedAt: fetchedAt,
    );
  }

  static DateTime? _parseExpires(String? value) {
    if (value == null) return null;
    try {
      return HttpDate.parse(value);
    } catch (_) {
      return null;
    }
  }
}

final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => MetNorwayWeatherRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonCacheProvider),
    userAgent: Env.weatherUserAgent,
  ),
);

final currentWeatherProvider = StreamProvider<DataResult<CurrentWeather>>(
  (ref) => ref.watch(weatherRepositoryProvider).watch(),
);
