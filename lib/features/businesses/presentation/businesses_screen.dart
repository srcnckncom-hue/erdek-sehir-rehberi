import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/erdek_time.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../explore/presentation/place_photos.dart';
import '../data/businesses_repository.dart';
import '../domain/business.dart';
import 'business_detail_screen.dart';
import 'business_style.dart';

Future<void> openBusinesses(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BusinessesScreen()),
    );

/// İşletmeler: kategori hapları + işletme kartları. Kategoriler ve
/// işletmeler panelden (İşletmeler bölümü) eklenir.
class BusinessesScreen extends ConsumerStatefulWidget {
  const BusinessesScreen({super.key});

  @override
  ConsumerState<BusinessesScreen> createState() => _BusinessesScreenState();
}

class _BusinessesScreenState extends ConsumerState<BusinessesScreen> {
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final result = ref.watch(businessesDataProvider);
    final value = result.value;

    final children = <Widget>[
      PageHeader(
        title: l10n.businessesTitle,
        subtitle: l10n.businessesSubtitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.back,
      ),
    ];

    if (value == null) {
      children.add(
        result.hasError
            ? MessageView(
                icon: StateIcons.error,
                iconColor: p.accentRed,
                title: l10n.loadErrorTitle,
                message: l10n.loadErrorMessage,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(businessesDataProvider),
              )
            : const SkeletonList(count: 4, itemHeight: 88),
      );
    } else {
      final data = value.data;
      final categories = data.usedCategories;
      // Seçili kategori artık boşsa "Tümü"ne dön.
      final selected = categories.any((c) => c.id == _categoryId) ? _categoryId : null;
      final list = data.filter(categoryId: selected);

      if (value.isSample) {
        children
          ..add(InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner))
          ..add(const SizedBox(height: AppSpacing.md));
      }
      if (value.isOffline) {
        children
          ..add(
            InfoBanner(
              icon: AppIcons.offline,
              message: l10n.offlineBanner(
                ErdekTime.hhmm(ErdekTime.toErdek(value.fetchedAt ?? value.updatedAt)),
              ),
            ),
          )
          ..add(const SizedBox(height: AppSpacing.md));
      }

      if (data.businesses.isEmpty) {
        children.add(
          MessageView(
            icon: AppIcons.businesses,
            title: l10n.businessesEmptyTitle,
            message: l10n.businessesEmptyMessage,
          ),
        );
      } else {
        if (categories.length > 1) {
          children.add(
            PillChoiceRow(
              key: const Key('business_category_filter'),
              semanticsLabel: l10n.businessCategoryFilter,
              items: [
                PillChoice(
                  label: l10n.filterAll,
                  selected: selected == null,
                  onTap: () => setState(() => _categoryId = null),
                ),
                for (final c in categories)
                  PillChoice(
                    label: '${c.title} (${data.countIn(c.id)})',
                    selected: selected == c.id,
                    onTap: () => setState(() => _categoryId = c.id),
                  ),
              ],
            ),
          );
        }
        children.add(const SizedBox(height: AppSpacing.lg));
        for (var i = 0; i < list.length; i++) {
          if (i > 0) children.add(const SizedBox(height: AppSpacing.gap));
          final business = list[i];
          final category = data.categoryOf(business);
          children.add(
            BusinessCard(
              business: business,
              category: category,
              onTap: () => openBusiness(
                context,
                business,
                category: category,
                isSample: value.isSample,
              ),
            ),
          );
        }
      }
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(businessesDataProvider);
          try {
            await ref.read(businessesDataProvider.future);
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
}

/// Liste kartı: kapak fotoğrafı (yoksa kategori ikonu) + ad + kategori + kısa tanım.
class BusinessCard extends StatelessWidget {
  const BusinessCard({super.key, required this.business, required this.category, required this.onTap});

  final Business business;
  final BusinessCategory? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final icon = category?.icon ?? BusinessIcon.other;
    final color = BusinessStyle.color(p, icon);
    final fallback = BusinessIconTile(icon: icon);
    final summary = business.summary ?? business.address;

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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.tileAll,
                    child: SizedBox.square(
                      dimension: 64,
                      child: business.photos.isEmpty
                          ? fallback
                          : PlacePhotoImage(url: business.photos.first.url, fallback: fallback),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: AppTypography.label.copyWith(
                            color: p.textHeading,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (category != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            category!.title,
                            style: AppTypography.caption.copyWith(color: color),
                          ),
                        ],
                        if (summary != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(color: p.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: AppIcon(AppIcons.caretRight, size: 18, color: p.textSecondary),
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
