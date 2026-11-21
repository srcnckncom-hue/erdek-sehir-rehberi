import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/launch/launch_splash.dart';
import 'app/providers.dart';
import 'core/cache/hive_json_cache.dart';
import 'core/settings/locale_store.dart';
import 'core/settings/onboarding_store.dart';
import 'core/settings/seen_store.dart';
import 'core/settings/theme_store.dart';
import 'core/settings/usage_store.dart';
import 'core/system/system_bridge.dart';
import 'core/time/erdek_time.dart';
import 'features/prayer/notifications/prayer_notifications.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErdekTime.init();

  await Hive.initFlutter();
  final cacheBox = await Hive.openBox<String>(HiveJsonCache.boxName);
  final settingsBox = await Hive.openBox<String>(HiveAnnouncementsSeenStore.boxName);

  final notifications = await LocalPrayerNotificationScheduler.initialize();
  // Bildirim metinleri kayıtlı dilde (dil değişirse bir sonraki açılışta).
  final localeStore = HiveLocaleStore(settingsBox);
  final l10n = lookupAppLocalizations(localeStore.load());

  // Logo parçaları çözülmeden ilk kare çizilmesin (animasyon takılmadan başlar).
  await _precacheLogo();

  runApp(
    ProviderScope(
      overrides: [
        jsonCacheProvider.overrideWithValue(HiveJsonCache(cacheBox)),
        announcementsSeenStoreProvider.overrideWithValue(
          HiveAnnouncementsSeenStore(settingsBox),
        ),
        onboardingStoreProvider.overrideWithValue(HiveOnboardingStore(settingsBox)),
        themeModeStoreProvider.overrideWithValue(HiveThemeModeStore(settingsBox)),
        localeStoreProvider.overrideWithValue(localeStore),
        usageStoreProvider.overrideWithValue(HiveUsageStore(settingsBox)),
        systemBridgeProvider.overrideWithValue(ChannelSystemBridge()),
        prayerNotificationSettingsStoreProvider.overrideWithValue(
          HivePrayerNotificationSettingsStore(settingsBox),
        ),
        prayerNotificationSchedulerProvider.overrideWithValue(
          LocalPrayerNotificationScheduler(notifications, l10n),
        ),
      ],
      child: const ErdekApp(),
    ),
  );
}

/// Açılış logosu parçalarını görüntü önbelleğine alır (en fazla 2 sn bekler;
/// hata olursa geçer). Böylece animasyonun ilk karelerinde boşluk olmaz.
Future<void> _precacheLogo() async {
  await Future.wait([
    for (final asset in LaunchSplash.precacheAssets) _precacheAsset(asset),
  ]);
}

Future<void> _precacheAsset(String asset) async {
  final done = Completer<void>();
  final stream = AssetImage(asset).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void finish() {
    if (!done.isCompleted) done.complete();
    stream.removeListener(listener);
  }

  listener = ImageStreamListener((_, _) => finish(), onError: (_, _) => finish());
  stream.addListener(listener);
  await done.future.timeout(const Duration(seconds: 2), onTimeout: () {});
}
