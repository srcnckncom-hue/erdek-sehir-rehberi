import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Sekme sayfalarının üst başlığı (görselde karşılığı yok; ana sayfa
/// bölüm başlığı stiline uygun: büyük Poppins Bold + ikincil alt satır).
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.backLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Verilirse başlığın üstünde yuvarlak "geri" düğmesi çizilir
  /// (sekme dışında açılan sayfalar: Gezilecek Yerler, Erdek Tarihi).
  final VoidCallback? onBack;
  final String? backLabel;

  /// Geri düğmesinin anahtarı (testler için).
  static const backKey = ValueKey('page-header-back');

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
                if (onBack != null) ...[
                  _BackButton(key: PageHeader.backKey, onTap: onBack!, label: backLabel),
                  const SizedBox(height: AppSpacing.md),
                ],
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

class _BackButton extends StatelessWidget {
  const _BackButton({super.key, required this.onTap, this.label});

  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: AppSpacing.minTouchTarget,
            child: Center(child: AppIcon(AppIcons.caretLeft, size: 22, color: p.textHeading)),
          ),
        ),
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
      // Şeffaf Material: içteki ListTile / InkWell dokunma efektleri beyaz
      // zeminin üstünde görünsün (yoksa Flutter uyarı verir, efekt kaybolur).
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppRadius.tileAll,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg, color: p.divider),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
