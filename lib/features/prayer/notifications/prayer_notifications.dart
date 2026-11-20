import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/time/erdek_time.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/prayer_times.dart';
import 'prayer_notification_plan.dart';

// ─── Ayarların saklanması ────────────────────────────────────────────────

abstract interface class PrayerNotificationSettingsStore {
  PrayerNotificationSettings load();

  Future<void> save(PrayerNotificationSettings settings);
}

class HivePrayerNotificationSettingsStore implements PrayerNotificationSettingsStore {
  HivePrayerNotificationSettingsStore(this.box);

  static const _key = 'prayer_notifications';

  final Box<String> box;

  @override
  PrayerNotificationSettings load() =>
      PrayerNotificationSettings.fromJsonString(box.get(_key));

  @override
  Future<void> save(PrayerNotificationSettings settings) =>
      box.put(_key, settings.toJsonString());
}

class MemoryPrayerNotificationSettingsStore implements PrayerNotificationSettingsStore {
  MemoryPrayerNotificationSettingsStore([this.value = const PrayerNotificationSettings()]);

  PrayerNotificationSettings value;

  @override
  PrayerNotificationSettings load() => value;

  @override
  Future<void> save(PrayerNotificationSettings settings) async => value = settings;
}

// ─── Bildirimleri işletim sistemine kurma ─────────────────────────────────

abstract interface class PrayerNotificationScheduler {
  /// iOS izin penceresini gösterir (ilk açışta). Verildiyse true.
  Future<bool> requestPermission();

  /// Tüm vakit bildirimlerini silip [plan]'dakileri kurar.
  Future<void> reschedule(List<PlannedPrayerNotification> plan);
}

/// Testler ve önizlemeler: hiçbir şey kurmaz.
class NoopPrayerNotificationScheduler implements PrayerNotificationScheduler {
  List<PlannedPrayerNotification> lastPlan = const [];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> reschedule(List<PlannedPrayerNotification> plan) async => lastPlan = plan;
}

/// flutter_local_notifications ile gerçek uygulama.
class LocalPrayerNotificationScheduler implements PrayerNotificationScheduler {
  LocalPrayerNotificationScheduler(this.plugin, this.l10n);

  final FlutterLocalNotificationsPlugin plugin;
  final AppLocalizations l10n;

  /// main() içinde bir kez. İzin penceresi burada GÖSTERİLMEZ; kullanıcı
  /// bildirimleri açtığında [requestPermission] ile istenir.
  static Future<FlutterLocalNotificationsPlugin> initialize() async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    return plugin;
  }

  @override
  Future<bool> requestPermission() async {
    final ios = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(alert: true, badge: false, sound: true);
    return granted ?? false;
  }

  @override
  Future<void> reschedule(List<PlannedPrayerNotification> plan) async {
    await plugin.cancelAll();
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
    for (final n in plan) {
      final name = l10n.prayerName(n.prayer.jsonKey);
      final time = n.prayerTime.toString();
      await plugin.zonedSchedule(
        id: n.id,
        scheduledDate: tz.TZDateTime(
          ErdekTime.location,
          n.fireDate.year,
          n.fireDate.month,
          n.fireDate.day,
          n.fireTime.hour,
          n.fireTime.minute,
        ),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: n.minutesBefore == 0 ? l10n.notifTitleAt(name) : l10n.notifTitleBefore(name),
        body: n.minutesBefore == 0
            ? l10n.notifBodyAt(name, time)
            : l10n.notifBodyBefore(name, n.minutesBefore, time),
      );
    }
  }
}

// ─── Riverpod ─────────────────────────────────────────────────────────────

/// main() içinde Hive ile override edilir.
final prayerNotificationSettingsStoreProvider = Provider<PrayerNotificationSettingsStore>(
  (ref) => MemoryPrayerNotificationSettingsStore(),
);

/// main() içinde gerçek planlayıcı ile override edilir.
final prayerNotificationSchedulerProvider = Provider<PrayerNotificationScheduler>(
  (ref) => NoopPrayerNotificationScheduler(),
);

final prayerNotificationSettingsProvider =
    NotifierProvider<PrayerNotificationSettingsNotifier, PrayerNotificationSettings>(
  PrayerNotificationSettingsNotifier.new,
);

class PrayerNotificationSettingsNotifier extends Notifier<PrayerNotificationSettings> {
  @override
  PrayerNotificationSettings build() => ref.watch(prayerNotificationSettingsStoreProvider).load();

  /// Açarken izin ister; izin yoksa kapalı kalır ve false döner.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      final granted = await ref.read(prayerNotificationSchedulerProvider).requestPermission();
      if (!granted) return false;
    }
    await _update(state.copyWith(enabled: enabled));
    return true;
  }

  Future<void> setMinutesBefore(int minutes) => _update(state.copyWith(minutesBefore: minutes));

  Future<void> togglePrayer(PrayerName prayer, {required bool on}) {
    final next = {...state.prayers};
    on ? next.add(prayer) : next.remove(prayer);
    return _update(state.copyWith(prayers: next));
  }

  Future<void> _update(PrayerNotificationSettings next) async {
    state = next;
    await ref.read(prayerNotificationSettingsStoreProvider).save(next);
  }
}

/// Vakit verisi + ayarlardan bildirimleri yeniden kurar.
Future<void> syncPrayerNotifications({
  required PrayerNotificationScheduler scheduler,
  required PrayerTimesData? data,
  required PrayerNotificationSettings settings,
  required DateTime erdekNow,
}) async {
  if (data == null) return;
  final plan = planPrayerNotifications(data: data, settings: settings, erdekNow: erdekNow);
  await scheduler.reschedule(plan);
}
