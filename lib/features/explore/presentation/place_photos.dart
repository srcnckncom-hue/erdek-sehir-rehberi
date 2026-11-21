import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/explore.dart';
import 'place_style.dart';

/// Fotoğraf yoksa ya da yüklenemezse: tür ikonu (renkli zemin).
class PlaceIconTile extends StatelessWidget {
  const PlaceIconTile({
    super.key,
    required this.category,
    this.iconSize = 32,
    this.caption,
  });

  final PlaceCategory category;
  final double iconSize;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = PlaceStyle.color(p, category);
    return ColoredBox(
      color: color.withValues(alpha: 0.12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(PlaceStyle.icon(category), size: iconSize, color: color),
            if (caption case final text?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(text, style: AppTypography.caption.copyWith(color: p.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

/// İnternetten fotoğraf; yüklenirken ve hata olursa [fallback].
class PlacePhotoImage extends StatelessWidget {
  const PlacePhotoImage({
    super.key,
    required this.url,
    required this.fallback,
    this.semanticLabel,
  });

  final String url;
  final Widget fallback;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        fallback,
        Image.network(
          url,
          fit: BoxFit.cover,
          semanticLabel: semanticLabel,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Ayrıntı sayfasının üstündeki fotoğraf alanı: kaydırılabilir galeri,
/// birden çok fotoğrafta noktalar, altında "Fotoğraf: …" (varsa).
/// Fotoğraf yoksa tür ikonu + "Fotoğraf yakında".
class PlacePhotoGallery extends StatefulWidget {
  const PlacePhotoGallery({super.key, required this.place});

  final Place place;

  @override
  State<PlacePhotoGallery> createState() => _PlacePhotoGalleryState();
}

class _PlacePhotoGalleryState extends State<PlacePhotoGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final place = widget.place;
    final photos = place.photos;

    if (photos.isEmpty) {
      return Padding(
        padding: AppSpacing.pagePadding,
        child: ClipRRect(
          borderRadius: AppRadius.cardAll,
          child: SizedBox(
            height: 180,
            child: PlaceIconTile(
              category: place.category,
              iconSize: 56,
              caption: l10n.placePhotoSoon,
            ),
          ),
        ),
      );
    }

    final fallback = PlaceIconTile(category: place.category, iconSize: 56);
    final credit = photos[_page.clamp(0, photos.length - 1)].credit;
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => PlacePhotoImage(
                      url: photos[i].url,
                      fallback: fallback,
                      semanticLabel: l10n.placePhotoLabel(place.title),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: AppSpacing.md,
                      child: IgnorePointer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < photos.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _page ? 18 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: i == _page ? 1 : 0.6),
                                  borderRadius: AppRadius.pillAll,
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x33000000), blurRadius: 4),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (credit != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.placePhotoCredit(credit),
              style: AppTypography.caption.copyWith(color: p.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
