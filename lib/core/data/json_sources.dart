import 'package:flutter/services.dart';

/// Uzak JSON'u ham metin olarak getirir (GitHub Pages).
abstract interface class JsonFetcher {
  Future<String> fetch(String path);
}

/// Uygulamayla birlikte gelen JSON kopyası (assets: data/).
abstract interface class BundledJsonSource {
  Future<String?> read(String path);
}

class CachedJson {
  const CachedJson({required this.body, required this.fetchedAt});

  final String body;
  final DateTime fetchedAt;
}

/// Cihazda saklanan son başarılı yanıt.
abstract interface class JsonCache {
  Future<CachedJson?> read(String key);

  Future<void> write(String key, CachedJson value);
}

/// Testler ve önizlemeler için bellek içi önbellek.
class MemoryJsonCache implements JsonCache {
  final Map<String, CachedJson> _items = {};

  @override
  Future<CachedJson?> read(String key) async => _items[key];

  @override
  Future<void> write(String key, CachedJson value) async {
    _items[key] = value;
  }
}

class AssetBundledJsonSource implements BundledJsonSource {
  AssetBundledJsonSource([AssetBundle? bundle]) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<String?> read(String path) async {
    try {
      return await _bundle.loadString('data/$path');
    } catch (_) {
      return null;
    }
  }
}
