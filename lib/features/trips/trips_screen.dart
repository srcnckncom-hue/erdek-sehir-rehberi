import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/launch_or_notify.dart';
import '../../core/util/launchers.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../explore/presentation/place_photos.dart';
import '../share/share_actions.dart';
import 'trips.dart';

Future<void> openTrips(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TripsScreen()),
    );

Future<void> openTrip(BuildContext context, TripRoute trip) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TripDetailScreen(trip: trip)),
    );

abstract final class TripStyle {
  static AppIconData icon(TripType t) => switch (t) {
        TripType.walk => AppIcons.tripWalk,
        TripType.bike => AppIcons.tripBike,
        TripType.boat => AppIcons.ferry,
        TripType.car => AppIcons.bizCar,
        TripType.culture => AppIcons.history,
      };

  static Color color(AppPalette p, TripType t) => switch (t) {
        TripType.walk => p.mint.foreground,
        TripType.bike => p.iconOrange,
        TripType.boat => p.aqua.foreground,
        TripType.car => p.iconBlue,
        TripType.culture => p.iconPurple,
      };

  static String label(AppLocalizations l10n, TripType t) => switch (t) {
        TripType.walk => l10n.tripWalk,
        TripType.bike => l10n.tripBike,
        TripType.boat => l10n.tripBoat,
        TripType.car => l10n.tripCar,
        TripType.culture => l10n.tripCulture,
      };

  static String? difficulty(AppLocalizations l10n, TripDifficulty? d) => switch (d) {
        TripDifficulty.easy => l10n.tripEasy,
        TripDifficulty.medium => l10n.tripMedium,
        TripDifficulty.hard => l10n.tripHard,
        null => null,
      };

  /// "6,5 km · 2 sa 30 dk · Orta"
  static String stats(AppLocalizations l10n, TripRoute t) => [
        if (t.distanceKm case final km?) '${km.toStringAsFixed(km % 1 == 0 ? 0 : 1).replaceAll('.', ',')} km',
        if (t.durationMin case final m?) m >= 60 ? l10n.tripHoursMinutes(m ~/ 60, m % 60) : l10n.tripMinutes(m),
        ?difficulty(l10n, t.difficulty),
      ].join(' · ');
}

/// Gezi rotaları: türe göre süzgeç.
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  TripType? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final result = ref.watch(tripsDataProvider);
    final data = result.value?.data;
    final types = data?.types() ?? const <TripType>[];
    final filter = types.contains(_filter) ? _filter : null;
    final shown = [for (final t in data?.trips ?? const <TripRoute>[]) if (filter == null || t.type == filter) t];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: l10n.tripsTitle,
            subtitle: l10n.tripsSubtitle,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          if (result.value?.isSample ?? false) ...[
            InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
            const SizedBox(height: AppSpacing.md),
          ],
          if (types.length > 1) ...[
            PillChoiceRow(
              key: const Key('trips_filter'),
              items: [
                PillChoice(
                  label: l10n.eventsAll(data!.trips.length),
                  selected: filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final t in types)
                  PillChoice(
                    label: TripStyle.label(l10n, t),
                    selected: filter == t,
                    onTap: () => setState(() => _filter = t),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (data == null && !result.hasError)
            const Padding(padding: AppSpacing.pagePadding, child: SkeletonBox(height: 120, radius: AppRadius.card))
          else if (shown.isEmpty)
            MessageView(
              key: const Key('trips_empty'),
              icon: AppIcons.trips,
              iconColor: p.mint.foreground,
              title: l10n.tripsEmptyTitle,
              message: l10n.tripsEmptyMessage,
            )
          else
            for (final t in shown) ...[
              _TripCard(trip: t),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final TripRoute trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final color = TripStyle.color(p, trip.type);
    final icon = ColoredBox(
      color: color.withValues(alpha: 0.12),
      child: Center(child: AppIcon(TripStyle.icon(trip.type), size: 30, color: color)),
    );
    final stats = TripStyle.stats(l10n, trip);
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Material(
        color: p.surface,
        borderRadius: AppRadius.cardAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('trip_${trip.id}'),
          onTap: () => openTrip(context, trip),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.tileAll,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: trip.photos.isEmpty ? icon : PlacePhotoImage(url: trip.photos.first.url, fallback: icon),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.title, style: AppTypography.label.copyWith(color: p.textHeading)),
                      Text(
                        trip.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: p.textBody),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        [TripStyle.label(l10n, trip.type), if (stats.isNotEmpty) stats].join(' · '),
                        style: AppTypography.tabLabel.copyWith(color: color, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                AppIcon(AppIcons.arrowRight, size: 18, color: p.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rota haritası: iOS'ta Apple Haritalar (numaralı duraklar + çizgi), diğerlerinde gösterilmez.
class TripMap extends StatelessWidget {
  const TripMap({super.key, required this.trip});

  final TripRoute trip;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return const SizedBox.shrink();
    final stops = trip.stops;
    return Padding(
      padding: AppSpacing.pagePadding,
      child: ClipRRect(
        borderRadius: AppRadius.cardAll,
        child: SizedBox(
          height: 260,
          child: UiKitView(
            viewType: 'erdek/map',
            creationParams: {
              'pins': [
                for (var i = 0; i < stops.length; i++)
                  if (stops[i].location case final loc?)
                    {
                      'id': 'stop:${i + 1}',
                      'kind': 'stop',
                      'title': stops[i].name,
                      'subtitle': stops[i].note,
                      'lat': loc.latitude,
                      'lng': loc.longitude,
                    },
              ],
              'path': [for (final pt in trip.line) [pt.latitude, pt.longitude]],
              'fit': true,
            },
            creationParamsCodec: const StandardMessageCodec(),
          ),
        ),
      ),
    );
  }
}

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.trip});

  final TripRoute trip;

  String _shareText(AppLocalizations l10n) => [
        trip.title,
        trip.summary,
        if (TripStyle.stats(l10n, trip) case final s when s.isNotEmpty) s,
        if (trip.stops.isNotEmpty) l10n.tripStopsLine(trip.stops.map((s) => s.name).join(' → ')),
        ?trip.directionsUrl(),
        '— ${l10n.appTitle}',
      ].join('\n');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final t = trip;
    final color = TripStyle.color(p, t.type);
    final stats = TripStyle.stats(l10n, t);
    final directions = t.directionsUrl();
    final cover = t.photos.firstOrNull;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: t.title,
            subtitle: [TripStyle.label(l10n, t.type), if (stats.isNotEmpty) stats].join(' · '),
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          if (cover != null) ...[
            Padding(
              padding: AppSpacing.pagePadding,
              child: ClipRRect(
                borderRadius: AppRadius.cardAll,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: PlacePhotoImage(
                    url: cover.url,
                    fallback: ColoredBox(color: color.withValues(alpha: 0.12)),
                    semanticLabel: l10n.placePhotoLabel(t.title),
                  ),
                ),
              ),
            ),
            if (cover.credit case final c?)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, 0),
                child: Text(l10n.placePhotoCredit(c), style: AppTypography.tabLabel.copyWith(color: p.textSecondary)),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (t.hasMap) ...[
            TripMap(trip: t),
            const SizedBox(height: AppSpacing.md),
          ],
          Padding(
            padding: AppSpacing.pagePadding,
            child: Row(
              children: [
                if (directions != null) ...[
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('trip_directions'),
                      onPressed: () => unawaited(launchOrNotify(context, () => Launchers.openUrl(directions))),
                      icon: AppIcon(AppIcons.directions, size: 18, color: p.onPrimary),
                      label: Text(l10n.tripOpenInMaps, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('trip_share'),
                    onPressed: () => unawaited(shareToWhatsApp(ref, _shareText(l10n))),
                    icon: AppIcon(AppIcons.whatsapp, size: 18, color: p.primary),
                    label: Text(l10n.shareWhatsApp, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.summary, style: AppTypography.body.copyWith(color: p.textHeading, fontWeight: FontWeight.w600)),
                for (final para in t.paragraphs) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(para, style: AppTypography.body.copyWith(color: p.textBody)),
                ],
                if (t.season case final s?) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.tripSeason(s), style: AppTypography.caption.copyWith(color: p.textSecondary)),
                ],
              ],
            ),
          ),
          if (t.stops.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            SectionHeader(title: l10n.tripStops(t.stops.length)),
            const SizedBox(height: AppSpacing.md),
            GroupedCard(
              children: [
                for (var i = 0; i < t.stops.length; i++)
                  ListTile(
                    key: Key('trip_stop_$i'),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: color,
                      child: Text('${i + 1}', style: AppTypography.tabLabel.copyWith(color: Colors.white)),
                    ),
                    title: Text(t.stops[i].name, style: AppTypography.label.copyWith(color: p.textHeading)),
                    subtitle: t.stops[i].note == null
                        ? null
                        : Text(t.stops[i].note!, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                    trailing: t.stops[i].location == null
                        ? null
                        : IconButton(
                            tooltip: l10n.directions,
                            icon: AppIcon(AppIcons.directions, size: 20, color: p.primary),
                            onPressed: () => unawaited(launchOrNotify(
                              context,
                              () => Launchers.directions(
                                name: t.stops[i].name,
                                latitude: t.stops[i].location!.latitude,
                                longitude: t.stops[i].location!.longitude,
                              ),
                            )),
                          ),
                  ),
              ],
            ),
          ],
          if (t.tips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            SectionHeader(title: l10n.tripTips),
            const SizedBox(height: AppSpacing.md),
            GroupedCard(
              children: [
                for (final tip in t.tips)
                  ListTile(
                    leading: AppIcon(AppIcons.info, size: 20, color: p.iconOrange),
                    title: Text(tip, style: AppTypography.caption.copyWith(color: p.textBody)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Text(l10n.tripSafetyNote, style: AppTypography.tabLabel.copyWith(color: p.textSecondary)),
          ),
        ],
      ),
    );
  }
}
