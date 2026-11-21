import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/explore.dart';
import 'place_photos.dart';
import 'place_style.dart';

Future<void> openPlace(BuildContext context, Place place, {bool isSample = false}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaceDetailScreen(place: place, isSample: isSample),
      ),
    );

/// Bir yerin ayrıntı sayfası: fotoğraf galerisi, özet, metin, ipuçları, yol tarifi.
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key, required this.place, this.isSample = false});

  final Place place;
  final bool isSample;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: place.title,
            subtitle: PlaceStyle.meta(l10n, place),
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          if (isSample) ...[
            InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
            const SizedBox(height: AppSpacing.md),
          ],
          // Fotoğraflar (panelden yüklenir); yoksa tür ikonu + "Fotoğraf yakında".
          PlacePhotoGallery(place: place),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.summary,
                  style: AppTypography.label.copyWith(color: p.textHeading),
                ),
                for (final paragraph in place.paragraphs) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    paragraph,
                    style: AppTypography.body.copyWith(color: p.textBody, height: 1.6),
                  ),
                ],
              ],
            ),
          ),
          if (place.tips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _TipsCard(tips: place.tips),
          ],
          if (place.hasLocation) ...[
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (place.address != null) ...[
                    Row(
                      children: [
                        AppIcon(AppIcons.mapPin, size: 20, color: p.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            place.address!,
                            style: AppTypography.caption.copyWith(color: p.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  FilledButton.icon(
                    onPressed: () => launchOrNotify(
                      context,
                      () => Launchers.directions(
                        name: place.title,
                        address: place.address,
                        latitude: place.latitude,
                        longitude: place.longitude,
                      ),
                    ),
                    icon: AppIcon(AppIcons.directions, size: 18, color: p.onPrimary),
                    label: Text(l10n.directions),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Container(
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.cardAll,
        boxShadow: AppShadows.card(p.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(AppIcons.lightbulb, size: 22, color: p.iconOrange),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.placeTipsTitle,
                  style: AppTypography.label.copyWith(
                    color: p.textHeading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          for (final tip in tips) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: AppSpacing.sm),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: p.iconOrange, shape: BoxShape.circle),
                  ),
                ),
                Expanded(
                  child: Text(tip, style: AppTypography.caption.copyWith(color: p.textBody)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
