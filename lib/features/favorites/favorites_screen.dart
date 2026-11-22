import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../nearby/nearby_screen.dart';
import '../nearby/points.dart';
import 'favorites.dart';

Future<void> openFavorites(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
    );

/// Yıldız düğmesi (ayrıntı sayfalarının başlığında, eczane kartında).
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.favoriteKey, this.size = AppSpacing.minTouchTarget});

  /// FavoriteKeys.business(...) vb.
  final String favoriteKey;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final on = ref.watch(favoritesProvider).contains(favoriteKey);
    return Semantics(
      button: true,
      toggled: on,
      label: on ? l10n.favoriteRemove : l10n.favoriteAdd,
      excludeSemantics: true,
      child: InkResponse(
        key: Key('fav_$favoriteKey'),
        radius: size / 2,
        onTap: () async {
          final messenger = ScaffoldMessenger.maybeOf(context);
          final added = await ref.read(favoritesProvider.notifier).toggle(favoriteKey);
          messenger
            ?..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(added ? l10n.favoriteAdded : l10n.favoriteRemoved)));
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: on ? p.iconOrange.withValues(alpha: 0.14) : p.surfaceMuted,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: AppIcon(
            on ? AppIcons.favoriteOn : AppIcons.favoriteOff,
            size: size * 0.5,
            color: on ? p.iconOrange : p.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Favorilerim: işletme, gezilecek yer ve eczaneler. Dokun → ayrıntı.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final items = ref.watch(favoriteItemsProvider(l10n.favoritePharmacyOnDuty));

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: l10n.favoritesTitle,
            subtitle: items.isEmpty ? null : l10n.favoritesCount(items.length),
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          if (items.isEmpty)
            MessageView(
              key: const Key('favorites_empty'),
              icon: AppIcons.favoriteOn,
              iconColor: p.iconOrange,
              title: l10n.favoritesEmptyTitle,
              message: l10n.favoritesEmptyMessage,
            )
          else
            GroupedCard(
              children: [for (final item in items) _FavoriteRow(item: item)],
            ),
        ],
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({required this.item});

  final PointOfInterest item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (icon, color) = switch (item.kind) {
      PointKind.business => (AppIcons.businesses, p.iconOrange),
      PointKind.place => (AppIcons.places, p.aqua.foreground),
      PointKind.pharmacy => (AppIcons.pill, p.accentRed),
      PointKind.service => (AppIcons.places, p.primary),
    };
    return InkWell(
      key: Key('favorite_row_${item.id}'),
      onTap: () => unawaited(openPoint(context, item)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: AppIcon(icon, size: 22, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppTypography.label.copyWith(color: p.textHeading)),
                  if (item.subtitle case final s? when s.isNotEmpty)
                    Text(
                      s,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: p.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FavoriteButton(favoriteKey: item.id, size: 36),
          ],
        ),
      ),
    );
  }
}
