import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/json_sources.dart';

/// JsonCache'in hive_ce ile kalıcı uygulaması. Tip adaptörü gerektirmez:
/// her kayıt `{ "body": "<ham json>", "fetchedAt": "<iso>" }` metni olarak saklanır.
class HiveJsonCache implements JsonCache {
  HiveJsonCache(this._box);

  static const boxName = 'json_cache';

  final Box<String> _box;

  @override
  Future<CachedJson?> read(String key) async {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CachedJson(
        body: map['body'] as String,
        fetchedAt: DateTime.parse(map['fetchedAt'] as String),
      );
    } catch (_) {
      // Bozuk kayıt: yok say, bir sonraki başarılı indirme üzerine yazar.
      return null;
    }
  }

  @override
  Future<void> write(String key, CachedJson value) => _box.put(
        key,
        jsonEncode({
          'body': value.body,
          'fetchedAt': value.fetchedAt.toUtc().toIso8601String(),
        }),
      );
}
