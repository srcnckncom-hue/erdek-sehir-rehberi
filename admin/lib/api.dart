import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Supabase REST/Auth/Storage istemcisi (yalnızca publishable anahtar +
/// giriş yapan kullanıcının oturumu; secret anahtar KULLANILMAZ).
class Api {
  Api({required String url, required this.apiKey})
      : base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  static const _storageKey = 'erdek_admin_session';
  static const bucket = 'ad-images';

  /// Gezilecek yer fotoğrafları vb. (0003_content_images.sql).
  static const contentBucket = 'content-images';

  final String base;
  final String apiKey;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String? email;

  bool get isConfigured => base.startsWith('https://') && apiKey.isNotEmpty;
  bool get isSignedIn => _refreshToken != null;

  String publicImageUrl(String path) => '$base/storage/v1/object/public/$bucket/$path';

  // ─── Oturum ──────────────────────────────────────────────────────────
  Future<bool> restoreSession() async {
    final saved = web.window.localStorage.getItem(_storageKey);
    if (saved == null) return false;
    try {
      final j = jsonDecode(saved) as Map<String, dynamic>;
      _refreshToken = j['refresh_token'] as String?;
      email = j['email'] as String?;
      if (_refreshToken == null) return false;
      await _refresh();
      return true;
    } catch (_) {
      signOut();
      return false;
    }
  }

  Future<void> signIn(String email, String password) async {
    final res = await http.post(
      Uri.parse('$base/auth/v1/token?grant_type=password'),
      headers: {'apikey': apiKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw ApiException('Giriş başarısız: e-posta veya şifre hatalı.');
    }
    _store(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void signOut() {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    email = null;
    web.window.localStorage.removeItem(_storageKey);
  }

  Future<void> _refresh() async {
    final res = await http.post(
      Uri.parse('$base/auth/v1/token?grant_type=refresh_token'),
      headers: {'apikey': apiKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': _refreshToken}),
    );
    if (res.statusCode != 200) {
      signOut();
      throw ApiException('Oturum süresi doldu, tekrar giriş yapın.');
    }
    _store(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void _store(Map<String, dynamic> j) {
    _accessToken = j['access_token'] as String;
    _refreshToken = j['refresh_token'] as String;
    final expiresIn = (j['expires_in'] as num?)?.toInt() ?? 3600;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn - 60));
    final user = j['user'] as Map<String, dynamic>?;
    email = (user?['email'] as String?) ?? email;
    web.window.localStorage.setItem(
      _storageKey,
      jsonEncode({'refresh_token': _refreshToken, 'email': email}),
    );
  }

  Future<Map<String, String>> _headers({Map<String, String> extra = const {}}) async {
    if (_refreshToken == null) throw ApiException('Giriş yapılmamış.');
    if (_accessToken == null || _expiresAt == null || DateTime.now().isAfter(_expiresAt!)) {
      await _refresh();
    }
    return {
      'apikey': apiKey,
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
      ...extra,
    };
  }

  // ─── REST ────────────────────────────────────────────────────────────
  Future<List<dynamic>> _get(String pathAndQuery) async {
    final res = await http.get(Uri.parse('$base/rest/v1/$pathAndQuery'), headers: await _headers());
    _check(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  void _check(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    var message = 'Sunucu hatası (${res.statusCode})';
    try {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      message = (j['message'] ?? j['error_description'] ?? j['error'] ?? message).toString();
    } catch (_) {
      // gövde JSON değil
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      message = 'Yetki yok: $message';
    }
    throw ApiException(message);
  }

  Future<bool> isAdmin() async => (await _get('admins?select=user_id')).isNotEmpty;

  Future<List<AdSlotInfo>> slots() async => [
        for (final j in await _get('ad_slots?select=*&order=id'))
          AdSlotInfo.fromJson(j as Map<String, dynamic>),
      ];

  Future<List<AdItem>> ads() async => [
        for (final j in await _get('ads?select=*,ad_placements(slot_id)&order=created_at.desc'))
          AdItem.fromJson(j as Map<String, dynamic>),
      ];

  /// Son [days] günün sayaçları.
  Future<List<AdStat>> stats({String? adId, int days = 30}) async {
    final from = DateTime.now().toUtc().subtract(Duration(days: days));
    final day = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
    final filter = adId == null ? '' : '&ad_id=eq.$adId';
    return [
      for (final j in await _get('ad_stats_daily?select=*&day=gte.$day$filter&order=day.desc'))
        AdStat.fromJson(j as Map<String, dynamic>),
    ];
  }

  /// Yeni reklam ya da güncelleme; reklam id'sini döndürür.
  Future<String> saveAd({String? id, required Map<String, dynamic> fields, required List<String> slotIds}) async {
    final headers = await _headers(extra: {'Prefer': 'return=representation'});
    final http.Response res;
    if (id == null) {
      res = await http.post(Uri.parse('$base/rest/v1/ads'), headers: headers, body: jsonEncode(fields));
    } else {
      res = await http.patch(Uri.parse('$base/rest/v1/ads?id=eq.$id'), headers: headers, body: jsonEncode(fields));
    }
    _check(res);
    final adId = ((jsonDecode(res.body) as List<dynamic>).first as Map<String, dynamic>)['id'] as String;

    final del = await http.delete(
      Uri.parse('$base/rest/v1/ad_placements?ad_id=eq.$adId'),
      headers: await _headers(),
    );
    _check(del);
    if (slotIds.isNotEmpty) {
      final ins = await http.post(
        Uri.parse('$base/rest/v1/ad_placements'),
        headers: await _headers(),
        body: jsonEncode([for (final s in slotIds) {'ad_id': adId, 'slot_id': s}]),
      );
      _check(ins);
    }
    return adId;
  }

  Future<void> deleteAd(AdItem ad) async {
    final res = await http.delete(Uri.parse('$base/rest/v1/ads?id=eq.${ad.id}'), headers: await _headers());
    _check(res);
    // Görsel silinemese de reklam silinmiş olur.
    try {
      await http.delete(
        Uri.parse('$base/storage/v1/object/$bucket/${ad.imagePath}'),
        headers: await _headers(),
      );
    } catch (_) {
      // önemli değil
    }
  }

  // ─── İçerik belgeleri (content_docs) ─────────────────────────────────
  /// Panelden kaydedilmiş belge; yoksa null.
  Future<Map<String, dynamic>?> getContent(String id) async {
    final rows = await _get('content_docs?select=doc&id=eq.$id');
    if (rows.isEmpty) return null;
    return (rows.first as Map<String, dynamic>)['doc'] as Map<String, dynamic>;
  }

  /// GitHub Pages'te yayınlanan kopya (panel ilk kez açıldığında başlangıç).
  Future<Map<String, dynamic>> getPublishedCopy(String id) async {
    final res = await http.get(Uri.base.resolve('../data/$id.json'));
    if (res.statusCode != 200) throw ApiException('Yayındaki kopya okunamadı ($id).');
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<void> saveContent(String id, Map<String, dynamic> doc) async {
    final res = await http.post(
      Uri.parse('$base/rest/v1/content_docs?on_conflict=id'),
      headers: await _headers(extra: {'Prefer': 'resolution=merge-duplicates'}),
      body: jsonEncode({'id': id, 'doc': doc}),
    );
    _check(res);
  }

  // ─── Bildirim (send-push Edge Function) ──────────────────────────────
  /// "Önemli duyurular"ı açan herkese anlık bildirim gönderir.
  Future<void> sendPush({required String title, required String body}) async {
    final res = await http.post(
      Uri.parse('$base/functions/v1/send-push'),
      headers: await _headers(),
      body: jsonEncode({'title': title, 'body': body}),
    );
    if (res.statusCode == 404) {
      throw ApiException('send-push fonksiyonu kurulmamış (docs/BILDIRIM_GONDER.md).');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      var message = 'Gönderilemedi (${res.statusCode})';
      try {
        final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        message = (j['error'] ?? j['message'] ?? message).toString();
      } catch (_) {
        // gövde JSON değil
      }
      throw ApiException(message);
    }
  }

  /// Son gönderilen bildirimler (yeniden eskiye).
  Future<List<Map<String, dynamic>>> pushLog({int limit = 20}) async => [
        for (final row in await _get('push_log?select=*&order=sent_at.desc&limit=$limit'))
          row as Map<String, dynamic>,
      ];

  // ─── Storage ─────────────────────────────────────────────────────────
  /// Görseli yükler, kovadaki yolunu döndürür.
  Future<String> uploadImage(Uint8List bytes, {required String contentType}) async {
    final path = 'ad_${DateTime.now().millisecondsSinceEpoch}.${_ext(contentType)}';
    final headers = await _headers(extra: {'Content-Type': contentType, 'x-upsert': 'false'});
    final res = await http.post(Uri.parse('$base/storage/v1/object/$bucket/$path'), headers: headers, body: bytes);
    _check(res);
    return path;
  }

  static String _ext(String contentType) => switch (contentType) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => 'jpg',
      };

  /// İçerik fotoğrafını [folder] altına yükler; herkese açık ADRESİNİ döndürür
  /// (belgeye bu adres yazılır, uygulama doğrudan okur).
  Future<String> uploadContentImage(
    Uint8List bytes, {
    required String contentType,
    required String folder,
  }) async {
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}.${_ext(contentType)}';
    final headers = await _headers(extra: {'Content-Type': contentType, 'x-upsert': 'false'});
    final res = await http.post(
      Uri.parse('$base/storage/v1/object/$contentBucket/$path'),
      headers: headers,
      body: bytes,
    );
    _check(res);
    return '$base/storage/v1/object/public/$contentBucket/$path';
  }
}
