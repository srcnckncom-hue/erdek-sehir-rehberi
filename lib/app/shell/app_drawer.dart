import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../features/explore/presentation/history_screen.dart';
import '../../features/explore/presentation/places_screen.dart';
import '../../l10n/app_localizations.dart';

/// ☰ menüsü: bağımsızlık notu, Keşfet (gezilecek yerler, tarih), veri kaynakları. Ayarlar (bildirim
/// tercihleri) 6. adımda, gizlilik bağlantısı 14. adımda eklenecek.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Drawer(
      backgroundColor: p.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              l10n.appTitle,
              style: AppTypography.sectionTitle.copyWith(color: p.textHeading),
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
