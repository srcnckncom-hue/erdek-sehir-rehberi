import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../app/firebase_config.dart';

/// Panelden gönderilen bildirimlerin konuları (FCM topic). Kullanıcı her birini
/// Ayarlar › Bildirim konuları'ndan ayrı ayrı açar. Konu adları panel ve
/// supabase/functions/send-push ile AYNI olmalı.
enum PushTopic {
  /// Eski sürümlerdeki "Önemli duyurular" (aboneler korunur).
  general('duyurular'),
  outages('kesintiler'),
  transport('ulasim'),
  events('etkinlikler');

  const PushTopic(this.topic);

  final String topic;
}

/// Firebase Cloud Messaging konu abonelikleri.
///
/// Kullanıcı açmadıkça Firebase hiçbir kimlik/anahtar üretmez
/// (Info.plist: FirebaseMessagingAutoInitEnabled = false).
abstract interface class PushService {
  /// Açarken iOS bildirim izni istenir; izin yoksa false döner.
  Future<bool> setTopic(PushTopic topic, bool on);
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
  Future<bool> setTopic(PushTopic topic, bool on) async {
    try {
      if (!on) {
        await _messaging.unsubscribeFromTopic(topic.topic);
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
      await _messaging.subscribeToTopic(topic.topic);
      return true;
    } on Exception catch (e) {
      debugPrint('Bildirim aboneliği değiştirilemedi: $e');
      return false;
    }
  }
}

/// Testler / Firebase ayarlı değilken.
class NoopPushService implements PushService {
  final calls = <(PushTopic, bool)>[];

  @override
  Future<bool> setTopic(PushTopic topic, bool on) async {
    calls.add((topic, on));
    return true;
  }
}

/// main() içinde FirebasePushService ile override edilir (ayarlıysa).
final pushServiceProvider = Provider<PushService>((ref) => NoopPushService());

/// Firebase ayarlı mı (Ayarlar'da bildirim konularını göstermek için).
final pushAvailableProvider = Provider<bool>((ref) => false);

// ─── Tercih (cihazda) ───────────────────────────────────────────────────

abstract interface class PushPrefsStore {
  /// Kayıt yoksa null.
  bool? read(PushTopic topic);
  Future<void> write(PushTopic topic, bool on);
}

class HivePushPrefsStore implements PushPrefsStore {
  HivePushPrefsStore(this.box);

  /// "Önemli duyurular" eski anahtarıyla aynı (güncellemede kaybolmasın).
  static String keyFor(PushTopic topic) =>
      topic == PushTopic.general ? 'push_announcements' : 'push_topic_${topic.topic}';

  final Box<String> box;

  @override
  bool? read(PushTopic topic) => switch (box.get(keyFor(topic))) {
        'true' => true,
        'false' => false,
        _ => null,
      };

  @override
  Future<void> write(PushTopic topic, bool on) => box.put(keyFor(topic), '$on');
}

class MemoryPushPrefsStore implements PushPrefsStore {
  final values = <PushTopic, bool>{};

  @override
  bool? read(PushTopic topic) => values[topic];

  @override
  Future<void> write(PushTopic topic, bool on) async => values[topic] = on;
}

final pushPrefsStoreProvider = Provider<PushPrefsStore>((ref) => MemoryPushPrefsStore());

/// Açık bildirim konuları.
///
/// Eski sürümde "Önemli duyurular"ı açmış kullanıcıda yeni konular (henüz
/// seçim yapmadıysa) açık sayılır; açılışta [PushTopicsNotifier.refresh] abone eder.
final pushTopicsProvider = NotifierProvider<PushTopicsNotifier, Set<PushTopic>>(PushTopicsNotifier.new);

class PushTopicsNotifier extends Notifier<Set<PushTopic>> {
  @override
  Set<PushTopic> build() {
    final store = ref.watch(pushPrefsStoreProvider);
    final general = store.read(PushTopic.general) ?? false;
    return {
      for (final t in PushTopic.values)
        if (store.read(t) ?? (t != PushTopic.general && general)) t,
    };
  }

  /// İzin verilmezse false döner ve kapalı kalır.
  Future<bool> setEnabled(PushTopic topic, bool on) async {
    final ok = await ref.read(pushServiceProvider).setTopic(topic, on);
    final value = on && ok;
    state = {...state.where((t) => t != topic), if (value) topic};
    await ref.read(pushPrefsStoreProvider).write(topic, value);
    return ok;
  }

  /// Açılışta: açık konulara aboneliği tazele (yeni cihaz anahtarı, yeni konu).
  /// İzin penceresi yalnızca daha önce izin verilmişse sessizce geçer.
  Future<void> refresh() async {
    final store = ref.read(pushPrefsStoreProvider);
    for (final t in state) {
      final ok = await ref.read(pushServiceProvider).setTopic(t, true);
      if (ok && store.read(t) == null) await store.write(t, true);
    }
  }
}
