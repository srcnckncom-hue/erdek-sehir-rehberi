import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Segment seçeneği (ikon + etiket).
class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final AppIconData? icon;
}

/// Hap biçimli segment anahtarı: gri zemin, seçili seçenek beyaz + gölgeli.
/// (Ulaşım: Feribot / Otobüs / Şehir İçi · Rehber: Telefonlar / Duyurular)
class SegmentedPills<T> extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: AppRadius.pillAll),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                selected: option.value == selected,
                button: true,
                label: option.label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(option.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: option.value == selected ? p.surface : Colors.transparent,
                      borderRadius: AppRadius.pillAll,
                      boxShadow: option.value == selected ? AppShadows.card(p.shadow) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (option.icon != null) ...[
                          AppIcon(
                            option.icon!,
                            size: 20,
                            color: option.value == selected ? p.primary : p.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                        ],
                        Flexible(
                          child: Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.tileLabel.copyWith(
                              color: option.value == selected ? p.primary : p.textSecondary,
                              fontWeight: option.value == selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Yatay kaydırılan seçim hapları (hat, gün, duyuru kategorisi).
class PillChoice {
  const PillChoice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;
}

class PillChoiceRow extends StatelessWidget {
  const PillChoiceRow({super.key, required this.items, this.semanticsLabel});

  final List<PillChoice> items;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: SizedBox(
        height: AppSpacing.minTouchTarget,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: AppSpacing.pagePadding,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) {
            final item = items[i];
            return Semantics(
              selected: item.selected,
              button: true,
              child: Material(
                color: item.selected ? p.primary : p.surface,
                borderRadius: AppRadius.pillAll,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: AppRadius.pillAll,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.pillAll,
                      border: item.selected ? null : Border.all(color: p.divider),
                    ),
                    child: Text(
                      item.label,
                      style: AppTypography.tileLabel.copyWith(
                        color: item.selected ? p.onPrimary : p.textBody,
                        fontWeight: item.selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
