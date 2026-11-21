import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Ana sayfadaki hap biçimli arama kutusu. Dokununca arama ekranı açılır
/// (kendisi metin girişi almaz).
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({super.key, required this.hint, this.onTap});

  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: hint,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: AppRadius.pillAll,
          boxShadow: AppShadows.raised(p.shadow),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.pillAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.searchHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    AppIcon(AppIcons.search, size: 20, color: p.textSecondary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        hint,
                        style: AppTypography.body.copyWith(color: p.textSecondary, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
