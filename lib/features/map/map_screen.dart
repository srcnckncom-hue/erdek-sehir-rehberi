import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../nearby/location_service.dart';
import '../nearby/nearby_screen.dart';
import '../nearby/points.dart';

Future<void> openMap(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MapScreen()),
    );

/// Erdek haritası (Apple Haritalar): nöbetçi eczane, işletmeler, gezilecek yerler.
/// Balondaki (i) düğmesi ayrıntıyı açar. iOS dışında (testler) liste gösterilir.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  PointKind? _filter;
  MethodChannel? _channel;
  List<PointOfInterest> _shown = const [];

  bool get _nativeMap => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  List<PointOfInterest> _visible(List<PointOfInterest> all) => [
        for (final p in all)
          if (p.location != null && (_filter == null || p.kind == _filter)) p,
      ];

  void _onCreated(int id) {
    final channel = MethodChannel('erdek/map_$id');
    channel.setMethodCallHandler((call) async {
      if (call.method != 'select' || !mounted) return;
      final selected = _shown.where((p) => p.id == call.arguments).firstOrNull;
      if (selected != null) await openPoint(context, selected);
    });
    _channel = channel;
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final all = ref.watch(pointsProvider(l10n.mapPharmacyLabel));
    final shown = _visible(all);

    // Veri ya da süzgeç değişince haritadaki iğneleri yenile.
    final channel = _channel;
    if (channel != null && !listEquals(shown.map((e) => e.id).toList(), _shown.map((e) => e.id).toList())) {
      final pins = [for (final s in shown) s.toPin()];
      WidgetsBinding.instance.addPostFrameCallback((_) => channel.invokeMethod<void>('setPins', pins));
    }
    _shown = shown;

    final filters = <(PointKind?, String)>[
      (null, l10n.filterAll),
      (PointKind.pharmacy, l10n.mapFilterPharmacy),
      (PointKind.business, l10n.mapFilterBusinesses),
      (PointKind.place, l10n.mapFilterPlaces),
    ];

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: l10n.mapTitle,
            subtitle: l10n.mapSubtitle(shown.length),
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          PillChoiceRow(
            key: const Key('map_filter'),
            semanticsLabel: l10n.mapTitle,
            items: [
              for (final (kind, label) in filters)
                PillChoice(
                  label: label,
                  selected: _filter == kind,
                  onTap: () => setState(() => _filter = kind),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                MediaQuery.paddingOf(context).bottom + AppSpacing.md,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.cardAll,
                child: _nativeMap
                    ? UiKitView(
                        viewType: 'erdek/map',
                        creationParams: {
                          'centerLat': erdekCenter.latitude,
                          'centerLng': erdekCenter.longitude,
                          'pins': [for (final s in shown) s.toPin()],
                        },
                        creationParamsCodec: const StandardMessageCodec(),
                        onPlatformViewCreated: _onCreated,
                      )
                    : Material(
                        key: const Key('map_fallback'),
                        color: p.surface,
                        child: ListView(
                          children: [
                            for (final s in shown)
                              ListTile(
                                title: Text(s.title),
                                subtitle: s.subtitle == null ? null : Text(s.subtitle!, maxLines: 1),
                                onTap: () => openPoint(context, s),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: FloatingActionButton.extended(
          key: const Key('map_nearby'),
          onPressed: () => openNearby(context),
          icon: AppIcon(AppIcons.locationArrow, size: 20, color: p.onPrimary),
          label: Text(l10n.nearbyTitle),
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
        ),
      ),
    );
  }
}
