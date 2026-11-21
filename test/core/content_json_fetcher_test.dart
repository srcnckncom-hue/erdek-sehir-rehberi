import 'package:dio/dio.dart';
import 'package:erdek_rehberi/core/data/json_sources.dart';
import 'package:erdek_rehberi/core/network/content_json_fetcher.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fallback implements JsonFetcher {
  final paths = <String>[];

  @override
  Future<String> fetch(String path) async {
    paths.add(path);
    return '{"from":"pages"}';
  }
}

void main() {
  test('Supabase ayarlı değilse (örnek ayarlar) GitHub Pages kullanılır', () async {
    final fallback = _Fallback();
    final fetcher = ContentJsonFetcher(
      dio: Dio(),
      fallback: fallback,
      supabaseUrl: 'https://example.supabase.co',
      apiKey: 'ornek-anon-key',
    );
    expect(await fetcher.fetch('contacts.json'), '{"from":"pages"}');
    expect(fallback.paths, ['contacts.json']);
  });

  test('namaz vakitleri panelde değil, her zaman Pages', () {
    expect(ContentJsonFetcher.contentIds.containsKey('prayer_times.json'), isFalse);
    expect(ContentJsonFetcher.contentIds['places.json'], 'places');
  });
}
