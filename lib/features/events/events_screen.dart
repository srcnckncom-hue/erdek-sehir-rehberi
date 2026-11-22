import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/system/system_bridge.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/time/calendar_date.dart';
import '../../core/util/date_texts.dart';
import '../../core/util/launch_or_notify.dart';
import '../../core/util/launchers.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../explore/presentation/place_photos.dart';
import '../home/presentation/home_texts.dart';
import '../reminders/departure_reminders.dart' show ReminderResult;
import '../share/share_actions.dart';
import 'event_reminders.dart';
import 'events.dart';

Future<void> openEvents(BuildContext context, {VoidCallback? onOpenAnnouncements}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EventsScreen(onOpenAnnouncements: onOpenAnnouncements)),
    );

Future<void> openEvent(BuildContext context, CityEvent event) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EventDetailScreen(event: event)),
    );

abstract final class EventStyle {
  static AppIconData icon(EventCategory c) => switch (c) {
        EventCategory.concert => AppIcons.eventConcert,
        EventCategory.festival => AppIcons.event,
        EventCategory.culture => AppIcons.eventCulture,
        EventCategory.sport => AppIcons.eventSport,
        EventCategory.kids => AppIcons.eventKids,
        EventCategory.market => AppIcons.market,
        EventCategory.other => AppIcons.eventOther,
      };

  static Color color(AppPalette p, EventCategory c) => switch (c) {
        EventCategory.concert => p.iconPurple,
        EventCategory.festival => p.iconOrange,
        EventCategory.culture => p.iconBlue,
        EventCategory.sport => p.mint.foreground,
        EventCategory.kids => p.iconCoral,
        EventCategory.market => p.iconCrimson,
        EventCategory.other => p.aqua.foreground,
      };

  static String label(AppLocalizations l10n, EventCategory c) => switch (c) {
        EventCategory.concert => l10n.eventCatConcert,
        EventCategory.festival => l10n.eventCatFestival,
        EventCategory.culture => l10n.eventCatCulture,
        EventCategory.sport => l10n.eventCatSport,
        EventCategory.kids => l10n.eventCatKids,
        EventCategory.market => l10n.eventCatMarket,
        EventCategory.other => l10n.eventCatOther,
      };

  /// "20:30" · "20:30–23:00" · "Tüm gün"; çok günlüde "22 Kasım – 24 Kasım".
  static String when(AppLocalizations l10n, CityEvent e) {
    final time = switch ((e.startTime, e.endTime)) {
      (final s?, final f?) => '$s–$f',
      (final s?, null) => '$s',
      _ => l10n.eventAllDay,
    };
    if (!e.isMultiDay) return time;
    final range = '${DateTexts.dayMonth(l10n, e.date)} – ${DateTexts.dayMonth(l10n, e.lastDay)}';
    return e.isAllDay ? range : '$range · $time';
  }
}

/// Yaklaşan etkinlikler: türe göre süzgeç, güne göre gruplu liste.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key, this.onOpenAnnouncements});

  /// Verilirse altta "Etkinlik duyuruları" bağlantısı (Rehber › Duyurular).
  final VoidCallback? onOpenAnnouncements;

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  EventCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final today = CalendarDate.fromDateTime(now);
    final result = ref.watch(eventsDataProvider);
    final data = result.value?.data;
    final upcoming = data?.upcoming(now) ?? const <CityEvent>[];
    final categories = data?.categoriesIn(upcoming) ?? const <EventCategory>[];
    final filter = categories.contains(_filter) ? _filter : null;
    final shown = [for (final e in upcoming) if (filter == null || e.category == filter) e];

    final groups = <CalendarDate, List<CityEvent>>{};
    for (final e in shown) {
      groups.putIfAbsent(e.listDay(today), () => []).add(e);
    }
    final days = groups.keys.toList()..sort((a, b) => a.compareTo(b));

    final children = <Widget>[
      PageHeader(
        title: l10n.eventsTitle,
        subtitle: l10n.eventsSubtitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.back,
      ),
      if (result.value?.isSample ?? false) ...[
        InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
        const SizedBox(height: AppSpacing.md),
      ],
      if (categories.length > 1) ...[
        PillChoiceRow(
          key: const Key('events_filter'),
          items: [
            PillChoice(
              label: l10n.eventsAll(upcoming.length),
              selected: filter == null,
              onTap: () => setState(() => _filter = null),
            ),
            for (final c in categories)
              PillChoice(
                label: '${EventStyle.label(l10n, c)} (${upcoming.where((e) => e.category == c).length})',
                selected: filter == c,
                onTap: () => setState(() => _filter = c),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];

    if (data == null && !result.hasError) {
      children.add(const Padding(
        padding: AppSpacing.pagePadding,
        child: SkeletonBox(height: 120, radius: AppRadius.card),
      ));
    } else if (shown.isEmpty) {
      children.add(MessageView(
        key: const Key('events_empty'),
        icon: AppIcons.event,
        iconColor: p.iconOrange,
        title: l10n.eventsEmptyTitle,
        message: l10n.eventsEmptyMessage,
      ));
    } else {
      for (final day in days) {
        final relative = HomeTexts.relativeDay(l10n, day, today);
        final full = DateTexts.weekdayDayMonth(l10n, day);
        children.addAll([
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: relative == full ? full : '$relative · $full'),
          const SizedBox(height: AppSpacing.sm),
          for (final e in groups[day]!) ...[
            EventCard(event: e, now: now),
            const SizedBox(height: AppSpacing.sm),
          ],
        ]);
      }
    }

    if (widget.onOpenAnnouncements case final open?) {
      children.addAll([
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton.icon(
            key: const Key('events_announcements'),
            onPressed: () {
              Navigator.of(context).pop();
              open();
            },
            icon: AppIcon(AppIcons.announcements, size: 18, color: p.primary),
            label: Text(l10n.eventsAnnouncementsLink),
          ),
        ),
      ]);
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: children,
      ),
    );
  }
}

/// Listede bir etkinlik: fotoğraf/ikon, ad, saat · yer, tür.
class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.event, required this.now});

  final CityEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final color = EventStyle.color(p, event.category);
    final reminded = ref.watch(eventRemindersProvider).any((r) => r.eventId == event.id);
    final icon = ColoredBox(
      color: color.withValues(alpha: 0.12),
      child: Center(child: AppIcon(EventStyle.icon(event.category), size: 28, color: color)),
    );
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Material(
        color: p.surface,
        borderRadius: AppRadius.cardAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('event_${event.id}'),
          onTap: () => openEvent(context, event),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.tileAll,
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: event.photos.isEmpty
                        ? icon
                        : PlacePhotoImage(url: event.photos.first.url, fallback: icon),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(color: p.textHeading),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [EventStyle.when(l10n, event), ?event.place].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: p.textBody),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Text(
                            event.isOnAt(now) ? l10n.eventNow : EventStyle.label(l10n, event.category),
                            style: AppTypography.tabLabel.copyWith(
                              color: event.isOnAt(now) ? p.accentRed : color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (reminded) ...[
                            const SizedBox(width: AppSpacing.sm),
                            AppIcon(AppIcons.bellFilled, size: 14, color: p.iconOrange),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                AppIcon(AppIcons.arrowRight, size: 18, color: p.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Etkinlik ayrıntısı: fotoğraflar, tarih/saat, yer, açıklama, eylemler.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.event});

  final CityEvent event;

  Future<void> _addToCalendar(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final e = event;
    final result = await ref.read(systemBridgeProvider).addToCalendar(
          CalendarEntry(
            title: e.title,
            start: e.isAllDay ? DateTime(e.date.year, e.date.month, e.date.day) : e.startsAt,
            end: e.isAllDay
                ? DateTime(e.lastDay.year, e.lastDay.month, e.lastDay.day, 23, 59)
                : e.endsAt,
            allDay: e.isAllDay,
            location: e.place == null ? null : '${e.place}, Erdek',
            notes: [?e.summary, ...e.paragraphs, ?e.organizer].join('\n\n'),
            url: e.link,
          ),
        );
    final message = switch (result) {
      CalendarResult.saved => l10n.eventCalendarSaved,
      CalendarResult.canceled => null,
      CalendarResult.denied => l10n.eventCalendarDenied,
      CalendarResult.unavailable => l10n.cannotOpen,
    };
    if (message != null) messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleReminder(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await ref.read(eventRemindersProvider.notifier).toggle(
          event,
          title: event.title,
          body: event.isAllDay
              ? l10n.eventReminderBodyAllDay(event.place ?? 'Erdek')
              : l10n.eventReminderBody(event.startTime.toString(), event.place ?? 'Erdek'),
        );
    final message = switch (result) {
      ReminderResult.added => event.isAllDay ? l10n.eventReminderAddedAllDay : l10n.eventReminderAdded,
      ReminderResult.removed => l10n.reminderRemoved,
      ReminderResult.tooLate => l10n.eventReminderTooLate,
      ReminderResult.denied => l10n.notificationPermissionDenied,
    };
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _shareText(AppLocalizations l10n) {
    final e = event;
    return [
      e.title,
      '${DateTexts.weekdayDayMonth(l10n, e.date)} · ${EventStyle.when(l10n, e)}',
      ?e.place,
      if (e.latitude != null && e.longitude != null)
        l10n.shareMapLine(ShareTexts.mapsUrl(name: e.place ?? e.title, latitude: e.latitude, longitude: e.longitude)),
      ?e.link,
      '— ${l10n.appTitle}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final e = event;
    final color = EventStyle.color(p, e.category);
    final reminded = ref.watch(eventRemindersProvider).any((r) => r.eventId == e.id);
    final hasLocation = e.latitude != null && e.longitude != null;

    Widget infoRow(AppIconData icon, String text, {String? sub}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(icon, size: 22, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: AppTypography.label.copyWith(color: p.textHeading)),
                    if (sub != null) Text(sub, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );

    Widget action(Key key, AppIconData icon, String label, VoidCallback onTap, {bool filled = false}) => Expanded(
          child: filled
              ? FilledButton.icon(
                  key: key,
                  onPressed: onTap,
                  icon: AppIcon(icon, size: 18, color: p.onPrimary),
                  label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                )
              : OutlinedButton.icon(
                  key: key,
                  onPressed: onTap,
                  icon: AppIcon(icon, size: 18, color: p.primary),
                  label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
        );

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: e.title,
            subtitle: EventStyle.label(l10n, e.category),
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          _EventGallery(event: e),
          const SizedBox(height: AppSpacing.md),
          GroupedCard(
            children: [
              infoRow(
                AppIcons.imsakiye,
                e.isMultiDay
                    ? '${DateTexts.weekdayDayMonth(l10n, e.date)} – ${DateTexts.weekdayDayMonth(l10n, e.lastDay)}'
                    : DateTexts.weekdayDayMonth(l10n, e.date),
                sub: e.isAllDay ? l10n.eventAllDay : EventStyle.when(l10n, e).split(' · ').last,
              ),
              if (e.place case final place?) infoRow(AppIcons.mapPin, place),
              if (e.organizer case final org?) infoRow(AppIcons.ticket, org, sub: l10n.eventOrganizer),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Row(
              children: [
                action(const Key('event_calendar'), AppIcons.calendarAdd, l10n.eventAddToCalendar,
                    () => unawaited(_addToCalendar(context, ref)),
                    filled: true),
                const SizedBox(width: AppSpacing.sm),
                action(
                  const Key('event_remind'),
                  reminded ? AppIcons.bellFilled : AppIcons.bell,
                  reminded ? l10n.eventReminderOn : l10n.eventRemind,
                  () => unawaited(_toggleReminder(context, ref)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Row(
              children: [
                if (hasLocation) ...[
                  action(
                    const Key('event_directions'),
                    AppIcons.directions,
                    l10n.directions,
                    () => unawaited(launchOrNotify(
                      context,
                      () => Launchers.directions(name: e.place ?? e.title, latitude: e.latitude, longitude: e.longitude),
                    )),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                action(
                  const Key('event_share'),
                  AppIcons.whatsapp,
                  l10n.shareWhatsApp,
                  () => unawaited(shareToWhatsApp(ref, _shareText(l10n))),
                ),
              ],
            ),
          ),
          if (e.summary != null || e.paragraphs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (e.summary case final s?)
                    Text(s, style: AppTypography.body.copyWith(color: p.textHeading, fontWeight: FontWeight.w600)),
                  for (final para in e.paragraphs) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(para, style: AppTypography.body.copyWith(color: p.textBody)),
                  ],
                ],
              ),
            ),
          ],
          if (e.link case final link?) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: AppSpacing.pagePadding,
              child: OutlinedButton.icon(
                key: const Key('event_link'),
                onPressed: () => unawaited(launchOrNotify(context, () => Launchers.openUrl(link))),
                icon: AppIcon(AppIcons.globe, size: 18, color: p.primary),
                label: Text(l10n.eventMoreInfo),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventGallery extends StatefulWidget {
  const _EventGallery({required this.event});

  final CityEvent event;

  @override
  State<_EventGallery> createState() => _EventGalleryState();
}

class _EventGalleryState extends State<_EventGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final e = widget.event;
    final color = EventStyle.color(p, e.category);
    final fallback = ColoredBox(
      color: color.withValues(alpha: 0.12),
      child: Center(child: AppIcon(EventStyle.icon(e.category), size: 56, color: color)),
    );
    if (e.photos.isEmpty) {
      return Padding(
        padding: AppSpacing.pagePadding,
        child: ClipRRect(borderRadius: AppRadius.cardAll, child: SizedBox(height: 120, child: fallback)),
      );
    }
    final credit = e.photos[_page.clamp(0, e.photos.length - 1)].credit;
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: e.photos.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => PlacePhotoImage(
                      url: e.photos[i].url,
                      fallback: fallback,
                      semanticLabel: l10n.placePhotoLabel(e.title),
                    ),
                  ),
                  if (e.photos.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: AppSpacing.md,
                      child: IgnorePointer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < e.photos.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _page ? 18 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: i == _page ? 1 : 0.6),
                                  borderRadius: AppRadius.pillAll,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (credit != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.placePhotoCredit(credit), style: AppTypography.tabLabel.copyWith(color: p.textSecondary)),
          ],
        ],
      ),
    );
  }
}
