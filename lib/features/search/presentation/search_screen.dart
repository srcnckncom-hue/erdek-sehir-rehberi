import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/shell/app_tab.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../announcements/data/announcements_repository.dart';
import '../../announcements/presentation/announcements_view.dart';
import '../../businesses/data/businesses_repository.dart';
import '../../businesses/presentation/business_detail_screen.dart';
import '../../businesses/presentation/businesses_screen.dart';
import '../../contacts/domain/contacts.dart';
import '../../emergency/emergency.dart';
import '../../emergency/emergency_screen.dart';
import '../../explore/presentation/history_screen.dart';
import '../../explore/presentation/places_screen.dart';
import '../../favorites/favorites_screen.dart';
import '../../map/map_screen.dart';
import '../../nearby/nearby_screen.dart';
import '../../ramadan/ramadan_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../transport/domain/transport.dart';
import '../../weather/presentation/weather_screen.dart';
import '../../contacts/data/contacts_repository.dart';
import '../../contacts/presentation/directory_selection.dart';
import '../../explore/data/explore_repository.dart';
import '../../explore/presentation/place_detail_screen.dart';
import '../../explore/presentation/place_style.dart';
import '../../pharmacy/data/pharmacy_repository.dart';
import '../../transport/data/transport_repository.dart';
import '../../transport/presentation/transport_screen.dart' show modeIcon;
import '../../transport/presentation/transport_selection.dart';
import '../domain/search_index.dart';
import '../recent_searches.dart';

Future<void> openSearch(BuildContext context, ValueChanged<AppTab> onOpenTab) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SearchScreen(onOpenTab: onOpenTab)),
    );

/// Cihaz içi arama: sayfalar, acil hatlar, eczane, işletme, telefon, sefer,
/// gezilecek yer ve duyurular. Boşken son aramalar ve öneriler.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.onOpenTab});

  final ValueChanged<AppTab> onOpenTab;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Ekranı kapatıp ilgili sekmeye geçer.
  void _go(AppTab tab, [void Function()? prepare]) {
    _remember();
    prepare?.call();
    Navigator.of(context).pop();
    widget.onOpenTab(tab);
  }

  /// Arama ekranının üstüne bir sayfa açar (geri gelince arama duruyor).
  void _push(Future<void> Function(BuildContext) open) {
    _remember();
    unawaited(open(context));
  }

  void _remember() => unawaited(ref.read(recentSearchesProvider.notifier).add(_query));

  void _setQuery(String q) {
    _controller
      ..text = q
      ..selection = TextSelection.collapsed(offset: q.length);
    setState(() => _query = q);
  }

  Map<SearchPage, String> _pageTitles(AppLocalizations l10n) => {
        SearchPage.emergency: l10n.emergencyScreenTitle,
        SearchPage.pharmacy: l10n.actionPharmacy,
        SearchPage.prayer: l10n.tabPrayer,
        SearchPage.ferry: l10n.actionFerryTimes,
        SearchPage.bus: l10n.actionBusTimes,
        SearchPage.weather: l10n.weatherTitle,
        SearchPage.wind: l10n.searchPageWind,
        SearchPage.sea: l10n.searchPageSea,
        SearchPage.map: l10n.mapTitle,
        SearchPage.nearby: l10n.nearbyTitle,
        SearchPage.favorites: l10n.favoritesTitle,
        SearchPage.ramadan: l10n.ramadanTitle,
        SearchPage.businesses: l10n.businessesTitle,
        SearchPage.places: l10n.placesTitle,
        SearchPage.history: l10n.historyTitle,
        SearchPage.settings: l10n.settingsTitle,
      };

  AppIconData _pageIcon(SearchPage page) => switch (page) {
        SearchPage.emergency => AppIcons.emergency,
        SearchPage.pharmacy => AppIcons.pharmacy,
        SearchPage.prayer => AppIcons.prayer,
        SearchPage.ferry => AppIcons.ferry,
        SearchPage.bus => AppIcons.bus,
        SearchPage.weather => AppIcons.forecast,
        SearchPage.wind => AppIcons.wind,
        SearchPage.sea => AppIcons.sea,
        SearchPage.map => AppIcons.map,
        SearchPage.nearby => AppIcons.nearby,
        SearchPage.favorites => AppIcons.favoriteOn,
        SearchPage.ramadan => AppIcons.ramadan,
        SearchPage.businesses => AppIcons.businesses,
        SearchPage.places => AppIcons.places,
        SearchPage.history => AppIcons.history,
        SearchPage.settings => AppIcons.settings,
      };

  void _openPage(SearchPage page) {
    switch (page) {
      case SearchPage.emergency:
        _push(openEmergency);
      case SearchPage.pharmacy:
        _go(AppTab.pharmacy);
      case SearchPage.prayer:
        _go(AppTab.prayer);
      case SearchPage.ferry:
        _go(AppTab.transport, () => ref.read(transportSelectionProvider.notifier).selectMode(TransportMode.ferry));
      case SearchPage.bus:
        _go(AppTab.transport, () => ref.read(transportSelectionProvider.notifier).selectMode(TransportMode.bus));
      case SearchPage.weather:
        _push(openWeather);
      case SearchPage.wind:
        _push((c) => openWeather(c, tab: WeatherTab.wind));
      case SearchPage.sea:
        _push((c) => openWeather(c, tab: WeatherTab.sea));
      case SearchPage.map:
        _push(openMap);
      case SearchPage.nearby:
        _push(openNearby);
      case SearchPage.favorites:
        _push(openFavorites);
      case SearchPage.ramadan:
        _push(openRamadan);
      case SearchPage.businesses:
        _push(openBusinesses);
      case SearchPage.places:
        _push(openPlaces);
      case SearchPage.history:
        _push(openHistory);
      case SearchPage.settings:
        _push(openSettings);
    }
  }

  /// Sorgu boşken: son aramalar + öneriler.
  List<Widget> _idle(AppLocalizations l10n) {
    final p = context.palette;
    final recent = ref.watch(recentSearchesProvider);
    Widget chips(List<String> items, {required String keyPrefix}) => Padding(
          padding: AppSpacing.pagePadding,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final q in items)
                ActionChip(
                  key: Key('${keyPrefix}_$q'),
                  label: Text(q, style: AppTypography.caption.copyWith(color: p.textHeading)),
                  backgroundColor: p.surface,
                  side: BorderSide(color: p.divider),
                  shape: const StadiumBorder(),
                  onPressed: () => _setQuery(q),
                ),
            ],
          ),
        );
    return [
      if (recent.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: l10n.searchRecent,
          actionLabel: l10n.searchClearRecent,
          onAction: () => ref.read(recentSearchesProvider.notifier).clear(),
        ),
        const SizedBox(height: AppSpacing.sm),
        chips(recent, keyPrefix: 'search_recent'),
      ],
      const SizedBox(height: AppSpacing.lg),
      SectionHeader(title: l10n.searchSuggestions),
      const SizedBox(height: AppSpacing.sm),
      chips(l10n.searchSuggestionList.split('|'), keyPrefix: 'search_suggest'),
      const SizedBox(height: AppSpacing.lg),
      Padding(
        padding: AppSpacing.pagePadding,
        child: Text(l10n.searchEmptyPrompt, style: AppTypography.caption.copyWith(color: p.textSecondary)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(clockProvider)();

    final places = ref.watch(placesDataProvider).value;
    final businesses = ref.watch(businessesDataProvider).value;
    final results = searchAll(
      query: _query,
      now: now,
      pageTitles: _pageTitles(l10n),
      helpLines: [
        Contact(name: l10n.emergencyTitle, phone: Emergency.number, note: l10n.emergencyCallServices),
        for (final h in HelpLine.values) h.toContact(l10n),
      ],
      businesses: businesses?.data,
      pharmacy: ref.watch(pharmacyDataProvider).value?.data,
      contacts: ref.watch(contactsDataProvider).value?.data,
      transport: ref.watch(transportDataProvider).value?.data,
      announcements: ref.watch(announcementsProvider).value?.data,
      places: places?.data,
    );

    Widget section(String title, List<Widget> rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: title),
            const SizedBox(height: AppSpacing.sm),
            GroupedCard(children: rows),
          ],
        );

    final body = <Widget>[];
    if (_query.trim().length < 2) {
      body.addAll(_idle(l10n));
    } else if (results.isEmpty) {
      body.add(MessageView(icon: AppIcons.info, title: l10n.searchNoResults(_query.trim())));
    } else {
      if (results.pages.isNotEmpty) {
        body.add(section(l10n.searchSectionPages, [
          for (final page in results.pages)
            _ResultRow(
              key: Key('search_page_${page.name}'),
              icon: _pageIcon(page),
              color: page == SearchPage.emergency ? p.accentRed : p.primary,
              title: _pageTitles(l10n)[page]!,
              onTap: () => _openPage(page),
            ),
        ]));
      }
      if (results.helpLines.isNotEmpty) {
        body.add(section(l10n.searchSectionHelpLines, [
          for (final c in results.helpLines)
            _ResultRow(
              key: Key('search_help_${c.phone}'),
              icon: c.phone == Emergency.number ? AppIcons.emergency : AppIcons.call,
              color: p.accentRed,
              title: c.name,
              subtitle: Launchers.formatPhone(c.phone),
              onTap: () {
                _remember();
                unawaited(launchOrNotify(context, () => Launchers.call(c.phone)));
              },
            ),
        ]));
      }
      if (results.pharmacies.isNotEmpty) {
        body.add(section(l10n.searchSectionPharmacies, [
          for (final ph in results.pharmacies)
            _ResultRow(
              icon: AppIcons.pharmacy,
              color: p.accentRed,
              title: ph.name,
              subtitle: ph.address,
              onTap: () => _go(AppTab.pharmacy),
            ),
        ]));
      }
      if (results.businesses.isNotEmpty) {
        final env = businesses!;
        final data = env.data;
        final sample = env.isSample;
        body.add(section(l10n.searchSectionBusinesses, [
          for (final b in results.businesses)
            _ResultRow(
              key: Key('search_business_${b.id}'),
              icon: AppIcons.businesses,
              color: p.iconOrange,
              title: b.name,
              subtitle: data.categoryOf(b)?.title,
              onTap: () => _push(
                (c) => openBusiness(c, b, category: data.categoryOf(b), isSample: sample),
              ),
            ),
        ]));
      }
      if (results.contacts.isNotEmpty) {
        body.add(section(l10n.searchSectionContacts, [
          for (final c in results.contacts)
            _ResultRow(
              icon: AppIcons.contacts,
              color: p.iconBlue,
              title: c.name,
              subtitle: Launchers.formatPhone(c.phone),
              onTap: () {
                _remember();
                unawaited(launchOrNotify(context, () => Launchers.call(c.phone)));
              },
            ),
        ]));
      }
      if (results.routes.isNotEmpty) {
        body.add(section(l10n.searchSectionRoutes, [
          for (final r in results.routes)
            _ResultRow(
              icon: modeIcon(r.mode),
              color: p.aqua.foreground,
              title: r.title,
              subtitle: r.operatorName,
              onTap: () => _go(AppTab.transport, () {
                ref.read(transportSelectionProvider.notifier)
                  ..selectMode(r.mode)
                  ..selectRoute(r.id);
              }),
            ),
        ]));
      }
      if (results.places.isNotEmpty) {
        body.add(section(l10n.searchSectionPlaces, [
          for (final place in results.places)
            _ResultRow(
              icon: PlaceStyle.icon(place.category),
              color: PlaceStyle.color(p, place.category),
              title: place.title,
              subtitle: PlaceStyle.meta(l10n, place),
              onTap: () => _push((c) => openPlace(c, place, isSample: places?.isSample ?? false)),
            ),
        ]));
      }
      if (results.announcements.isNotEmpty) {
        body.add(section(l10n.searchSectionAnnouncements, [
          for (final a in results.announcements)
            _ResultRow(
              icon: AnnouncementCard.iconFor(a.category),
              color: AnnouncementCard.colorFor(p, a.category),
              title: a.title,
              subtitle: l10n.categoryName(a.category.jsonValue),
              onTap: () => _go(
                AppTab.directory,
                () => ref.read(directorySelectionProvider.notifier).showAnnouncements(a.category),
              ),
            ),
        ]));
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.xs, AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: AppRadius.pillAll,
                        boxShadow: AppShadows.raised(p.shadow),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (v) => setState(() => _query = v),
                        onSubmitted: (_) => _remember(),
                        style: AppTypography.body.copyWith(color: p.textBody),
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          hintStyle: AppTypography.body.copyWith(color: p.textSecondary),
                          border: InputBorder.none,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
                            child: AppIcon(AppIcons.search, size: 22, color: p.textSecondary),
                          ),
                          prefixIconConstraints: const BoxConstraints(minHeight: AppSpacing.searchHeight),
                          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg),
                children: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            AppIcon(icon, size: 24, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.label.copyWith(color: p.textHeading)),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                ],
              ),
            ),
            AppIcon(AppIcons.arrowRight, size: 18, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}
