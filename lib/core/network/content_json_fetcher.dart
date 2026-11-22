import 'dart:convert';

import 'package:dio/dio.dart';

import '../data/json_sources.dart';

/// Panelden düzenlenen içerikleri (telefonlar, duyurular, eczane, ulaşım,
/// gezilecek yerler, tarih, işletmeler, sosyal medya) Supabase'ten okur: get_content(id).
/// Supabase ayarlı değilse ya da o belge henüz panelden kaydedilmemişse
/// GitHub Pages'teki dosyaya [fallback] düşer. Namaz vakitleri hep Pages'ten.
class ContentJsonFetcher implements JsonFetcher {
  ContentJsonFetcher({
    required this.dio,
    required this.fallback,
    required String supabaseUrl,
    required this.apiKey,
  }) : _base = supabaseUrl.endsWith('/')
            ? supabaseUrl.substring(0, supabaseUrl.length - 1)
            : supabaseUrl;

  /// Supabase'te tutulan belgeler (dosya adı → belge kimliği).
  static const contentIds = {
    'contacts.json': 'contacts',
    'announcements.json': 'announcements',
    'pharmacy.json': 'pharmacy',
    'transport.json': 'transport',
    'places.json': 'places',
    'history.json': 'history',
    'businesses.json': 'businesses',
    'social.json': 'social',
    'stories.json': 'stories',
    'appearance.json': 'appearance',
    'events.json': 'events',
    'outages.json': 'outages',
    'markets.json': 'markets',
    'trips.json': 'trips',
  };

  final Dio dio;
  final JsonFetcher fallback;
  final String apiKey;
  final String _base;

  bool get isConfigured =>
      _base.startsWith('https://') && apiKey.isNotEmpty && !_base.contains('example.');

  @override
  Future<String> fetch(String path) async {
    final id = contentIds[path];
    if (id == null || !isConfigured) return fallback.fetch(path);
    final response = await dio.post<String>(
      '$_base/rest/v1/rpc/get_content',
      data: jsonEncode({'p_id': id}),
      options: Options(
        headers: {'apikey': apiKey, 'Content-Type': 'application/json'},
        responseType: ResponseType.plain,
      ),
    );
    final body = response.data?.trim() ?? '';
    if (body.isEmpty || body == 'null') return fallback.fetch(path);
    return body;
  }
}
