import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// "▌ Hızlı İşlemlerim            Tümünü Gör →"
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// Soldaki çubuğun rengi (varsayılan ana mavi; "Şehir Hizmetleri"nde kırmızı).
  final Color? accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Row(
        children: [
          Container(
            width: 5,
            height: 19,
            decoration: BoxDecoration(
              color: accentColor ?? p.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AppTypography.sectionTitle.copyWith(color: p.textHeading),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (actionLabel != null)
            InkWell(
              onTap: onAction,
              borderRadius: AppRadius.pillAll,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: AppTypography.label.copyWith(color: p.primary),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      AppIcon(AppIcons.arrowRight, size: 18, color: p.primary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
