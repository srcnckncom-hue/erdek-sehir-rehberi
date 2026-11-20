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
    required this.fetcher,
    required this.cache,
    required this.bundled,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final JsonFetcher fetcher;
  final JsonCache cache;
  final BundledJsonSource bundled;
  final DateTime Function() _now;

  Stream<DataResult<T>> watch<T>(
    String path,
    T Function(Map<String, dynamic> data) parseData,
  ) async* {
    DataResult<T>? local;

    final cached = await cache.read(path);
    if (cached != null) {
      local = _tryParse(cached.body, parseData, DataOrigin.cache, cached.fetchedAt);
    }
    if (local == null) {
      final bundledBody = await bundled.read(path);
      if (bundledBody != null) {
        local = _tryParse(bundledBody, parseData, DataOrigin.bundled, null);
      }
    }
    if (local != null) yield local;

    try {
      final body = await fetcher.fetch(path);
      final fetchedAt = _now();
      final fresh = _parse(body, parseData, DataOrigin.network, fetchedAt);
      await cache.write(path, CachedJson(body: body, fetchedAt: fetchedAt));
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
