import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Sekme sayfalarının üst başlığı (görselde karşılığı yok; ana sayfa
/// bölüm başlığı stiline uygun: büyük Poppins Bold + ikincil alt satır).
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final topInset = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        topInset + AppSpacing.md,
        AppSpacing.page,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: AppTypography.pageTitle.copyWith(color: p.textHeading)),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Beyaz, gölgeli, yuvarlak köşeli grup kutusu (satır listeleri için).
class GroupedCard extends StatelessWidget {
  const GroupedCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: AppSpacing.pagePadding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.tileAll,
        boxShadow: AppShadows.card(p.shadow),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg, color: p.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}
