import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

class TabItem {
  const TabItem({required this.label, required this.icon});

  final String label;

  /// Aktif/pasif ikon (AppIcons.tabXxx).
  final IconData Function({required bool active}) icon;
}

/// Buzlu cam alt menü. Aktif sekme: %10 mavi zemin + mavi ikon/etiket +
/// alt çizgi (görseldeki "Ana Sayfa" sekmesi).
class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<TabItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.tabBar,
            border: Border(top: BorderSide(color: p.divider.withValues(alpha: 0.6))),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              bottomInset > 0 ? bottomInset : AppSpacing.sm,
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _TabButton(
                      item: items[i],
                      active: i == currentIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.item, required this.active, required this.onTap});

  final TabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.primary : p.textSecondary;
    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.tileAll,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          decoration: BoxDecoration(
            color: active ? p.primarySoft : Colors.transparent,
            borderRadius: AppRadius.tileAll,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(item.icon(active: active), size: 26, color: color),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: AppTypography.tabLabel.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 40 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
