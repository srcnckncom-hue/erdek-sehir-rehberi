import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_result.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/erdek_time.dart';
import '../../../core/util/date_texts.dart';
import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../ads/presentation/ad_slot.dart';
import '../../home/presentation/home_texts.dart';
import '../data/transport_repository.dart';
import '../domain/transport.dart';
import 'transport_selection.dart';

/// Ulaşım sekmesi: feribot/otobüs → hat → gün → sefer listesi.
/// Görselde karşılığı yok; ana sayfa stiline göre.
class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key});

  /// Liste arasına her N seferde bir reklam alanı.
  static const inlineAdEvery = 5;
  static const dayCount = 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final today = CalendarDate.fromDateTime(now);
    final result = ref.watch(transportDataProvider);
    final selection = ref.watch(transportSelectionProvider);
    final notifier = ref.read(transportSelectionProvider.notifier);
    final value = result.value;

    final children = <Widget>[
      PageHeader(
        title: l10n.transportScreenTitle,
        subtitle: l10n.transportSubtitle(DateTexts.weekdayDayMonth(l10n, today)),
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
                onAction: () => ref.invalidate(transportDataProvider),
              )
            : const SkeletonList(count: 5, itemHeight: 56),
      );
    } else {
      children.addAll(_banners(l10n, value));

      final routes = value.data.byMode(selection.mode);
      final route = routes.where((r) => r.id == selection.routeId).firstOrNull ?? routes.firstOrNull;
      final selectedDate = today.addDays(selection.dayOffset);

      children.addAll([
        SegmentedPills<TransportMode>(
          selected: selection.mode,
          onSelected: notifier.selectMode,
          options: [
            SegmentOption(value: TransportMode.ferry, label: l10n.modeFerry, icon: AppIcons.ferry),
            SegmentOption(value: TransportMode.bus, label: l10n.modeBus, icon: AppIcons.bus),
            SegmentOption(value: TransportMode.city, label: l10n.modeCity, icon: AppIcons.cityBus),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PillChoiceRow(
          semanticsLabel: l10n.selectRoute,
          items: [
            for (final r in routes)
              PillChoice(label: r.title, selected: r.id == route?.id, onTap: () => notifier.selectRoute(r.id)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ]);

      if (route != null && route.isSample) {
        children.addAll([
          InfoBanner(icon: AppIcons.info, message: l10n.routeSampleBanner),
          const SizedBox(height: AppSpacing.lg),
        ]);
      }

      if (route == null) {
        children.add(
          MessageView(
            icon: modeIcon(selection.mode),
            title: l10n.noTimetableTitle,
            message: l10n.noTimetableMessage,
          ),
        );
      } else {
        final next = upcomingDepartures(route, now, limit: 1).firstOrNull;
        children.addAll([
          Padding(
            padding: AppSpacing.pagePadding,
            child: _NextDepartureCard(route: route, next: next, now: now, today: today),
          ),
          const SizedBox(height: AppSpacing.section),
          SectionHeader(title: l10n.departuresTitle),
          const SizedBox(height: AppSpacing.md),
          PillChoiceRow(
            items: [
              for (var i = 0; i < dayCount; i++)
                PillChoice(
                  label: _dayLabel(l10n, today.addDays(i), today),
                  selected: i == selection.dayOffset,
                  onTap: () => notifier.selectDay(i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DepartureList(
            route: route,
            date: selectedDate,
            today: today,
            now: now,
            next: next,
          ),
        ]);
      }

      children.addAll([
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: AppSpacing.pagePadding,
          child: Text(
            l10n.transportSourceNote(
              DateTexts.dayMonth(l10n, CalendarDate.fromDateTime(ErdekTime.toErdek(value.updatedAt))),
            ),
            style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
          ),
        ),
      ]);
    }

    children.add(
      const AdSlot(
        id: 'transport_bottom',
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.section, AppSpacing.page, 0),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transportDataProvider);
        try {
          await ref.read(transportDataProvider.future);
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

  static String _dayLabel(AppLocalizations l10n, CalendarDate date, CalendarDate today) {
    if (date == today) return l10n.today;
    if (date == today.addDays(1)) return l10n.tomorrow;
    return l10n.dayChip(l10n.weekdayShort('${date.weekday}'), date.day);
  }

  List<Widget> _banners(AppLocalizations l10n, DataResult<TransportData> value) => [
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
}

// ─── Sıradaki sefer kartı ─────────────────────────────────────────────────

class _NextDepartureCard extends StatelessWidget {
  const _NextDepartureCard({
    required this.route,
    required this.next,
    required this.now,
    required this.today,
  });

  final TransportRoute route;
  final UpcomingDeparture? next;
  final DateTime now;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final timetable = route.timetableFor(today);

    final String title;
    final subtitle = <String>[l10n.fromTo(route.from, route.to)];
    if (next == null) {
      title = l10n.noUpcomingDepartures;
    } else {
      final n = next!;
      title = l10n.dayAndTime(HomeTexts.relativeDay(l10n, n.date, today), n.departure.time.toString());
      final arrival = n.departure.arrival;
      if (arrival != null) subtitle[0] = '${subtitle[0]} · ${l10n.arrivalAt(arrival.toString())}';
      final minutes = today.daysUntil(n.date) * 24 * 60 + n.departure.time.minutesOfDay - (now.hour * 60 + now.minute);
      subtitle.add(HomeTexts.remaining(l10n, Duration(minutes: minutes)));
      if (n.departure.note != null) subtitle.add(n.departure.note!);
    }

    return FeatureCard(
      color: switch (route.mode) {
        TransportMode.ferry => p.aqua.foreground,
        TransportMode.bus => p.primary,
        TransportMode.city => p.mint.foreground,
      },
      icon: modeIcon(route.mode),
      overline: l10n.nextDepartureOverline,
      title: title,
      subtitle: subtitle.join('\n'),
      tagLabel: timetable?.name,
      tagIcon: timetable == null ? null : AppIcons.imsakiye,
      actions: [
        if (route.phone != null)
          CardAction(
            icon: AppIcons.call,
            label: l10n.callOperator,
            onTap: () => launchOrNotify(context, () => Launchers.call(route.phone!)),
          ),
      ],
      footnote: route.operatorName,
    );
  }
}

// ─── Sefer listesi ────────────────────────────────────────────────────────

class _DepartureList extends StatelessWidget {
  const _DepartureList({
    required this.route,
    required this.date,
    required this.today,
    required this.now,
    required this.next,
  });

  final TransportRoute route;
  final CalendarDate date;
  final CalendarDate today;
  final DateTime now;
  final UpcomingDeparture? next;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;

    if (route.timetableFor(date) == null) {
      return MessageView(
        icon: AppIcons.imsakiye,
        title: l10n.noTimetableTitle,
        message: l10n.noTimetableMessage,
      );
    }
    final departures = route.departuresOn(date);
    if (departures.isEmpty) {
      return MessageView(icon: AppIcons.imsakiye, title: l10n.noDeparturesTitle);
    }

    final nowMinutes = now.hour * 60 + now.minute;
    final rows = <Widget>[];
    for (var i = 0; i < departures.length; i++) {
      final d = departures[i];
      if (i > 0) {
        rows.add(Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg, color: p.divider));
        // Her 5 seferde bir yerel reklam (aktif reklam yoksa yer kaplamaz).
        if (i % TransportScreen.inlineAdEvery == 0) {
          rows.add(
            const AdSlot(
              id: 'transport_list_inline',
              padding: EdgeInsets.all(AppSpacing.sm),
            ),
          );
        }
      }
      final isNext = next != null && next!.date == date && next!.departure.time == d.time;
      final isPast = date == today && d.time.minutesOfDay <= nowMinutes;
      rows.add(_DepartureRow(departure: d, isNext: isNext, isPast: isPast, nextLabel: l10n.nextBadge));
    }

    return Container(
      margin: AppSpacing.pagePadding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.tileAll,
        boxShadow: AppShadows.card(p.shadow),
      ),
      child: Column(children: rows),
    );
  }
}

class _DepartureRow extends StatelessWidget {
  const _DepartureRow({
    required this.departure,
    required this.isNext,
    required this.isPast,
    required this.nextLabel,
  });

  final Departure departure;
  final bool isNext;
  final bool isPast;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final color = isNext ? p.primary : (isPast ? p.textSecondary : p.textBody);
    return Container(
      color: isNext ? p.primarySoft : null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              departure.time.toString(),
              style: AppTypography.label.copyWith(
                color: color,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                decoration: isPast ? TextDecoration.lineThrough : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (departure.arrival != null)
                  Text(
                    l10n.arrivalAt(departure.arrival.toString()),
                    style: AppTypography.tileLabel.copyWith(color: isPast ? p.textSecondary : p.textBody),
                  ),
                if (departure.note != null)
                  Text(
                    departure.note!,
                    style: AppTypography.caption.copyWith(color: p.textSecondary),
                  ),
              ],
            ),
          ),
          if (isNext)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(color: p.primary, borderRadius: AppRadius.pillAll),
              child: Text(
                nextLabel,
                style: AppTypography.tabLabel.copyWith(color: p.onPrimary, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

AppIconData modeIcon(TransportMode mode) => switch (mode) {
      TransportMode.ferry => AppIcons.ferry,
      TransportMode.bus => AppIcons.bus,
      TransportMode.city => AppIcons.cityBus,
    };
