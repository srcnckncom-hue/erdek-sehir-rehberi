import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../features/explore/presentation/history_screen.dart';
import '../../features/explore/presentation/places_screen.dart';
import '../../l10n/app_localizations.dart';
import '../providers.dart';

/// ☰ menüsü: bağımsızlık notu, Keşfet (gezilecek yerler, tarih), Görünüm
/// (açık/koyu tema), veri kaynakları. Gizlilik bağlantısı 14. adımda eklenecek.
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
                height: 120,
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
            _Section(icon: AppIcons.info, title: l10n.drawerDataSources, body: l10n.dataSourcesBody),
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

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.body});

  final AppIconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: p.surface, borderRadius: AppRadius.tileAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 22, color: p.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTypography.label.copyWith(color: p.textHeading)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: AppTypography.caption.copyWith(color: p.textBody)),
        ],
      ),
    );
  }
}
