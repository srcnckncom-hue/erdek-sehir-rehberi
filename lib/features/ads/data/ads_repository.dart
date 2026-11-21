import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/env.dart';
import '../../../app/providers.dart';
import '../../../core/data/json_sources.dart';
import '../domain/ad.dart';

/// Reklamları Supabase'ten okur (yalnızca get_active_ads / record_ad_event
/// fonksiyonları; tablolara doğrudan erişim yok). Son başarılı yanıt
/// önbelleğe yazılır; internet yoksa oradan gösterilir.
class AdsRepository {
  AdsRepository({
    required Dio dio,
    required JsonCache cache,
    required String supabaseUrl,
    required String apiKey,
  })  : _dio = dio,
        _cache = cache,
        _base = supabaseUrl.endsWith('/') ? supabaseUrl.substring(0, supabaseUrl.length - 1) : supabaseUrl,
        _apiKey = apiKey;

  static const _cacheKey = 'ads_active';

  final Dio _dio;
  final JsonCache _cache;
  final String _base;
  final String _apiKey;

  /// Test/CI derlemelerinde (örnek ayarlar) ağa hiç çıkılmaz.
  bool get isConfigured =>
      _base.startsWith('https://') && _apiKey.isNotEmpty && !_base.contains('example.');

  Options get _options => Options(
        headers: {'apikey': _apiKey, 'Content-Type': 'application/json'},
        responseType: ResponseType.plain,
      );

  String imageUrl(Ad ad) => '$_base/storage/v1/object/public/ad-images/${ad.imagePath}';

  Future<List<Ad>> loadActive() async {
    if (!isConfigured) return const [];
    try {
      final response = await _dio.post<String>(
        '$_base/rest/v1/rpc/get_active_ads',
        data: '{}',
        options: _options,
      );
      final body = response.data ?? '[]';
      final ads = _parse(body);
      await _cache.write(_cacheKey, CachedJson(body: body, fetchedAt: DateTime.now()));
      return ads;
    } catch (_) {
      final cached = await _cache.read(_cacheKey);
      if (cached == null) return const [];
      try {
        return _parse(cached.body);
      } catch (_) {
        return const [];
      }
    }
  }

  /// Sayaç; hata olursa sessizce geçilir (reklam gösterimini etkilemez).
  Future<void> record(Ad ad, AdEventKind kind) async {
    if (!isConfigured) return;
    try {
      await _dio.post<String>(
        '$_base/rest/v1/rpc/record_ad_event',
        data: jsonEncode({'p_ad_id': ad.id, 'p_slot_id': ad.slotId, 'p_kind': kind.name}),
        options: _options,
      );
    } catch (_) {
      // Sayılamayan olay önemli değil.
    }
  }

  static List<Ad> _parse(String body) => (jsonDecode(body) as List<dynamic>)
      .map((e) => Ad.fromJson(e as Map<String, dynamic>))
      .toList();
}

final adsRepositoryProvider = Provider<AdsRepository>(
  (ref) => AdsRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonCacheProvider),
    supabaseUrl: Env.supabaseUrl,
    apiKey: Env.supabaseAnonKey,
  ),
);

/// Uygulama oturumundaki yayındaki reklamlar (ana sayfada aşağı çekince yenilenir).
final activeAdsProvider = FutureProvider<List<Ad>>(
  (ref) => ref.watch(adsRepositoryProvider).loadActive(),
);

/// Oturum başına rastgele başlangıç: aynı slotta birden çok reklam varsa
/// her açılışta farklısı gösterilir.
final adRotationSeedProvider = Provider<int>((ref) => Random().nextInt(1 << 20));
