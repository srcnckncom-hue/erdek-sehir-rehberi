import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Geniş renkli kısayol kartı (görselde "Ödemeler / Başvurular / Randevu").
class QuickActionChip extends StatelessWidget {
  const QuickActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.tone,
    this.onTap,
  });

  final AppIconData icon;
  final String label;
  final ToneColors tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: tone.background,
        borderRadius: AppRadius.chipAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.chipAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.chipHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  AppIcon(icon, size: 24, color: tone.foreground),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      // 14: küçük ekranda (SE) "Nöbetçi Eczane" tek satıra sığsın.
                      style: AppTypography.label.copyWith(color: p.textBody, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Beyaz kare kısayol kutucuğu (ikon + iki satırlık etiket).
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    this.onTap,
  });

  final AppIconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: AppRadius.tileAll,
          boxShadow: AppShadows.card(p.shadow),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.tileAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.tileHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(icon, size: 28, color: iconColor),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      label,
                      style: AppTypography.tileLabel.copyWith(color: p.textBody),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

/// Çocukları [columns] sütunlu satırlara dizer (eşit genişlik, 8 pt boşluk).
/// GridView yerine: satır yüksekliği içeriğe göre büyüyebilsin (Dynamic Type).
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.skip(i).take(columns).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: AppSpacing.gap),
                Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
              ],
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: AppSpacing.gap),
            rows[r],
          ],
        ],
      ),
    );
  }
}
