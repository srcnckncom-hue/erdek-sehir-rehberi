import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../features/explore/presentation/history_screen.dart';
import '../../features/explore/presentation/places_screen.dart';
import '../../features/businesses/presentation/businesses_screen.dart';
import '../../features/social/social_links.dart';
import '../../features/weather/presentation/weather_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../core/system/system_bridge.dart';
import '../../features/settings/presentation/report_issue.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../app_info.dart';
import '../providers.dart';

/// ☰ menüsü: bağımsızlık notu, Keşfet (gezilecek yerler, tarih), Görünüm
/// (açık/koyu tema), Ayarlar ve Hakkında, paylaş, hata bildir.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final themeMode = ref.watch(themeModeProvider);
    return Drawer(
      backgroundColor: p.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/logo.png',
                height: 150,
                semanticLabel: l10n.appTitle,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.drawerIndependentNote,
              style: AppTypography.caption.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n.exploreTitle,
              style: AppTypography.label.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavRow(
              icon: AppIcons.places,
              color: p.aqua.foreground,
              title: l10n.placesTitle,
              onTap: () => _push(context, const PlacesScreen()),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavRow(
              icon: AppIcons.history,
              color: p.iconPurple,
              title: l10n.historyTitle,
              onTap: () => _push(context, const HistoryScreen()),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavRow(
              key: const Key('drawer_businesses'),
              icon: AppIcons.businesses,
              color: p.iconOrange,
              title: l10n.businessesTitle,
              onTap: () => _push(context, const BusinessesScreen()),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavRow(
              icon: AppIcons.forecast,
              color: p.iconBlue,
              title: l10n.weatherTitle,
              onTap: () => _push(context, const WeatherScreen()),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n.appearanceTitle,
              style: AppTypography.label.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedPills<ThemeMode>(
              key: const Key('theme_mode_selector'),
              selected: themeMode,
              onSelected: (mode) => ref.read(themeModeProvider.notifier).setMode(mode),
              options: [
                SegmentOption(value: ThemeMode.light, label: l10n.themeLight, icon: AppIcons.themeLight),
                SegmentOption(value: ThemeMode.dark, label: l10n.themeDark, icon: AppIcons.themeDark),
                SegmentOption(value: ThemeMode.system, label: l10n.themeSystem, icon: AppIcons.themeSystem),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n.settingsSupportTitle,
              style: AppTypography.label.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavRow(
              key: const Key('drawer_settings'),
              icon: AppIcons.settings,
              color: p.primary,
              title: l10n.settingsTitle,
              onTap: () => _push(context, const SettingsScreen()),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavRow(
              icon: AppIcons.share,
              color: p.iconBlue,
              title: l10n.shareAppTitle,
              onTap: () => unawaited(
                ref.read(systemBridgeProvider).share(l10n.shareAppText(AppInfo.shareUrl)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavRow(
              icon: AppIcons.report,
              color: p.iconRed,
              title: l10n.reportIssueTitle,
              onTap: () => openReportEmail(context, ref, section: l10n.appTitle),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SocialLinksRow(),
          ],
        ),
      ),
    );
  }
}

/// Menüyü kapatıp sayfayı açar (aynı Navigator üzerinden).
void _push(BuildContext context, Widget page) {
  final navigator = Navigator.of(context)..pop();
  unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => page)));
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: AppRadius.tileAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.tileAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              AppIcon(icon, size: 24, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title, style: AppTypography.label.copyWith(color: p.textHeading)),
              ),
              AppIcon(AppIcons.caretRight, size: 18, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
