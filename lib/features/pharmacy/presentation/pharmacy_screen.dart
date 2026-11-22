import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/erdek_time.dart';
import '../../../core/util/date_texts.dart';
import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../ads/presentation/ad_slot.dart';
import '../../settings/presentation/report_issue.dart';
import '../../share/share_actions.dart';
import '../data/pharmacy_repository.dart';
import '../domain/duty_schedule.dart';
import '../domain/pharmacy.dart';
import 'pharmacy_card.dart';

/// Eczane sekmesi: bugünün nöbetçileri + önümüzdeki günler.
/// Görselde karşılığı yok; ana sayfa stiline göre tasarlandı.
class PharmacyScreen extends ConsumerWidget {
  const PharmacyScreen({super.key});

  /// Yarın dahil önümüzdeki 7 gün.
  static const upcomingDays = 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final result = ref.watch(pharmacyDataProvider);
    final value = result.value;

    final dutyDate = dutyDateFor(now);
    final period = l10n.dutyPeriod(
      DateTexts.dayMonth(l10n, dutyDate),
      DateTexts.dayMonth(l10n, dutyDate.addDays(1)),
    );

    final children = <Widget>[
      PageHeader(title: l10n.pharmacyScreenTitle, subtitle: period),
    ];

    if (value == null) {
      if (result.hasError) {
        children.add(
          MessageView(
            icon: StateIcons.error,
            iconColor: context.palette.accentRed,
            title: l10n.loadErrorTitle,
            message: l10n.loadErrorMessage,
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(pharmacyDataProvider),
          ),
        );
      } else {
        children.add(const SkeletonList(count: 3, itemHeight: 150));
      }
    } else {
      final data = value.data;
      final onDuty = data.onDutyFor(dutyDate);

      if (value.isSample) {
        children.addAll([
          InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
          const SizedBox(height: AppSpacing.sm),
        ]);
      }
      if (value.isOffline) {
        final at = ErdekTime.toErdek(value.fetchedAt ?? value.updatedAt);
        children.addAll([
          InfoBanner(icon: AppIcons.offline, message: l10n.offlineBanner(ErdekTime.hhmm(at))),
          const SizedBox(height: AppSpacing.sm),
        ]);
      }
      children.addAll([
        InfoBanner(icon: AppIcons.warning, message: l10n.pharmacyConfirm),
        const SizedBox(height: AppSpacing.lg),
      ]);

      if (onDuty.isEmpty) {
        children.add(
          MessageView(
            icon: AppIcons.pharmacy,
            iconColor: context.palette.accentRed,
            title: l10n.pharmacyEmptyTitle,
            message: l10n.pharmacyEmptyMessage,
            actionLabel: l10n.callEmergency,
            onAction: () => launchOrNotify(context, () => Launchers.call('112')),
          ),
        );
      } else {
        for (var i = 0; i < onDuty.length; i++) {
          if (i > 0) children.add(const SizedBox(height: AppSpacing.gap));
          children.add(
            _card(
              context,
              onDuty[i],
              data.noteFor(dutyDate, onDuty[i].id),
              dayLabel: DateTexts.weekdayDayMonth(l10n, dutyDate),
            ),
          );
        }
      }

      children.addAll([
        const SizedBox(height: AppSpacing.section),
        SectionHeader(title: l10n.upcomingDutiesTitle),
        const SizedBox(height: AppSpacing.md),
        GroupedCard(
          children: [
            for (var i = 1; i <= upcomingDays; i++)
              _UpcomingRow(
                // İlk satır: "Yarın · Pazar, 22 Kasım" (vurgulu)
                label: i == 1
                    ? l10n.tomorrowWithDate(DateTexts.weekdayDayMonth(l10n, dutyDate.addDays(i)))
                    : DateTexts.weekdayDayMonth(l10n, dutyDate.addDays(i)),
                highlight: i == 1,
                names: [
                  for (final p in data.onDutyFor(dutyDate.addDays(i)))
                    switch (data.noteFor(dutyDate.addDays(i), p.id)) {
                      final note? => '${p.name}\n($note)',
                      null => p.name,
                    },
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: AppSpacing.pagePadding,
          child: Text(
            l10n.pharmacySourceNote,
            style: AppTypography.tabLabel.copyWith(color: context.palette.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ReportIssueLink(section: l10n.pharmacyScreenTitle),
      ]);
    }

    children.add(
      const AdSlot(
        id: 'pharmacy_bottom',
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.section, AppSpacing.page, 0),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pharmacyDataProvider);
        try {
          await ref.read(pharmacyDataProvider.future);
        } catch (_) {
          // Hata ekranda gösterilir.
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg),
        children: children,
      ),
    );
  }

  Widget _card(BuildContext context, Pharmacy pharmacy, String? note, {required String dayLabel}) => PharmacyCard(
        pharmacy: pharmacy,
        note: note,
        shareText: ShareTexts.pharmacy(
          AppLocalizations.of(context),
          pharmacy: pharmacy,
          dayLabel: dayLabel,
          note: note,
        ),
        onCall: () => launchOrNotify(context, () => Launchers.call(pharmacy.phone)),
        onDirections: () => launchOrNotify(
          context,
          () => Launchers.directions(
            name: pharmacy.name,
            address: pharmacy.address,
            latitude: pharmacy.latitude,
            longitude: pharmacy.longitude,
          ),
        ),
      );
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.label, required this.names, this.highlight = false});

  final String label;
  final List<String> names;

  /// Yarın satırı: etiket kalın ve ana renkte.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: highlight
                  ? AppTypography.tileLabel.copyWith(color: p.primary, fontWeight: FontWeight.w600)
                  : AppTypography.caption.copyWith(color: p.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              names.isEmpty ? l10n.noDutyRecord : names.join('\n'),
              textAlign: TextAlign.end,
              style: AppTypography.tileLabel.copyWith(
                color: names.isEmpty ? p.textSecondary : p.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
