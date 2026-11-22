import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../explore/data/explore_repository.dart';
import '../explore/domain/explore.dart';
import '../explore/presentation/place_detail_screen.dart';
import '../explore/presentation/places_screen.dart';
import 'swim_score.dart';

Future<void> openBeaches(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BeachesScreen()),
    );

abstract final class AmenityStyle {
  static AppIconData icon(BeachAmenity a) => switch (a) {
        BeachAmenity.blueFlag => AppIcons.amenityFlag,
        BeachAmenity.lifeguard => AppIcons.amenityLifeguard,
        BeachAmenity.shower => AppIcons.amenityShower,
        BeachAmenity.wc => AppIcons.amenityWc,
        BeachAmenity.sunbeds => AppIcons.placeBeach,
        BeachAmenity.parking => AppIcons.bizCar,
        BeachAmenity.accessible => AppIcons.amenityAccessible,
        BeachAmenity.shallow => AppIcons.amenityShallow,
        BeachAmenity.food => AppIcons.bizFood,
        BeachAmenity.sand || BeachAmenity.pebble => AppIcons.check,
      };

  static String label(AppLocalizations l10n, BeachAmenity a) => switch (a) {
        BeachAmenity.blueFlag => l10n.amenityBlueFlag,
        BeachAmenity.lifeguard => l10n.amenityLifeguard,
        BeachAmenity.shower => l10n.amenityShower,
        BeachAmenity.wc => l10n.amenityWc,
        BeachAmenity.sunbeds => l10n.amenitySunbeds,
        BeachAmenity.parking => l10n.amenityParking,
        BeachAmenity.accessible => l10n.amenityAccessible,
        BeachAmenity.shallow => l10n.amenityShallow,
        BeachAmenity.sand => l10n.amenitySand,
        BeachAmenity.pebble => l10n.amenityPebble,
        BeachAmenity.food => l10n.amenityFood,
      };
}

/// Plaj olanakları (küçük etiketler). Yer ayrıntısında ve plaj listesinde.
class BeachAmenityChips extends StatelessWidget {
  const BeachAmenityChips({super.key, required this.amenities});

  final List<BeachAmenity> amenities;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final a in amenities)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: a == BeachAmenity.blueFlag ? p.iconBlue.withValues(alpha: 0.14) : p.surfaceMuted,
              borderRadius: AppRadius.pillAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(AmenityStyle.icon(a), size: 14, color: a == BeachAmenity.blueFlag ? p.iconBlue : p.textSecondary),
                const SizedBox(width: AppSpacing.xxs),
                Text(AmenityStyle.label(l10n, a), style: AppTypography.tabLabel.copyWith(color: p.textBody)),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Bugün denize girilir mi?" kartı (puan, sonuç, etkenler).
class SwimScoreCard extends ConsumerWidget {
  const SwimScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final s = ref.watch(todaySwimScoreProvider);
    if (s == null) return const SizedBox.shrink();

    final (Color color, String verdict) = switch (s.level) {
      SwimLevel.great => (p.mint.foreground, l10n.swimGreat),
      SwimLevel.good => (p.iconBlue, l10n.swimGood),
      SwimLevel.fair => (p.iconOrange, l10n.swimFair),
      SwimLevel.poor => (p.accentRed, l10n.swimPoor),
    };
    String num1(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
    String factorText(SwimFactor f) => switch (f.kind) {
          SwimFactorKind.water => l10n.swimFactorWater('${f.value!.round()}'),
          SwimFactorKind.air => l10n.swimFactorAir('${f.value!.round()}'),
          SwimFactorKind.wave => l10n.swimFactorWave(num1(f.value!)),
          SwimFactorKind.wind => l10n.swimFactorWind('${f.value!.round()}'),
          SwimFactorKind.rain => l10n.swimFactorRain,
          SwimFactorKind.storm => l10n.swimFactorStorm,
        };
    Color statusColor(SwimFactorStatus st) => switch (st) {
          SwimFactorStatus.ok => p.mint.foreground,
          SwimFactorStatus.warn => p.iconOrange,
          SwimFactorStatus.bad => p.accentRed,
        };

    return Container(
      key: const Key('swim_score'),
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: AppRadius.cardAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: s.score / 100,
                      strokeWidth: 5,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.18),
                    ),
                    Text('${s.score}', style: AppTypography.label.copyWith(color: p.textHeading)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.swimQuestion, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                    Text(verdict, style: AppTypography.cardTitle.copyWith(color: color)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final f in s.factors)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(color: p.surface, borderRadius: AppRadius.pillAll),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: statusColor(f.status), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(factorText(f), style: AppTypography.tabLabel.copyWith(color: p.textBody)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            s.waterKnown ? l10n.swimNote : l10n.swimNoteNoSea,
            style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Plajlar: bugünün yüzme puanı + plajlar (olanaklarla, süzgeçli).
class BeachesScreen extends ConsumerStatefulWidget {
  const BeachesScreen({super.key});

  @override
  ConsumerState<BeachesScreen> createState() => _BeachesScreenState();
}

class _BeachesScreenState extends ConsumerState<BeachesScreen> {
  BeachAmenity? _filter;

  static const _filters = [BeachAmenity.blueFlag, BeachAmenity.shallow, BeachAmenity.parking, BeachAmenity.lifeguard];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final result = ref.watch(placesDataProvider);
    final beaches = [
      for (final pl in result.value?.data.places ?? const <Place>[])
        if (pl.category == PlaceCategory.beach) pl,
    ];
    final available = [for (final f in _filters) if (beaches.any((b) => b.amenities.contains(f))) f];
    final filter = available.contains(_filter) ? _filter : null;
    final shown = [for (final b in beaches) if (filter == null || b.amenities.contains(filter)) b];
    final sample = result.value?.isSample ?? false;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: l10n.beachesTitle,
            subtitle: l10n.beachesSubtitle,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          const SwimScoreCard(),
          const SizedBox(height: AppSpacing.section),
          if (sample) ...[
            InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
            const SizedBox(height: AppSpacing.md),
          ],
          if (available.isNotEmpty) ...[
            PillChoiceRow(
              key: const Key('beaches_filter'),
              items: [
                PillChoice(
                  label: l10n.eventsAll(beaches.length),
                  selected: filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final f in available)
                  PillChoice(
                    label: AmenityStyle.label(l10n, f),
                    selected: filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (result.value == null && !result.hasError)
            const Padding(padding: AppSpacing.pagePadding, child: SkeletonBox(height: 120, radius: AppRadius.card))
          else if (shown.isEmpty)
            MessageView(icon: AppIcons.placeBeach, iconColor: p.aqua.foreground, title: l10n.beachesEmpty)
          else
            for (final b in shown) ...[
              PlaceCard(place: b, onTap: () => openPlace(context, b, isSample: sample)),
              if (b.amenities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, 0),
                  child: BeachAmenityChips(amenities: b.amenities),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}
