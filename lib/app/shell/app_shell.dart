import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/pharmacy/presentation/pharmacy_screen.dart';
import '../../features/prayer/data/prayer_repository.dart';
import '../../features/prayer/notifications/prayer_notifications.dart';
import '../../features/prayer/presentation/prayer_screen.dart';
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Uygulama öne gelince 60 bildirimlik pencereyi ileri kaydır.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncNotifications();
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
          // 8. adımda gerçek ekranla değişecek.
          _ComingSoon(title: l10n.tabDirectory, icon: AppIcons.contacts),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.icon});

  final String title;
  final AppIconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              title,
              style: AppTypography.sectionTitle.copyWith(color: context.palette.textHeading),
            ),
          ),
          Expanded(
            child: Center(
              child: MessageView(
                icon: icon,
                title: l10n.comingSoonTitle,
                message: l10n.comingSoonMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
