import 'dart:convert';

import 'package:erdek_rehberi/core/data/data_result.dart';
import 'package:erdek_rehberi/core/data/json_sources.dart';
import 'package:erdek_rehberi/core/data/offline_first_loader.dart';
import 'package:flutter_test/flutter_test.dart';

String _envelope(int value, {int schemaVersion = 1}) => jsonEncode({
      'schemaVersion': schemaVersion,
      'isSample': false,
      'updatedAt': '2026-11-21T00:00:00+03:00',
      'data': {'value': value},
    });

int _parse(Map<String, dynamic> data) => data['value'] as int;

class _FakeFetcher implements JsonFetcher {
  _FakeFetcher(this.response);

  String? response;
  int calls = 0;

  @override
  Future<String> fetch(String path) async {
    calls++;
    final r = response;
    if (r == null) throw StateError('çevrimdışı');
    return r;
  }
}

class _FakeBundled implements BundledJsonSource {
  _FakeBundled(this.body);

  final String? body;

  @override
  Future<String?> read(String path) async => body;
}

void main() {
  final fixedNow = DateTime.utc(2026, 11, 21, 12);

  OfflineFirstLoader loader(_FakeFetcher f, JsonCache c, {String? bundled}) =>
      OfflineFirstLoader(
        fetcher: f,
        cache: c,
        bundled: _FakeBundled(bundled),
        now: () => fixedNow,
      );

  test('önce önbellek, sonra ağ; ağ yanıtı önbelleğe yazılır', () async {
    final cache = MemoryJsonCache();
    await cache.write('x.json', CachedJson(body: _envelope(1), fetchedAt: DateTime.utc(2026)));
    final fetcher = _FakeFetcher(_envelope(2));

    final results = await loader(fetcher, cache).watch('x.json', _parse).toList();

    expect(results.map((r) => r.data), [1, 2]);
    expect(results.map((r) => r.origin), [DataOrigin.cache, DataOrigin.network]);
    expect(results.last.fetchedAt, fixedNow);
    expect((await cache.read('x.json'))!.body, _envelope(2));
  });

  test('çevrimdışı: önbellek refreshError ile tekrar yayınlanır', () async {
    final cache = MemoryJsonCache();
    await cache.write('x.json', CachedJson(body: _envelope(1), fetchedAt: DateTime.utc(2026)));

    final results = await loader(_FakeFetcher(null), cache).watch('x.json', _parse).toList();

    expect(results, hasLength(2));
    expect(results.last.data, 1);
    expect(results.last.isOffline, isTrue);
  });

  test('önbellek yoksa uygulamayla gelen kopya kullanılır', () async {
    final results = await loader(_FakeFetcher(null), MemoryJsonCache(), bundled: _envelope(7))
        .watch('x.json', _parse)
        .toList();

    expect(results, hasLength(2));
    expect(results.first.data, 7);
    expect(results.first.origin, DataOrigin.bundled);
    expect(results.last.isOffline, isTrue);
  });

  test('hiç kopya yok ve çevrimdışı: hata', () async {
    final stream = loader(_FakeFetcher(null), MemoryJsonCache()).watch('x.json', _parse);
    await expectLater(stream, emitsError(isA<StateError>()));
  });

  test('bozuk önbellek yok sayılır, bundled kopyaya düşer', () async {
    final cache = MemoryJsonCache();
    await cache.write('x.json', CachedJson(body: '{bozuk', fetchedAt: DateTime.utc(2026)));

    final results = await loader(_FakeFetcher(_envelope(3)), cache, bundled: _envelope(9))
        .watch('x.json', _parse)
        .toList();

    expect(results.map((r) => r.data), [9, 3]);
  });

  test('yeni şema sürümü: eski kopyada kalınır', () async {
    final results = await loader(
      _FakeFetcher(_envelope(5, schemaVersion: 99)),
      MemoryJsonCache(),
      bundled: _envelope(1),
    ).watch('x.json', _parse).toList();

    expect(results.last.data, 1);
    expect(results.last.refreshError, isA<UnsupportedSchemaVersion>());
  });
}
