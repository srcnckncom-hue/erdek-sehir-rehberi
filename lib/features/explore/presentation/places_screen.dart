import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/data_result.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/erdek_time.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/explore_repository.dart';
import '../domain/explore.dart';
import 'place_detail_screen.dart';
import 'place_style.dart';

Future<void> openPlaces(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PlacesScreen()),
    );

/// Bölge filtresi: Tümü / Erdek / Kapıdağ.
enum _AreaFilter { all, erdek, kapidag }

extension on _AreaFilter {
  PlaceArea? get area => switch (this) {
        _AreaFilter.all => null,
        _AreaFilter.erdek => PlaceArea.erdek,
        _AreaFilter.kapidag => PlaceArea.kapidag,
      };
}

/// Gezilecek Yerler: bölge anahtarı + tür hapları + yer kartları.
/// Görselde karşılığı yok; alt sayfa stiline göre.
class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key});

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  _AreaFilter _area = _AreaFilter.all;
  PlaceCategory? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final places = ref.watch(placesDataProvider);
    final value = places.value;

    final children = <Widget>[
      PageHeader(
        title: l10n.placesTitle,
        subtitle: l10n.placesSubtitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.back,
      ),
    ];

    if (value == null) {
      children.add(
        places.hasError
            ? MessageView(
                icon: StateIcons.error,
                iconColor: p.accentRed,
                title: l10n.loadErrorTitle,
                message: l10n.loadErrorMessage,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(placesDataProvider),
              )
            : const SkeletonList(count: 4, itemHeight: 96),
      );
    } else {
      final data = value.data;
      final categories = data.categoriesIn(_area.area);
      // Bölge değişince o bölgede olmayan tür seçili kalmasın.
      final category = categories.contains(_category) ? _category : null;
      final list = data.filter(area: _area.area, category: category);

      children
        ..addAll(_banners(l10n, value))
        ..add(
          SegmentedPills<_AreaFilter>(
            selected: _area,
            onSelected: (a) => setState(() => _area = a),
            options: [
              SegmentOption(value: _AreaFilter.all, label: l10n.filterAll),
              SegmentOption(value: _AreaFilter.erdek, label: l10n.areaName('erdek')),
              SegmentOption(value: _AreaFilter.kapidag, label: l10n.areaName('kapidag')),
            ],
          ),
        );
      if (categories.length > 1) {
        children.addAll([
          const SizedBox(height: AppSpacing.md),
          PillChoiceRow(
            semanticsLabel: l10n.placeCategoryFilter,
            items: [
              PillChoice(
                label: l10n.filterAll,
                selected: category == null,
                onTap: () => setState(() => _category = null),
              ),
              for (final c in categories)
                PillChoice(
                  label: PlaceStyle.categoryName(l10n, c),
                  selected: category == c,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
        ]);
      }
      children.add(const SizedBox(height: AppSpacing.lg));
      if (list.isEmpty) {
        children.add(MessageView(icon: StateIcons.empty, title: l10n.noPlacesInFilter));
      } else {
        for (var i = 0; i < list.length; i++) {
          if (i > 0) children.add(const SizedBox(height: AppSpacing.gap));
          children.add(
            PlaceCard(
              place: list[i],
              onTap: () => openPlace(context, list[i], isSample: value.isSample),
            ),
          );
        }
      }
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(placesDataProvider);
          try {
            await ref.read(placesDataProvider.future);
          } catch (_) {
            // Hata ekranda gösterilir.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg),
          children: children,
        ),
      ),
    );
  }

  List<Widget> _banners(AppLocalizations l10n, DataResult<Object> value) => [
        if (value.isSample) ...[
          InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
          const SizedBox(height: AppSpacing.md),
        ],
        if (value.isOffline) ...[
          InfoBanner(
            icon: AppIcons.offline,
            message: l10n.offlineBanner(
              ErdekTime.hhmm(ErdekTime.toErdek(value.fetchedAt ?? value.updatedAt)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ];
}

/// Liste kartı: tür ikonu (fotoğraf gelene kadar) + başlık + bölge/tür + özet.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final color = PlaceStyle.color(p, place.category);

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.tileAll,
          ),
          child: AppIcon(PlaceStyle.icon(place.category), size: 32, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place.title,
                style: AppTypography.label.copyWith(
                  color: p.textHeading,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                PlaceStyle.meta(l10n, place),
                style: AppTypography.caption.copyWith(color: color),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                place.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: AppIcon(AppIcons.caretRight, size: 18, color: p.textSecondary),
        ),
      ],
    );

    return Padding(
      padding: AppSpacing.pagePadding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: AppRadius.cardAll,
          boxShadow: AppShadows.card(p.shadow),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.cardAll,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
