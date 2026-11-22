import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_result.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/erdek_time.dart';
import '../../../core/util/date_texts.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../ads/presentation/ad_slot.dart';
import '../../home/presentation/home_texts.dart';
import '../../ramadan/ramadan_screen.dart';
import '../data/prayer_repository.dart';
import '../domain/prayer_times.dart';
import '../notifications/prayer_notification_plan.dart';
import '../notifications/prayer_notifications.dart';
import 'imsakiye_table.dart';
import 'notification_settings_sheet.dart';

/// Vakitler sekmesi: sıradaki vakit, bugünün vakitleri, bildirim ayarı,
/// aylık imsakiye. Görselde karşılığı yok; ana sayfa stiline göre.
class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  /// İmsakiyede gösterilen ay (null = bugünün ayı).
  (int, int)? _month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final today = CalendarDate.fromDateTime(now);
    final result = ref.watch(prayerTimesProvider);
    final settings = ref.watch(prayerNotificationSettingsProvider);
    final value = result.value;
    final data = value?.data;
    final todayData = data?.dayFor(today);

    final subtitle = [
      l10n.prayerSubtitle(DateTexts.weekdayDayMonth(l10n, today)),
      if (todayData?.hijri != null) l10n.hijriDate(todayData!.hijri!),
    ].join('\n');

    final children = <Widget>[PageHeader(title: l10n.prayerScreenTitle, subtitle: subtitle)];

    if (value == null) {
      children.add(
        result.hasError
            ? MessageView(
                icon: StateIcons.error,
                iconColor: p.accentRed,
                title: l10n.loadErrorTitle,
                message: l10n.loadErrorMessage,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(prayerTimesProvider),
              )
            : const SkeletonList(count: 4, itemHeight: 90),
      );
    } else {
      children.addAll(_banners(l10n, value));

      final next = findNextPrayer(value.data, now);
      if (todayData == null || next == null) {
        children.add(
          MessageView(
            icon: AppIcons.prayer,
            title: l10n.prayerNoDataTitle,
            message: l10n.prayerNoDataMessage,
          ),
        );
      } else {
        children.addAll([
          Padding(
            padding: AppSpacing.pagePadding,
            child: FeatureCard(
              color: p.primary,
              icon: AppIcons.prayer,
              overline: l10n.nextPrayerTitle,
              title: l10n.prayerTitleWithTime(l10n.prayerName(next.name.jsonKey), next.time.toString()),
              subtitle: HomeTexts.remaining(l10n, next.remaining),
              tagLabel: settings.enabled ? l10n.notificationsTag : null,
              tagIcon: settings.enabled ? AppIcons.bell : null,
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          SectionHeader(title: l10n.todayTimesTitle),
          const SizedBox(height: AppSpacing.md),
          GroupedCard(
            children: [
              for (final name in PrayerName.values)
                _PrayerRow(
                  name: l10n.prayerName(name.jsonKey),
                  time: todayData.timeOf(name).toString(),
                  state: _rowState(name, todayData, next, today, now),
                ),
            ],
          ),
        ]);
      }

      children.addAll([
        const SizedBox(height: AppSpacing.section),
        const RamadanEntryCard(),
        _NotificationTile(settings: settings),
        const SizedBox(height: AppSpacing.section),
        ..._imsakiye(context, value.data, today),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: AppSpacing.pagePadding,
          child: Text(
            l10n.prayerSourceNote(l10n.prayerSourceName),
            style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
          ),
        ),
      ]);
    }

    children.add(
      const AdSlot(
        id: 'prayer_bottom',
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.section, AppSpacing.page, 0),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(prayerTimesProvider);
        try {
          await ref.read(prayerTimesProvider.future);
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

  List<Widget> _banners(AppLocalizations l10n, DataResult<PrayerTimesData> value) => [
        if (value.isSample) ...[
          InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (value.isOffline) ...[
          InfoBanner(
            icon: AppIcons.offline,
            message: l10n.offlineBanner(
              ErdekTime.hhmm(ErdekTime.toErdek(value.fetchedAt ?? value.updatedAt)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (value.isSample || value.isOffline) const SizedBox(height: AppSpacing.sm),
      ];

  _RowState _rowState(
    PrayerName name,
    PrayerDay day,
    NextPrayer next,
    CalendarDate today,
    DateTime now,
  ) {
    if (next.date == today && next.name == name) return _RowState.next;
    final passed = day.timeOf(name).minutesOfDay <= now.hour * 60 + now.minute;
    return passed ? _RowState.passed : _RowState.upcoming;
  }

  List<Widget> _imsakiye(BuildContext context, PrayerTimesData data, CalendarDate today) {
    final l10n = AppLocalizations.of(context);
    final months = {for (final d in data.days) (d.date.year, d.date.month)}.toList()
      ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    if (months.isEmpty) return const [];

    var selected = _month ?? (today.year, today.month);
    if (!months.contains(selected)) selected = months.first;
    final index = months.indexOf(selected);

    return [
      SectionHeader(title: l10n.imsakiyeTitle),
      const SizedBox(height: AppSpacing.sm),
      Padding(
        padding: AppSpacing.pagePadding,
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.previousMonth,
              onPressed: index > 0 ? () => setState(() => _month = months[index - 1]) : null,
              icon: AppIcon(AppIcons.caretLeft, size: 22),
            ),
            Expanded(
              child: Text(
                l10n.monthYear(l10n.monthName('${selected.$2}'), '${selected.$1}'),
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(
                  color: context.palette.textHeading,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.nextMonth,
              onPressed: index < months.length - 1
                  ? () => setState(() => _month = months[index + 1])
                  : null,
              icon: AppIcon(AppIcons.caretRight, size: 22),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      ImsakiyeTable(days: data.month(selected.$1, selected.$2), today: today),
    ];
  }
}

enum _RowState { passed, next, upcoming }

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({required this.name, required this.time, required this.state});

  final String name;
  final String time;
  final _RowState state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isNext = state == _RowState.next;
    final color = switch (state) {
      _RowState.next => p.primary,
      _RowState.passed => p.textSecondary,
      _RowState.upcoming => p.textBody,
    };
    return Container(
      color: isNext ? p.primarySoft : null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isNext ? p.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              name,
              style: AppTypography.label.copyWith(
                color: color,
                fontWeight: isNext ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: AppTypography.label.copyWith(
              color: color,
              fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.settings});

  final PrayerNotificationSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final summary = !settings.enabled
        ? l10n.notificationsOff
        : settings.minutesBefore == 0
            ? l10n.notificationsOnAtTime
            : l10n.notificationsOnBefore(settings.minutesBefore);

    return GroupedCard(
      children: [
        InkWell(
          onTap: () => showNotificationSettingsSheet(context),
          borderRadius: AppRadius.tileAll,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
            child: Row(
              children: [
                AppIcon(AppIcons.bellRinging, size: 28, color: p.iconOrange),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notificationsTitle,
                        style: AppTypography.label.copyWith(color: p.textHeading),
                      ),
                      Text(summary, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: settings.enabled,
                  onChanged: (on) => toggleNotifications(context, ref, on: on),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
