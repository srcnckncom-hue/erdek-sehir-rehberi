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
import '../../../core/system/system_bridge.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../ads/presentation/ad_slot.dart';
import '../../reminders/departure_reminders.dart';
import '../../settings/presentation/report_issue.dart';
import '../../share/share_actions.dart';
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
        // Şehir içi hatlar çok: kaydırmalı satır yerine alt alta iki sütun (büyük, okunaklı).
        if (selection.mode == TransportMode.city)
          _RouteGrid(routes: routes, selectedId: route?.id, onSelect: notifier.selectRoute)
        else
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
          if (route.stops.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            _StopList(route: route),
          ],
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
        const SizedBox(height: AppSpacing.xs),
        ReportIssueLink(section: l10n.transportScreenTitle),
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
    // Bugünkü son sefer (henüz kalkmadıysa): "Bugünkü son sefer 18:00"
    final todays = route.departuresOn(today);
    if (todays.isNotEmpty && todays.last.time.minutesOfDay > now.hour * 60 + now.minute) {
      final isLast = next != null && next!.date == today && next!.departure.time == todays.last.time;
      subtitle.add(
        isLast ? l10n.thisIsLastDepartureToday : l10n.lastDepartureToday(todays.last.time.toString()),
      );
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

// ─── Şehir içi hat seçimi ────────────────────────────────────────────────

class _RouteGrid extends StatelessWidget {
  const _RouteGrid({required this.routes, required this.selectedId, required this.onSelect});

  final List<TransportRoute> routes;
  final String? selectedId;
  final void Function(String id) onSelect;

  /// "A → B" başlığını iki satıra böler: ("A ›", "B"). Ok yoksa başlık tek satır.
  static (String, String?) lines(String title) {
    final i = title.indexOf('→');
    if (i < 0) return (title, null);
    return ('${title.substring(0, i).trim()} ›', title.substring(i + 1).trim());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return QuickActionGrid(
      columns: 2,
      children: [
        for (final r in routes)
          Builder(builder: (context) {
            final selected = r.id == selectedId;
            final (first, second) = lines(r.title);
            final fg = selected ? p.onPrimary : p.textBody;
            return Semantics(
              button: true,
              selected: selected,
              label: r.title,
              excludeSemantics: true,
              child: Material(
                key: Key('route_${r.id}'),
                color: selected ? p.primary : p.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.chipAll,
                  side: BorderSide(color: selected ? p.primary : p.divider),
                ),
                child: InkWell(
                  borderRadius: AppRadius.chipAll,
                  onTap: () => onSelect(r.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(first, style: AppTypography.tileLabel.copyWith(color: fg, fontWeight: FontWeight.w600)),
                        if (second != null) ...[
                          const SizedBox(height: 2),
                          Text(second, style: AppTypography.tileLabel.copyWith(color: fg, fontWeight: FontWeight.w500)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ─── Duraklar ─────────────────────────────────────────────────────────────

class _StopList extends StatelessWidget {
  const _StopList({required this.route});

  final TransportRoute route;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final stops = route.stops;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.routeStops(stops.length)),
        const SizedBox(height: AppSpacing.md),
        GroupedCard(
          children: [
            for (var i = 0; i < stops.length; i++)
              ListTile(
                key: Key('route_stop_$i'),
                dense: true,
                leading: CircleAvatar(
                  radius: 13,
                  backgroundColor: p.mint.foreground,
                  child: Text('${i + 1}', style: AppTypography.tabLabel.copyWith(color: Colors.white)),
                ),
                title: Text(stops[i], style: AppTypography.label.copyWith(color: p.textHeading)),
              ),
          ],
        ),
      ],
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
            AdSlot(
              id: 'transport_list_inline',
              index: i ~/ TransportScreen.inlineAdEvery,
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          );
        }
      }
      final isNext = next != null && next!.date == date && next!.departure.time == d.time;
      final isPast = date == today && d.time.minutesOfDay <= nowMinutes;
      rows.add(
        _DepartureRow(
          route: route,
          date: date,
          today: today,
          departure: d,
          isNext: isNext,
          isPast: isPast,
          nextLabel: l10n.nextBadge,
        ),
      );
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

class _DepartureRow extends ConsumerWidget {
  const _DepartureRow({
    required this.route,
    required this.date,
    required this.today,
    required this.departure,
    required this.isNext,
    required this.isPast,
    required this.nextLabel,
  });

  final TransportRoute route;
  final CalendarDate date;
  final CalendarDate today;
  final Departure departure;
  final bool isNext;
  final bool isPast;
  final String nextLabel;

  String _shareText(AppLocalizations l10n) => ShareTexts.departure(
        l10n,
        routeTitle: l10n.fromTo(route.from, route.to),
        dayLabel: date == today || date == today.addDays(1)
            ? HomeTexts.relativeDay(l10n, date, today)
            : DateTexts.weekdayDayMonth(l10n, date),
        time: departure.time.toString(),
        arrival: departure.arrival?.toString(),
        note: departure.note,
      );

  Future<void> _toggleReminder(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await ref.read(departureRemindersProvider.notifier).toggle(
          routeId: route.id,
          date: date,
          time: departure.time,
          title: l10n.fromTo(route.from, route.to),
          body: l10n.reminderNotifBody(departure.time.toString(), DepartureReminder.minutesBefore),
        );
    final message = switch (result) {
      ReminderResult.added => l10n.reminderAdded(DepartureReminder.minutesBefore),
      ReminderResult.removed => l10n.reminderRemoved,
      ReminderResult.tooLate => l10n.reminderTooLate(DepartureReminder.minutesBefore),
      ReminderResult.denied => l10n.notificationPermissionDenied,
    };
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openActions(BuildContext context, WidgetRef ref, {required bool reminderSet}) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final text = _shareText(l10n);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: p.background,
      builder: (sheetContext) {
        void run(Future<void> Function() action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: Text(
                  '${l10n.fromTo(route.from, route.to)} · ${departure.time}',
                  style: AppTypography.label.copyWith(color: p.textHeading, fontWeight: FontWeight.w600),
                ),
              ),
              if (!isPast)
                ListTile(
                  key: const Key('departure_reminder_action'),
                  leading: AppIcon(reminderSet ? AppIcons.bellFilled : AppIcons.bell, size: 24, color: p.iconOrange),
                  title: Text(
                    reminderSet
                        ? l10n.reminderRemoveAction
                        : l10n.reminderAction(DepartureReminder.minutesBefore),
                  ),
                  onTap: () => run(() => _toggleReminder(context, ref)),
                ),
              ListTile(
                key: const Key('departure_whatsapp_action'),
                leading: AppIcon(AppIcons.whatsapp, size: 24, color: const Color(0xFF128C4B)),
                title: Text(l10n.shareWhatsApp),
                onTap: () => run(() => shareToWhatsApp(ref, text)),
              ),
              ListTile(
                leading: AppIcon(AppIcons.share, size: 24, color: p.iconBlue),
                title: Text(l10n.shareOther),
                onTap: () => run(() => ref.read(systemBridgeProvider).share(text)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final color = isNext ? p.primary : (isPast ? p.textSecondary : p.textBody);
    final reminderSet = ref
        .watch(departureRemindersProvider)
        .any((r) => r.matches(route.id, date, departure.time));

    return Material(
      color: isNext ? p.primarySoft : Colors.transparent,
      child: InkWell(
        onTap: () => _openActions(context, ref, reminderSet: reminderSet),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
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
              if (isPast)
                const SizedBox(width: AppSpacing.minTouchTarget, height: AppSpacing.minTouchTarget)
              else
                IconButton(
                  key: Key('departure_bell_${departure.time}'),
                  tooltip: reminderSet
                      ? l10n.reminderRemoveAction
                      : l10n.reminderAction(DepartureReminder.minutesBefore),
                  onPressed: () => _toggleReminder(context, ref),
                  icon: AppIcon(
                    reminderSet ? AppIcons.bellFilled : AppIcons.bell,
                    size: 22,
                    color: reminderSet ? p.iconOrange : p.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

AppIconData modeIcon(TransportMode mode) => switch (mode) {
      TransportMode.ferry => AppIcons.ferry,
      TransportMode.bus => AppIcons.bus,
      TransportMode.city => AppIcons.cityBus,
    };
