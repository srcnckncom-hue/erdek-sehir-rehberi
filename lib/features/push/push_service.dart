import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../app/firebase_config.dart';

/// Panelden / Firebase konsolundan gönderilen "önemli duyuru" bildirimleri
/// (Firebase Cloud Messaging, konu: [PushService.announcementsTopic]).
///
/// Kullanıcı açmadıkça Firebase hiçbir kimlik/anahtar üretmez
/// (Info.plist: FirebaseMessagingAutoInitEnabled = false).
abstract interface class PushService {
  static const announcementsTopic = 'duyurular';

  /// Açarken iOS bildirim izni istenir; izin yoksa false döner.
  Future<bool> setAnnouncementsEnabled(bool on);
}

class FirebasePushService implements PushService {
  FirebasePushService._();

  /// Firebase ayarı yoksa (config/GoogleService-Info.plist eklenmemişse)
  /// null döner; uygulama bildirimsiz çalışmaya devam eder.
  static Future<FirebasePushService?> initialize() async {
    final options = FirebaseConfig.options;
    if (options == null) return null;
    try {
      await Firebase.initializeApp(options: options);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      return FirebasePushService._();
    } on Exception catch (e) {
      debugPrint('Firebase başlatılamadı: $e');
      return null;
    }
  }

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  Future<bool> setAnnouncementsEnabled(bool on) async {
    try {
      if (!on) {
        await _messaging.unsubscribeFromTopic(PushService.announcementsTopic);
        return true;
      }
      final settings = await _messaging.requestPermission();
      final allowed = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) return false;
      await _messaging.setAutoInitEnabled(true);
      // iOS: konuya abone olmadan önce APNs anahtarı gelmiş olmalı.
      for (var i = 0; i < 10 && await _messaging.getAPNSToken() == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      await _messaging.subscribeToTopic(PushService.announcementsTopic);
      return true;
    } on Exception catch (e) {
      debugPrint('Bildirim aboneliği değiştirilemedi: $e');
      return false;
    }
  }
}

/// Testler / Firebase ayarlı değilken.
class NoopPushService implements PushService {
  final calls = <bool>[];

  @override
  Future<bool> setAnnouncementsEnabled(bool on) async {
    calls.add(on);
    return true;
  }
}

/// main() içinde FirebasePushService ile override edilir (ayarlıysa).
final pushServiceProvider = Provider<PushService>((ref) => NoopPushService());

/// Firebase ayarlı mı (Ayarlar'da anahtarı göstermek için).
final pushAvailableProvider = Provider<bool>((ref) => false);

// ─── Tercih (cihazda) ───────────────────────────────────────────────────

abstract interface class PushPrefsStore {
  bool get announcementsEnabled;
  Future<void> setAnnouncementsEnabled(bool on);
}

class HivePushPrefsStore implements PushPrefsStore {
  HivePushPrefsStore(this.box);

  static const _key = 'push_announcements';

  final Box<String> box;

  @override
  bool get announcementsEnabled => box.get(_key) == 'true';

  @override
  Future<void> setAnnouncementsEnabled(bool on) => box.put(_key, '$on');
}

class MemoryPushPrefsStore implements PushPrefsStore {
  @override
  bool announcementsEnabled = false;

  @override
  Future<void> setAnnouncementsEnabled(bool on) async => announcementsEnabled = on;
}

final pushPrefsStoreProvider = Provider<PushPrefsStore>((ref) => MemoryPushPrefsStore());

/// "Önemli duyurular" bildirimleri açık mı.
final announcementsPushProvider = NotifierProvider<AnnouncementsPushNotifier, bool>(
  AnnouncementsPushNotifier.new,
);

class AnnouncementsPushNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(pushPrefsStoreProvider).announcementsEnabled;

  /// İzin verilmezse false döner ve kapalı kalır.
  Future<bool> setEnabled(bool on) async {
    final ok = await ref.read(pushServiceProvider).setAnnouncementsEnabled(on);
    final value = on && ok;
    state = value;
    await ref.read(pushPrefsStoreProvider).setAnnouncementsEnabled(value);
    return ok;
  }

  /// Açılışta: açıksa aboneliği tazele (yeni cihaz anahtarı vb.).
  Future<void> refresh() async {
    if (state) unawaited(ref.read(pushServiceProvider).setAnnouncementsEnabled(true));
  }
}
