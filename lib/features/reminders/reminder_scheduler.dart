import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/time/erdek_time.dart';

/// Yerel bildirim kimlik aralıkları (iOS en fazla 64 bekleyen bildirim tutar):
///  * vakit bildirimleri: yyyyMMdd*10 + vakit  (< 1.000.000.000)
///  * iftar: 1.100.000.000 + yyyyMMdd mod 100.000.000
///  * sefer hatırlatıcıları: 1.500.000.000 ile 2.000.000.000 arası
abstract final class NotificationIds {
  static const prayerMax = 1000000000;
  static const iftarBase = 1100000000;
  static const iftarEnd = 1200000000;
  static const departureBase = 1500000000;
  static const departureEnd = 2000000000;
  static const eventBase = 2000000000;
  static const eventEnd = 2100000000;
  static const outageBase = 2100000000;
  static const outageEnd = 2100001000;
}

/// Tek seferlik yerel bildirimler (sefer hatırlatıcısı, iftar).
abstract interface class ReminderScheduler {
  /// İzin yoksa iOS izin penceresini gösterir. Verildiyse true.
  Future<bool> requestPermission();

  /// [erdekAt]: Erdek saatiyle yıl/ay/gün/saat/dakika alanları.
  Future<void> schedule({
    required int id,
    required DateTime erdekAt,
    required String title,
    required String body,
  });

  Future<void> cancel(int id);

  /// [from] ≤ kimlik < [to] aralığındaki bekleyen bildirimleri siler.
  Future<void> cancelRange(int from, int to);
}

/// Testler ve önizlemeler: kurulanları bellekte tutar.
class NoopReminderScheduler implements ReminderScheduler {
  final scheduled = <int, (DateTime, String, String)>{};

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule({
    required int id,
    required DateTime erdekAt,
    required String title,
    required String body,
  }) async =>
      scheduled[id] = (erdekAt, title, body);

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<void> cancelRange(int from, int to) async =>
      scheduled.removeWhere((id, _) => id >= from && id < to);
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler(this.plugin);

  final FlutterLocalNotificationsPlugin plugin;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'hatirlatmalar',
      'Hatırlatmalar',
      channelDescription: 'Sefer, iftar, etkinlik ve kesinti hatırlatmaları',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  @override
  Future<bool> requestPermission() async {
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(alert: true, badge: false, sound: true);
    return granted ?? false;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime erdekAt,
    required String title,
    required String body,
  }) =>
      plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime(
          ErdekTime.location,
          erdekAt.year,
          erdekAt.month,
          erdekAt.day,
          erdekAt.hour,
          erdekAt.minute,
        ),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );

  @override
  Future<void> cancel(int id) => plugin.cancel(id: id);

  @override
  Future<void> cancelRange(int from, int to) async {
    final pending = await plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= from && request.id < to) await plugin.cancel(id: request.id);
    }
  }
}

/// main() içinde LocalReminderScheduler ile override edilir.
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => NoopReminderScheduler());

// ─── Basit anahtar–değer saklama (Hive settings kutusu) ─────────────────────

abstract interface class ReminderStore {
  String? read(String key);

  Future<void> write(String key, String? value);
}

class HiveReminderStore implements ReminderStore {
  HiveReminderStore(this.box);

  final Box<String> box;

  @override
  String? read(String key) => box.get(key);

  @override
  Future<void> write(String key, String? value) => value == null ? box.delete(key) : box.put(key, value);
}

class MemoryReminderStore implements ReminderStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

/// main() içinde Hive ile override edilir.
final reminderStoreProvider = Provider<ReminderStore>((ref) => MemoryReminderStore());
