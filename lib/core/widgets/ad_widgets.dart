import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Tüm reklamlarda zorunlu küçük "Reklam" etiketi
/// (App Store ve tüketici mevzuatı gereği içerikten ayırt edilebilirlik).
class AdLabel extends StatelessWidget {
  const AdLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: const BoxDecoration(
        color: Color(0x99000000),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        text,
        style: AppTypography.tabLabel.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Kart formatlı yerel reklam (`home_feed_1` gibi slotlar).
/// Görsel oranı 2:1 — admin panelinde yükleme rehberi: 1200×600 px.
/// Veriyi AdSlot (features/ads) sağlar; bu yalnızca görünüm.
class AdCard extends StatelessWidget {
  const AdCard({
    super.key,
    required this.image,
    required this.title,
    required this.adLabel,
    this.subtitle,
    this.onTap,
  });

  static const imageAspectRatio = 2.0;

  final ImageProvider image;
  final String title;
  final String? subtitle;

  /// "Reklam"
  final String adLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: '$adLabel: $title',
      button: onTap != null,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: AppRadius.tileAll,
          boxShadow: AppShadows.card(p.shadow),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.tileAll,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: imageAspectRatio,
                        child: Image(
                          image: image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(color: p.surfaceMuted),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.sm,
                        top: AppSpacing.sm,
                        child: AdLabel(text: adLabel),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.label.copyWith(
                            color: p.textBody,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppTypography.caption.copyWith(color: p.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
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
