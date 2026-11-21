import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/explore_repository.dart';
import '../domain/explore.dart';

Future<void> openHistory(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
    );

/// Erdek Tarihi: giriş metni + dönemler (zaman çizelgesi biçiminde).
/// Görselde karşılığı yok; alt sayfa stiline göre.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final history = ref.watch(historyDataProvider);
    final value = history.value;

    final children = <Widget>[
      PageHeader(
        title: l10n.historyTitle,
        subtitle: l10n.historySubtitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.back,
      ),
    ];

    if (value == null) {
      children.add(
        history.hasError
            ? MessageView(
                icon: StateIcons.error,
                iconColor: p.accentRed,
                title: l10n.loadErrorTitle,
                message: l10n.loadErrorMessage,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(historyDataProvider),
              )
            : const SkeletonList(count: 3, itemHeight: 160),
      );
    } else {
      final data = value.data;
      if (value.isSample) {
        children.addAll([
          InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
          const SizedBox(height: AppSpacing.md),
        ]);
      }
      if (data.intro != null) {
        children.addAll([
          Padding(
            padding: AppSpacing.pagePadding,
            child: Text(
              data.intro!,
              style: AppTypography.body.copyWith(color: p.textBody, height: 1.6),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ]);
      }
      for (var i = 0; i < data.sections.length; i++) {
        children.add(
          _TimelineEntry(
            section: data.sections[i],
            isLast: i == data.sections.length - 1,
          ),
        );
      }
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: children,
      ),
    );
  }
}

/// Solda nokta + dikey çizgi, sağda dönem kartı.
class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.section, required this.isLast});

  final HistorySection section;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: AppSpacing.pagePadding,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: p.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.primary, width: 3),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: p.primary.withValues(alpha: 0.25)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: AppRadius.cardAll,
                    boxShadow: AppShadows.card(p.shadow),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (section.period != null) ...[
                        Text(
                          section.period!,
                          style: AppTypography.caption.copyWith(
                            color: p.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Semantics(
                        header: true,
                        child: Text(
                          section.title,
                          style: AppTypography.label.copyWith(
                            color: p.textHeading,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      for (final paragraph in section.paragraphs) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          paragraph,
                          style: AppTypography.body.copyWith(color: p.textBody, height: 1.6),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
