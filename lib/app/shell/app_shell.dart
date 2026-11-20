import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/pharmacy/presentation/pharmacy_screen.dart';
import '../../l10n/app_localizations.dart';
import 'app_drawer.dart';
import 'app_tab.dart';

export 'app_tab.dart';

/// Alt menülü ana iskelet. Sekmeler IndexedStack ile durumunu korur.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AppTab _tab = widget.initialTab;

  void _select(AppTab tab) => setState(() => _tab = tab);

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
          // 6–8. adımlarda gerçek ekranlarla değişecek.
          _ComingSoon(title: l10n.tabPrayer, icon: AppIcons.prayer),
          _ComingSoon(title: l10n.tabTransport, icon: AppIcons.ferry),
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
