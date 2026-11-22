import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/launch_or_notify.dart';
import '../../core/util/launchers.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../businesses/presentation/business_detail_screen.dart';
import '../explore/presentation/place_detail_screen.dart';
import 'location_service.dart';
import 'points.dart';

Future<void> openNearby(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NearbyScreen()),
    );

/// Bir yeri açar: işletme / gezilecek yer ayrıntısı; eczane için ara + yol tarifi.
Future<void> openPoint(BuildContext context, PointOfInterest point) async {
  switch (point.kind) {
    case PointKind.business:
      await openBusiness(context, point.business!, category: point.businessCategory);
    case PointKind.place:
      await openPlace(context, point.place!);
    case PointKind.pharmacy:
      final pharmacy = point.pharmacy!;
      final l10n = AppLocalizations.of(context);
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(pharmacy.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(pharmacy.address),
              ),
              ListTile(
                leading: AppIcon(AppIcons.call, size: 24, color: sheetContext.palette.mint.foreground),
                title: Text(l10n.call),
                subtitle: Text(Launchers.formatPhone(pharmacy.phone)),
                onTap: () => launchOrNotify(sheetContext, () => Launchers.call(pharmacy.phone)),
              ),
              ListTile(
                leading: AppIcon(AppIcons.directions, size: 24, color: sheetContext.palette.primary),
                title: Text(l10n.directions),
                onTap: () => launchOrNotify(
                  sheetContext,
                  () => Launchers.directions(
                    name: pharmacy.name,
                    address: pharmacy.address,
                    latitude: pharmacy.latitude,
                    longitude: pharmacy.longitude,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

/// Yakınımdakiler: konumu bir kez alır, yerleri yakından uzağa sıralar.
class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  GeoPoint? _here;
  LocationFailure? _failure;
  bool _loading = true;
  PointKind? _filter;

  @override
  void initState() {
    super.initState();
    // İlk konum isteği ilk kare çizildikten sonra (initState içinde setState olmaz).
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  Future<void> _locate() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final here = await ref.read(locationServiceProvider).current();
      if (!mounted) return;
      setState(() {
        _here = here;
        _loading = false;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _failure = e.failure;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final here = _here;

    final children = <Widget>[
      PageHeader(
        title: l10n.nearbyTitle,
        subtitle: l10n.nearbySubtitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.back,
      ),
    ];

    if (_loading) {
      children.add(const SkeletonList(count: 5, itemHeight: 64));
    } else if (here == null) {
      final denied = _failure == LocationFailure.denied;
      children.add(
        MessageView(
          icon: AppIcons.nearby,
          iconColor: p.iconOrange,
          title: denied ? l10n.nearbyDeniedTitle : l10n.nearbyUnavailableTitle,
          message: denied ? l10n.nearbyDeniedMessage : l10n.nearbyUnavailableMessage,
          actionLabel: l10n.retry,
          onAction: _locate,
        ),
      );
    } else {
      final all = ref.watch(pointsProvider(l10n.mapPharmacyLabel));
      final filtered = [for (final x in all) if (_filter == null || x.kind == _filter) x];
      final sorted = sortByDistance(filtered, here);
      final filters = <(PointKind?, String)>[
        (null, l10n.filterAll),
        (PointKind.pharmacy, l10n.mapFilterPharmacy),
        (PointKind.business, l10n.mapFilterBusinesses),
        (PointKind.place, l10n.mapFilterPlaces),
      ];
      children
        ..add(InfoBanner(icon: AppIcons.info, message: l10n.nearbyPrivacyNote))
        ..add(const SizedBox(height: AppSpacing.md))
        ..add(
          PillChoiceRow(
            key: const Key('nearby_filter'),
            semanticsLabel: l10n.nearbyTitle,
            items: [
              for (final (kind, label) in filters)
                PillChoice(label: label, selected: _filter == kind, onTap: () => setState(() => _filter = kind)),
            ],
          ),
        )
        ..add(const SizedBox(height: AppSpacing.lg));

      if (sorted.isEmpty) {
        children.add(MessageView(icon: AppIcons.nearby, title: l10n.nearbyEmpty));
      } else {
        children.add(
          GroupedCard(
            children: [
              for (final (point, meters) in sorted.take(40))
                _NearbyRow(point: point, meters: meters, onTap: () => openPoint(context, point)),
            ],
          ),
        );
      }
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _locate,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
          children: children,
        ),
      ),
    );
  }
}

class _NearbyRow extends StatelessWidget {
  const _NearbyRow({required this.point, required this.meters, required this.onTap});

  final PointOfInterest point;
  final double? meters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final (icon, color) = switch (point.kind) {
      PointKind.pharmacy => (AppIcons.pharmacy, p.accentRed),
      PointKind.business => (AppIcons.businesses, p.iconOrange),
      PointKind.place => (AppIcons.places, p.iconBlue),
    };
    final distance = meters == null ? l10n.nearbyNoLocation : formatDistance(meters!);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            AppIcon(icon, size: 24, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(color: p.textHeading),
                  ),
                  if (point.subtitle != null)
                    Text(
                      point.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: p.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              distance,
              style: AppTypography.caption.copyWith(
                color: meters == null ? p.textSecondary : p.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
