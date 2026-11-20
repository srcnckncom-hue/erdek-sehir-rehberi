import 'dart:convert';

import 'data_envelope.dart';
import 'data_result.dart';
import 'json_sources.dart';

/// Önce yerel (önbellek, yoksa uygulamayla gelen kopya), sonra internet.
///
/// Akış sırası:
///  1. Yerel kopya varsa hemen yayınlanır (ekran anında dolar).
///  2. İnternetten indirilir; başarılıysa önbelleğe yazılıp yayınlanır.
///  3. İndirme başarısızsa yerel kopya `refreshError` ile tekrar yayınlanır
///     (ekranda "çevrimdışı · son güncelleme: ..." gösterilir).
///  4. Hiç yerel kopya yoksa ve indirme başarısızsa akış hata verir.
class OfflineFirstLoader {
  OfflineFirstLoader({
    required JsonFetcher fetcher,
    required JsonCache cache,
    required BundledJsonSource bundled,
    DateTime Function()? now,
  })  : _fetcher = fetcher,
        _cache = cache,
        _bundled = bundled,
        _now = now ?? DateTime.now;

  final JsonFetcher _fetcher;
  final JsonCache _cache;
  final BundledJsonSource _bundled;
  final DateTime Function() _now;

  Stream<DataResult<T>> watch<T>(
    String path,
    T Function(Map<String, dynamic> data) parseData,
  ) async* {
    DataResult<T>? local;

    final cached = await _cache.read(path);
    if (cached != null) {
      local = _tryParse(cached.body, parseData, DataOrigin.cache, cached.fetchedAt);
    }
    if (local == null) {
      final bundled = await _bundled.read(path);
      if (bundled != null) {
        local = _tryParse(bundled, parseData, DataOrigin.bundled, null);
      }
    }
    if (local != null) yield local;

    try {
      final body = await _fetcher.fetch(path);
      final fetchedAt = _now();
      final fresh = _parse(body, parseData, DataOrigin.network, fetchedAt);
      await _cache.write(path, CachedJson(body: body, fetchedAt: fetchedAt));
      yield fresh;
    } catch (error, stackTrace) {
      if (local == null) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      yield local.withRefreshError(error);
    }
  }

  DataResult<T>? _tryParse<T>(
    String body,
    T Function(Map<String, dynamic> data) parseData,
    DataOrigin origin,
    DateTime? fetchedAt,
  ) {
    try {
      return _parse(body, parseData, origin, fetchedAt);
    } catch (_) {
      return null;
    }
  }

  DataResult<T> _parse<T>(
    String body,
    T Function(Map<String, dynamic> data) parseData,
    DataOrigin origin,
    DateTime? fetchedAt,
  ) {
    final envelope = DataEnvelope<T>.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
      parseData,
    );
    if (envelope.schemaVersion > DataEnvelope.supportedSchemaVersion) {
      throw UnsupportedSchemaVersion(envelope.schemaVersion);
    }
    return DataResult<T>(
      data: envelope.data,
      origin: origin,
      isSample: envelope.isSample,
      updatedAt: envelope.updatedAt,
      fetchedAt: fetchedAt,
    );
  }
}

/// JSON, uygulamanın bu sürümünün bilmediği bir şemayla yayınlanmış.
/// Uygulama eski kopyayla çalışmaya devam eder.
class UnsupportedSchemaVersion implements Exception {
  const UnsupportedSchemaVersion(this.version);

  final int version;

  @override
  String toString() => 'Desteklenmeyen şema sürümü: $version';
}
