import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/shell/app_tab.dart';
import '../../../core/data/data_result.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/erdek_time.dart';
import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../ads/data/ads_repository.dart';
import '../../ads/presentation/ad_slot.dart';
import '../../announcements/data/announcements_repository.dart';
import '../../announcements/data/announcements_seen.dart';
import '../../announcements/domain/announcement.dart';
import '../../contacts/presentation/directory_selection.dart';
import '../../explore/data/explore_repository.dart';
import '../../explore/presentation/history_screen.dart';
import '../../explore/presentation/places_screen.dart';
import '../../pharmacy/data/pharmacy_repository.dart';
import '../../pharmacy/domain/duty_schedule.dart';
import '../../pharmacy/domain/pharmacy.dart';
import '../../search/presentation/search_screen.dart';
import '../../prayer/data/prayer_repository.dart';
import '../../prayer/domain/prayer_times.dart';
import '../../transport/data/transport_repository.dart';
import '../../transport/domain/transport.dart';
import '../../transport/presentation/transport_selection.dart';
import '../../weather/data/weather_repository.dart';
import '../../weather/domain/weather.dart';
import 'home_texts.dart';

const _heroImage = AssetImage('assets/images/hero_erdek.jpg');

/// Ana sayfa. Tasarım: design/02_ana_sayfa_v2.png (yalnızca görsel stil).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onOpenTab, required this.onOpenMenu});

  final ValueChanged<AppTab> onOpenTab;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();

    final pharmacy = ref.watch(pharmacyDataProvider);
    final prayer = ref.watch(prayerTimesProvider);
    final transport = ref.watch(transportDataProvider);
    final announcements = ref.watch(announcementsProvider);
    final weather = ref.watch(currentWeatherProvider);
    final lastSeen = ref.watch(announcementsLastSeenProvider);
    final placeCount = ref.watch(placesDataProvider).value?.data.places.length;
    final periodCount = ref.watch(historyDataProvider).value?.data.sections.length;

    final unread = announcements.value?.data
            .activeAt(now)
            .where((a) => lastSeen == null || a.publishedAt.isAfter(lastSeen))
            .length ??
        0;
    final showSampleBanner = [pharmacy.value, prayer.value, transport.value]
        .any((r) => r?.isSample ?? false);

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(pharmacyDataProvider)
          ..invalidate(prayerTimesProvider)
          ..invalidate(transportDataProvider)
          ..invalidate(announcementsProvider)
          ..invalidate(currentWeatherProvider)
          ..invalidate(activeAdsProvider);
        try {
          await ref.read(pharmacyDataProvider.future);
        } catch (_) {
          // Hata kartlarda gösterilir; yenileme göstergesi yine kapanmalı.
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(
              now: now,
              weather: weather,
              others: [pharmacy, prayer],
              unread: unread,
              onMenu: onOpenMenu,
              onBell: () => _openAnnouncements(ref),
              onSearch: () => openSearch(context, onOpenTab),
            ),
            if (showSampleBanner) ...[
              const SizedBox(height: AppSpacing.md),
              InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
            ],
            const SizedBox(height: AppSpacing.section),
            SectionHeader(
              title: l10n.quickActionsTitle,
              actionLabel: l10n.seeAll,
              onAction: () => _showAllServices(context, ref),
            ),
            const SizedBox(height: AppSpacing.md),
            QuickActionGrid(columns: 3, children: _chips(context, ref)),
            const SizedBox(height: AppSpacing.gap),
            QuickActionGrid(columns: 4, children: _tiles(context, ref)),
            const SizedBox(height: AppSpacing.section),
            const AdSlot(
              id: 'home_feed_1',
              padding: EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.section,
              ),
            ),
            SectionHeader(
              title: l10n.cityServicesTitle,
              accentColor: context.palette.accentRed,
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _PharmacyCard(
                            now: now,
                            result: pharmacy,
                            onOpen: () => onOpenTab(AppTab.pharmacy),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.gap),
                        Expanded(
                          child: _NextPrayerCard(
                            now: now,
                            result: prayer,
                            onOpen: () => onOpenTab(AppTab.prayer),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _NextDepartureCard(
                            now: now,
                            result: transport,
                            mode: TransportMode.ferry,
                            onOpen: () => _openTransport(ref, TransportMode.ferry),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.gap),
                        Expanded(
                          child: _NextDepartureCard(
                            now: now,
                            result: transport,
                            mode: TransportMode.bus,
                            onOpen: () => _openTransport(ref, TransportMode.bus),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            SectionHeader(title: l10n.exploreTitle),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: AppSpacing.pagePadding,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ExploreCard(
                        icon: AppIcons.places,
                        color: context.palette.aqua.foreground,
                        title: l10n.placesTitle,
                        subtitle: placeCount == null ? l10n.placesSubtitle : l10n.placesCount(placeCount),
                        onTap: () => openPlaces(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gap),
                    Expanded(
                      child: _ExploreCard(
                        icon: AppIcons.history,
                        color: context.palette.iconPurple,
                        title: l10n.historyTitle,
                        subtitle: periodCount == null ? l10n.historySubtitle : l10n.historyCount(periodCount),
                        onTap: () => openHistory(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n.weatherAttribution,
              textAlign: TextAlign.center,
              style: AppTypography.tabLabel.copyWith(color: context.palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Ulaşım sekmesini istenen türde (feribot/otobüs) açar.
  void _openTransport(WidgetRef ref, TransportMode mode) {
    ref.read(transportSelectionProvider.notifier).selectMode(mode);
    onOpenTab(AppTab.transport);
  }

  void _openAnnouncements(WidgetRef ref, [AnnouncementCategory? category]) {
    ref.read(directorySelectionProvider.notifier).showAnnouncements(category);
    onOpenTab(AppTab.directory);
  }

  void _openContacts(WidgetRef ref) {
    ref.read(directorySelectionProvider.notifier).showContacts();
    onOpenTab(AppTab.directory);
  }

  List<Widget> _chips(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return [
      QuickActionChip(
        icon: AppIcons.pharmacy,
        label: l10n.actionPharmacy,
        tone: p.peach,
        onTap: () => onOpenTab(AppTab.pharmacy),
      ),
      QuickActionChip(
        icon: AppIcons.prayer,
        label: l10n.actionPrayerTimes,
        tone: p.mint,
        onTap: () => onOpenTab(AppTab.prayer),
      ),
      QuickActionChip(
        icon: AppIcons.ferry,
        label: l10n.actionFerryTimes,
        tone: p.aqua,
        onTap: () => _openTransport(ref, TransportMode.ferry),
      ),
    ];
  }

  List<Widget> _tiles(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return [
      QuickActionTile(
        icon: AppIcons.announcements,
        label: l10n.actionAnnouncements,
        iconColor: p.iconPurple,
        onTap: () => _openAnnouncements(ref),
      ),
      QuickActionTile(
        icon: AppIcons.contacts,
        label: l10n.actionContacts,
        iconColor: p.iconBlue,
        onTap: () => _openContacts(ref),
      ),
      QuickActionTile(
        icon: AppIcons.bus,
        label: l10n.actionBusTimes,
        iconColor: p.iconPurple,
        onTap: () => _openTransport(ref, TransportMode.bus),
      ),
      QuickActionTile(
        icon: AppIcons.imsakiye,
        label: l10n.actionImsakiye,
        iconColor: p.iconRed,
        onTap: () => onOpenTab(AppTab.prayer),
      ),
      QuickActionTile(
        icon: AppIcons.outage,
        label: l10n.actionOutages,
        iconColor: p.iconCrimson,
        onTap: () => _openAnnouncements(ref, AnnouncementCategory.outage),
      ),
      QuickActionTile(
        icon: AppIcons.market,
        label: l10n.actionMarketDays,
        iconColor: p.iconPurple,
        onTap: () => _openAnnouncements(ref, AnnouncementCategory.market),
      ),
      QuickActionTile(
        icon: AppIcons.event,
        label: l10n.actionEvents,
        iconColor: p.iconOrange,
        onTap: () => _openAnnouncements(ref, AnnouncementCategory.event),
      ),
      QuickActionTile(
        icon: AppIcons.emergency,
        label: l10n.actionEmergency,
        iconColor: p.iconCoral,
        onTap: () => launchOrNotify(context, () => Launchers.call('112')),
      ),
    ];
  }

  void _showAllServices(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.background,
      showDragHandle: true,
      builder: (sheetContext) {
        void close(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SectionHeader(title: l10n.allServicesTitle),
                const SizedBox(height: AppSpacing.md),
                QuickActionGrid(
                  columns: 3,
                  children: [
                    for (final w in _chips(context, ref).cast<QuickActionChip>())
                      QuickActionChip(
                        icon: w.icon,
                        label: w.label,
                        tone: w.tone,
                        onTap: () => close(w.onTap ?? () {}),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gap),
                QuickActionGrid(
                  columns: 4,
                  children: [
                    for (final w in _tiles(context, ref).cast<QuickActionTile>())
                      QuickActionTile(
                        icon: w.icon,
                        label: w.label,
                        iconColor: w.iconColor,
                        onTap: () => close(w.onTap ?? () {}),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.now,
    required this.weather,
    required this.others,
    required this.unread,
    required this.onMenu,
    required this.onBell,
    required this.onSearch,
  });

  final DateTime now;
  final AsyncValue<DataResult<CurrentWeather>> weather;
  final List<AsyncValue<DataResult<Object>>> others;
  final int unread;
  final VoidCallback onMenu;
  final VoidCallback onBell;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = weather.value;
    final today = CalendarDate.fromDateTime(now);

    // Durum: herhangi bir kaynak çevrimdışıysa en eski güncelleme saatini göster.
    final offline = [weather.value, ...others.map((o) => o.value)]
        .whereType<DataResult<Object>>()
        .where((r) => r.isOffline)
        .toList();
    final String status;
    if (offline.isNotEmpty) {
      final at = offline.map((r) => r.fetchedAt ?? r.updatedAt).reduce((a, b) => a.isBefore(b) ? a : b);
      status = l10n.statusOffline(ErdekTime.hhmm(ErdekTime.toErdek(at)));
    } else if (weather.isLoading && w == null) {
      status = l10n.statusUpdating;
    } else {
      status = l10n.statusUpToDate;
    }

    HeroWeather? heroWeather;
    if (w != null) {
      final data = w.data;
      heroWeather = HeroWeather(
        temperature: data.roundedTemperature,
        symbolCode: data.symbolCode,
        description: data.descriptionTr,
        humidityLabel: data.relativeHumidity == null
            ? null
            : l10n.humidityLabel(data.relativeHumidity!.round()),
        windLabel: data.windSpeedKmh == null ? null : l10n.windLabel(data.windSpeedKmh!),
        rangeLabel: data.minTemperatureC == null || data.maxTemperatureC == null
            ? null
            : l10n.temperatureRange(data.minTemperatureC!.round(), data.maxTemperatureC!.round()),
      );
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.searchHeight / 2),
          child: HeroHeader(
            image: _heroImage,
            greeting: HomeTexts.greeting(l10n, now.hour),
            dayLabel: l10n.heroDayLabel(l10n.weekdayName('${today.weekday}')),
            locationLabel: l10n.locationLabel,
            statusLabel: status,
            menuLabel: l10n.menu,
            weather: heroWeather,
            onMenu: onMenu,
            bell: NotificationBell(
              count: unread,
              tooltip: l10n.announcementsTooltip,
              onTap: onBell,
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.page,
          right: AppSpacing.page,
          bottom: 0,
          child: AppSearchBar(hint: l10n.searchHint, onTap: onSearch),
        ),
      ],
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({required this.now, required this.result, required this.onOpen});

  final DateTime now;
  final AsyncValue<DataResult<PharmacyData>> result;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = result.value?.data;
    if (data == null && !result.hasError) {
      return const SkeletonBox(height: 220, radius: AppRadius.card);
    }

    final dutyDate = dutyDateFor(now);
    final onDuty = data?.onDutyFor(dutyDate) ?? const <Pharmacy>[];

    if (onDuty.isEmpty) {
      return FeatureCard(
        icon: AppIcons.pill,
        overline: l10n.pharmacyOverline,
        title: l10n.pharmacyNoneTitle,
        subtitle: l10n.pharmacyNoneSubtitle,
        onTap: onOpen,
        actions: [
          CardAction(
            icon: AppIcons.call,
            label: l10n.actionEmergency,
            onTap: () => launchOrNotify(context, () => Launchers.call('112')),
          ),
        ],
      );
    }

    final first = onDuty.first;
    // 08:30'dan sonra bugünün nöbetçisi yarın 08:30'a kadar; gece ise bugün 08:30'a kadar.
    final untilTomorrow = dutyDate == CalendarDate.fromDateTime(now);
    final subtitleParts = [
      if (untilTomorrow) l10n.pharmacyUntilTomorrow else l10n.pharmacyUntilToday,
      first.address,
      if (onDuty.length > 1) l10n.pharmacyMore(onDuty.length - 1),
    ];

    return FeatureCard(
      icon: AppIcons.pill,
      overline: l10n.pharmacyOverline,
      title: first.name,
      subtitle: subtitleParts.join('\n'),
      tagLabel: l10n.pharmacyTag,
      tagIcon: AppIcons.clock,
      footnote: l10n.pharmacyConfirm,
      onTap: onOpen,
      actions: [
        CardAction(
          icon: AppIcons.call,
          label: l10n.call,
          onTap: () => launchOrNotify(context, () => Launchers.call(first.phone)),
        ),
        CardAction(
          icon: AppIcons.directions,
          label: l10n.directions,
          onTap: () => launchOrNotify(
            context,
            () => Launchers.directions(
              name: first.name,
              address: first.address,
              latitude: first.latitude,
              longitude: first.longitude,
            ),
          ),
        ),
      ],
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({required this.now, required this.result, required this.onOpen});

  final DateTime now;
  final AsyncValue<DataResult<PrayerTimesData>> result;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = result.value?.data;
    if (data == null && !result.hasError) {
      return const SkeletonBox(height: 220, radius: AppRadius.card);
    }
    final next = data == null ? null : findNextPrayer(data, now);
    return InfoCard(
      title: l10n.nextPrayerTitle,
      icon: AppIcons.prayer,
      label: next == null ? l10n.noData : l10n.prayerName(next.name.jsonKey),
      value: next?.time.toString() ?? l10n.noData,
      footnote: next == null ? null : HomeTexts.remaining(l10n, next.remaining),
      onTap: onOpen,
    );
  }
}

class _NextDepartureCard extends StatelessWidget {
  const _NextDepartureCard({
    required this.now,
    required this.result,
    required this.mode,
    required this.onOpen,
  });

  final DateTime now;
  final AsyncValue<DataResult<TransportData>> result;
  final TransportMode mode;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = result.value?.data;
    if (data == null && !result.hasError) {
      return const SkeletonBox(height: 170, radius: AppRadius.card);
    }

    UpcomingDeparture? next;
    // Yalnızca Erdek'ten kalkan hatlar (dönüş seferleri değil).
    for (final route in data?.outboundByMode(mode) ?? const <TransportRoute>[]) {
      final candidate = upcomingDepartures(route, now, limit: 1).firstOrNull;
      if (candidate == null) continue;
      if (next == null ||
          candidate.date.isBefore(next.date) ||
          (candidate.date == next.date &&
              candidate.departure.time.compareTo(next.departure.time) < 0)) {
        next = candidate;
      }
    }

    final isFerry = mode == TransportMode.ferry;
    return InfoCard(
      title: isFerry ? l10n.nextFerryTitle : l10n.nextBusTitle,
      icon: isFerry ? AppIcons.ferry : AppIcons.bus,
      label: next?.route.to ?? l10n.noDeparture,
      value: next?.departure.time.toString() ?? l10n.noData,
      footnote: next == null
          ? null
          : HomeTexts.relativeDay(l10n, next.date, CalendarDate.fromDateTime(now)),
      onTap: onOpen,
    );
  }
}

/// "Keşfet" bölümündeki kart: renkli ikon kutusu + başlık + alt satır.
class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: AppRadius.tileAll,
                      ),
                      child: AppIcon(icon, size: 28, color: color),
                    ),
                    const Spacer(),
                    AppIcon(AppIcons.arrowRight, size: 18, color: p.textSecondary),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.label.copyWith(
                    color: p.textHeading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
