import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/json_sources.dart';
import 'erdekspor.dart';

/// Sayfa HTML'ini getirir (testlerde dosyadan).
abstract interface class HtmlFetcher {
  Future<String> get(String url);
}

class DioHtmlFetcher implements HtmlFetcher {
  DioHtmlFetcher(this._dio);

  final Dio _dio;

  @override
  Future<String> get(String url) async {
    final r = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: {'User-Agent': 'ErdekSehirRehberi/1.0 (iOS; bilgi amacli)', 'Accept': 'text/html'},
      ),
    );
    return r.data ?? '';
  }
}

final htmlFetcherProvider = Provider<HtmlFetcher>((ref) => DioHtmlFetcher(ref.watch(dioProvider)));

/// Erdekspor: kulüp sayfası + puan durumu. Önce cihazdaki son kopya gösterilir;
/// [maxAge]'den eskiyse siteden yenilenir. İnternet yoksa son kopya kalır.
final erdeksporProvider = AsyncNotifierProvider<ErdeksporNotifier, ErdeksporData?>(ErdeksporNotifier.new);

class ErdeksporNotifier extends AsyncNotifier<ErdeksporData?> {
  static const maxAge = Duration(minutes: 20);
  static const _clubKey = 'erdekspor_club_html';
  static const _groupKey = 'erdekspor_group_html';

  /// Son yenileme hata verdiyse (eski veri gösteriliyor).
  bool refreshFailed = false;

  @override
  Future<ErdeksporData?> build() async {
    final cache = ref.read(jsonCacheProvider);
    final club = await cache.read(_clubKey);
    final group = await cache.read(_groupKey);
    final cached = club == null ? null : _parse(club.body, group?.body, club.fetchedAt);
    final age = club == null ? null : ref.read(clockProvider)().difference(club.fetchedAt);
    if (cached != null && age != null && age < maxAge) return cached;
    try {
      return await _download();
    } catch (_) {
      refreshFailed = true;
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Aşağı çekince: siteden zorla yenile.
  Future<void> refresh() async {
    final previous = state.value;
    try {
      final fresh = await _download();
      refreshFailed = false;
      state = AsyncData(fresh);
    } catch (e, st) {
      refreshFailed = true;
      state = previous != null ? AsyncData(previous) : AsyncError(e, st);
    }
  }

  Future<ErdeksporData> _download() async {
    final fetcher = ref.read(htmlFetcherProvider);
    final cache = ref.read(jsonCacheProvider);
    final now = ref.read(clockProvider)();
    final clubBody = await fetcher.get(ErdeksporSource.clubUrl);
    final club = parseClubPage(clubBody);
    if (club.matches.isEmpty && club.stats.isEmpty) throw const FormatException('Erdekspor sayfası okunamadı');
    final (_, groupUrl) = mainGroupOf(club.matches, club.groupLinks);
    String? groupBody;
    try {
      groupBody = await fetcher.get(groupUrl);
    } catch (_) {
      groupBody = (await cache.read(_groupKey))?.body;
    }
    await cache.write(_clubKey, CachedJson(body: clubBody, fetchedAt: now));
    if (groupBody != null) await cache.write(_groupKey, CachedJson(body: groupBody, fetchedAt: now));
    return _parse(clubBody, groupBody, now)!;
  }

  ErdeksporData? _parse(String clubBody, String? groupBody, DateTime fetchedAt) {
    try {
      final club = parseClubPage(clubBody);
      final (group, _) = mainGroupOf(club.matches, club.groupLinks);
      return ErdeksporData(
        matches: club.matches,
        stats: club.stats,
        standings: groupBody == null ? const [] : parseStandings(groupBody),
        groupName: group,
        season: club.season,
        fetchedAt: fetchedAt,
      );
    } catch (_) {
      return null;
    }
  }
}
