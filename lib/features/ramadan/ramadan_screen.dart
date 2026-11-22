import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/time/calendar_date.dart';
import '../../core/util/date_texts.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../home/presentation/home_texts.dart';
import '../prayer/data/prayer_repository.dart';
import '../prayer/domain/prayer_times.dart';
import '../reminders/reminder_scheduler.dart';
import 'ramadan.dart';

Future<void> openRamadan(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RamadanScreen()),
    );

/// İftar bildirimini aç/kapatır ve bildirimleri hemen yeniden kurar.
Future<void> toggleIftarNotifications(BuildContext context, WidgetRef ref, {required bool on}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await ref.read(iftarNotificationsProvider.notifier).setEnabled(on);
  if (!ok) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.notificationPermissionDenied)));
    return;
  }
  await syncIftarNotifications(
    scheduler: ref.read(reminderSchedulerProvider),
    data: ref.read(prayerTimesProvider).value?.data,
    enabled: on,
    erdekNow: ref.read(clockProvider)(),
    title: l10n.iftarNotifTitle,
    body: l10n.iftarNotifBody,
  );
}

/// Ramazan: geri sayım (Ramazan'a / sahura / iftara), önemli günler,
/// iftar bildirimi ve Ramazan imsakiyesi.
class RamadanScreen extends ConsumerWidget {
  const RamadanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final today = CalendarDate.fromDateTime(now);
    final period = currentOrNextRamadan(today);
    final data = ref.watch(prayerTimesProvider).value?.data;
    final iftarOn = ref.watch(iftarNotificationsProvider);

    final children = <Widget>[
      PageHeader(
        title: l10n.ramadanTitle,
        subtitle: period == null ? null : l10n.ramadanSubtitle('${period.hijriYear}'),
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.back,
      ),
    ];

    if (period == null) {
      children.add(MessageView(icon: AppIcons.ramadan, title: l10n.ramadanOver));
    } else {
      final dayNumber = period.dayNumber(today);
      final countdown = data == null ? null : ramadanCountdown(period, data, now);

      // Üst kart: Ramazan'a kalan gün ya da sahur/iftar geri sayımı.
      final String overline;
      final String title;
      String? subtitle;
      if (dayNumber == null && today.isBefore(period.firstFast)) {
        final days = today.daysUntil(period.firstFast);
        overline = l10n.ramadanTitle;
        title = l10n.ramadanDaysLeft(days);
        subtitle = l10n.ramadanFirstSahur(DateTexts.dayMonth(l10n, period.firstFast.addDays(-1)));
      } else if (countdown != null) {
        overline = dayNumber == null ? l10n.ramadanTitle : l10n.ramadanDayN(dayNumber);
        title = l10n.prayerTitleWithTime(
          countdown.target == RamadanTarget.sahur ? l10n.ramadanImsak : l10n.ramadanIftar,
          countdown.time.toString(),
        );
        subtitle = '${countdown.target == RamadanTarget.sahur ? l10n.ramadanToSahur : l10n.ramadanToIftar} · '
            '${HomeTexts.remaining(l10n, countdown.remaining)}';
      } else {
        overline = dayNumber == null ? l10n.ramadanTitle : l10n.ramadanDayN(dayNumber);
        title = l10n.ramadanEid(DateTexts.weekdayDayMonth(l10n, period.eid));
        subtitle = l10n.ramadanTimesPending;
      }

      children.addAll([
        Padding(
          padding: AppSpacing.pagePadding,
          child: FeatureCard(
            key: const Key('ramadan_countdown'),
            color: p.iconPurple,
            icon: AppIcons.ramadan,
            overline: overline,
            title: title,
            subtitle: subtitle,
            tagLabel: iftarOn ? l10n.notificationsTag : null,
            tagIcon: iftarOn ? AppIcons.bell : null,
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionHeader(title: l10n.ramadanDatesTitle),
        const SizedBox(height: AppSpacing.md),
        GroupedCard(
          children: [
            _InfoRow(
              label: l10n.ramadanFirstSahurLabel,
              value: l10n.ramadanNightOf(DateTexts.weekdayDayMonth(l10n, period.firstFast.addDays(-1))),
            ),
            _InfoRow(label: l10n.ramadanFirstFastLabel, value: DateTexts.weekdayDayMonth(l10n, period.firstFast)),
            _InfoRow(label: l10n.ramadanKadirLabel, value: DateTexts.weekdayDayMonth(l10n, period.kadirNight)),
            _InfoRow(label: l10n.ramadanLastFastLabel, value: DateTexts.weekdayDayMonth(l10n, period.lastFast)),
            _InfoRow(label: l10n.ramadanEidLabel, value: DateTexts.weekdayDayMonth(l10n, period.eid)),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        GroupedCard(
          children: [
            SwitchListTile.adaptive(
              key: const Key('ramadan_iftar_switch'),
              value: iftarOn,
              onChanged: (on) => toggleIftarNotifications(context, ref, on: on),
              secondary: AppIcon(AppIcons.bellRinging, size: 24, color: p.iconOrange),
              title: Text(l10n.ramadanIftarNotif, style: AppTypography.label.copyWith(color: p.textHeading)),
              subtitle: Text(
                l10n.ramadanIftarNotifSubtitle,
                style: AppTypography.caption.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        SectionHeader(title: l10n.ramadanCalendarTitle),
        const SizedBox(height: AppSpacing.md),
        ..._calendar(context, period, data, today),
      ]);
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: children,
      ),
    );
  }

  List<Widget> _calendar(BuildContext context, RamadanPeriod period, PrayerTimesData? data, CalendarDate today) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final days = [
      for (final d in data?.days ?? const <PrayerDay>[])
        if (period.contains(d.date)) d,
    ]..sort((a, b) => a.date.compareTo(b.date));

    if (days.isEmpty) {
      return [InfoBanner(icon: AppIcons.info, message: l10n.ramadanTimesPending)];
    }

    final header = AppTypography.caption.copyWith(color: p.textSecondary, fontWeight: FontWeight.w600);
    return [
      Container(
        margin: AppSpacing.pagePadding,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: p.surface, borderRadius: AppRadius.tileAll),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(width: 36, child: Text('#', style: header)),
                  Expanded(child: Text(l10n.ramadanDateColumn, style: header)),
                  SizedBox(width: 64, child: Text(l10n.ramadanImsak, style: header, textAlign: TextAlign.right)),
                  SizedBox(width: 64, child: Text(l10n.ramadanIftar, style: header, textAlign: TextAlign.right)),
                ],
              ),
            ),
            for (final d in days)
              Container(
                color: d.date == today ? p.primarySoft : null,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text('${period.dayNumber(d.date)}', style: AppTypography.caption.copyWith(color: p.textSecondary)),
                    ),
                    Expanded(
                      child: Text(
                        DateTexts.weekdayDayMonth(l10n, d.date),
                        style: AppTypography.caption.copyWith(color: p.textBody),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        d.timeOf(PrayerName.imsak).toString(),
                        textAlign: TextAlign.right,
                        style: AppTypography.caption.copyWith(color: p.textHeading),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        d.timeOf(PrayerName.aksam).toString(),
                        textAlign: TextAlign.right,
                        style: AppTypography.caption.copyWith(color: p.textHeading, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      if (days.length < period.dayCount) ...[
        const SizedBox(height: AppSpacing.md),
        InfoBanner(icon: AppIcons.info, message: l10n.ramadanTimesPending),
      ],
    ];
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.label.copyWith(color: p.textHeading))),
          Text(value, style: AppTypography.caption.copyWith(color: p.textSecondary)),
        ],
      ),
    );
  }
}

/// Vakitler sekmesindeki Ramazan kartı (başlangıçtan 90 gün önce → bayram).
class RamadanEntryCard extends ConsumerWidget {
  const RamadanEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final today = CalendarDate.fromDateTime(now);
    final period = currentOrNextRamadan(today);
    if (period == null || !showRamadanEntry(today)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final dayNumber = period.dayNumber(today);
    final subtitle = dayNumber != null
        ? l10n.ramadanDayN(dayNumber)
        : today.isBefore(period.firstFast)
            ? l10n.ramadanDaysLeft(today.daysUntil(period.firstFast))
            : l10n.ramadanEid(DateTexts.weekdayDayMonth(l10n, period.eid));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Container(
        margin: AppSpacing.pagePadding,
        decoration: BoxDecoration(
          color: p.iconPurple.withValues(alpha: 0.10),
          borderRadius: AppRadius.cardAll,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const Key('ramadan_entry'),
            borderRadius: AppRadius.cardAll,
            onTap: () => openRamadan(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  AppIcon(AppIcons.ramadan, size: 32, color: p.iconPurple),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.ramadanTitle,
                          style: AppTypography.label.copyWith(color: p.textHeading, fontWeight: FontWeight.w600),
                        ),
                        Text(subtitle, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                      ],
                    ),
                  ),
                  AppIcon(AppIcons.caretRight, size: 18, color: p.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
