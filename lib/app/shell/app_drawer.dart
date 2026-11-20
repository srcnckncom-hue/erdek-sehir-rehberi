import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// ☰ menüsü: bağımsızlık notu, veri kaynakları. Ayarlar (bildirim
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
            _Section(icon: AppIcons.info, title: l10n.drawerDataSources, body: l10n.dataSourcesBody),
          ],
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
