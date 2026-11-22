import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/widgets/widgets.dart';
import '../../features/contacts/presentation/directory_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home_widget_sync/widget_sync.dart';
import '../../features/pharmacy/data/pharmacy_repository.dart';
import '../../features/push/push_service.dart';
import '../../features/pharmacy/presentation/pharmacy_screen.dart';
import '../../features/prayer/data/prayer_repository.dart';
import '../../features/prayer/notifications/prayer_notifications.dart';
import '../../features/prayer/presentation/prayer_screen.dart';
import '../../features/ramadan/ramadan.dart';
import '../../features/reminders/reminder_scheduler.dart';
import '../../features/transport/data/transport_repository.dart';
import '../../features/transport/presentation/transport_screen.dart';
import '../providers.dart';
import '../../l10n/app_localizations.dart';
import 'app_drawer.dart';
import 'app_tab.dart';

export 'app_tab.dart';

/// Alt menülü ana iskelet. Sekmeler IndexedStack ile durumunu korur.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AppTab _tab = widget.initialTab;

  void _select(AppTab tab) => setState(() => _tab = tab);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Vakit verisi ya da bildirim ayarı değişince bildirimleri yeniden kur.
    ref.listenManual(prayerTimesProvider, (_, _) => _syncNotifications(), fireImmediately: true);
    ref.listenManual(prayerNotificationSettingsProvider, (_, _) => _syncNotifications());
    // iOS ana ekran widget'ı: vakit ya da eczane verisi değişince güncelle.
    ref.listenManual(prayerTimesProvider, (_, _) => _syncWidget(), fireImmediately: true);
    ref.listenManual(pharmacyDataProvider, (_, _) => _syncWidget(), fireImmediately: true);
    ref.listenManual(transportDataProvider, (_, _) => _syncWidget(), fireImmediately: true);
    // Açık bildirim konularına aboneliği tazele (yalnızca Firebase ayarlıysa).
    if (ref.read(pushAvailableProvider)) {
      unawaited(ref.read(pushTopicsProvider.notifier).refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Uygulama öne gelince 60 bildirimlik pencereyi ileri kaydır.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNotifications();
      _syncWidget();
    }
  }

  void _syncWidget() {
    final pharmacy = ref.read(pharmacyDataProvider).value;
    unawaited(
      HomeWidgetSync.push(
        HomeWidgetSync.buildSnapshot(
          erdekNow: ref.read(clockProvider)(),
          prayer: ref.read(prayerTimesProvider).value?.data,
          pharmacy: pharmacy?.data,
          pharmacyIsSample: pharmacy?.isSample ?? false,
          transport: ref.read(transportDataProvider).value?.data,
        ),
      ),
    );
  }

  void _syncNotifications() {
    unawaited(
      syncPrayerNotifications(
        scheduler: ref.read(prayerNotificationSchedulerProvider),
        data: ref.read(prayerTimesProvider).value?.data,
        settings: ref.read(prayerNotificationSettingsProvider),
        erdekNow: ref.read(clockProvider)(),
      ),
    );
    final l10n = lookupAppLocalizations(ref.read(localeProvider));
    unawaited(
      syncIftarNotifications(
        scheduler: ref.read(reminderSchedulerProvider),
        data: ref.read(prayerTimesProvider).value?.data,
        enabled: ref.read(iftarNotificationsProvider),
        erdekNow: ref.read(clockProvider)(),
        title: l10n.iftarNotifTitle,
        body: l10n.iftarNotifBody,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      TabItem(label: l10n.tabHome, icon: AppIcons.tabHome),
      TabItem(label: l10n.tabPharmacy, icon: AppIcons.tabPharmacy),
      TabItem(label: l10n.tabPrayer, icon: AppIcons.tabPrayer),
      TabItem(label: l10n.tabTransport, icon: AppIcons.tabTransport),
      TabItem(label: l10n.tabDirectory, icon: AppIcons.tabDirectory),
    ];

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: FloatingTabBar(
        items: items,
        currentIndex: _tab.index,
        onSelected: (i) => _select(AppTab.values[i]),
      ),
      body: IndexedStack(
        index: _tab.index,
        children: [
          HomeScreen(
            onOpenTab: _select,
            onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const PharmacyScreen(),
          const PrayerScreen(),
          const TransportScreen(),
          DirectoryScreen(isActive: _tab == AppTab.directory),
        ],
      ),
    );
  }
}
