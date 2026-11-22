import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../reminders/reminder_scheduler.dart';

/// Ana sayfadaki küçük kutucuklar. İlk [defaults] görünür; diğerleri
/// kullanıcı isterse eklenir (Ana sayfayı düzenle).
enum HomeTile {
  announcements,
  contacts,
  bus,
  imsakiye,
  outages,
  markets,
  events,
  emergency,
  favorites,
  beaches,
  trips,
  map,
  nearby,
  businesses,
  weather,
  places,
  erdekspor,
  ataturk;

  static const defaults = [announcements, contacts, bus, imsakiye, outages, markets, events, emergency];

  AppIconData get icon => switch (this) {
        announcements => AppIcons.announcements,
        contacts => AppIcons.contacts,
        bus => AppIcons.bus,
        imsakiye => AppIcons.imsakiye,
        outages => AppIcons.outage,
        markets => AppIcons.market,
        events => AppIcons.event,
        emergency => AppIcons.emergency,
        favorites => AppIcons.favoriteOn,
        beaches => AppIcons.placeBeach,
        trips => AppIcons.trips,
        map => AppIcons.map,
        nearby => AppIcons.nearby,
        businesses => AppIcons.businesses,
        weather => AppIcons.forecast,
        places => AppIcons.places,
        erdekspor => AppIcons.erdekspor,
        ataturk => AppIcons.ataturk,
      };

  Color color(AppPalette p) => switch (this) {
        announcements || bus || markets => p.iconPurple,
        contacts || map || nearby || weather || places => p.iconBlue,
        imsakiye => p.iconRed,
        outages => p.iconCrimson,
        events || favorites || businesses => p.iconOrange,
        emergency || erdekspor || ataturk => p.iconCoral,
        beaches => p.aqua.foreground,
        trips => p.mint.foreground,
      };

  String label(AppLocalizations l10n) => switch (this) {
        announcements => l10n.actionAnnouncements,
        contacts => l10n.actionContacts,
        bus => l10n.actionBusTimes,
        imsakiye => l10n.actionImsakiye,
        outages => l10n.actionOutages,
        markets => l10n.actionMarketDays,
        events => l10n.actionEvents,
        emergency => l10n.actionEmergency,
        favorites => l10n.favoritesTitle,
        beaches => l10n.beachesTitle,
        trips => l10n.tripsTitle,
        map => l10n.mapTitle,
        nearby => l10n.nearbyTitle,
        businesses => l10n.businessesTitle,
        weather => l10n.weatherTitle,
        places => l10n.placesTitle,
        erdekspor => l10n.erdeksporTitle,
        ataturk => l10n.ataturkTitle,
      };
}

/// Görünen kutucuklar, sırayla (cihazda; anahtar `home_tiles`).
final homeTilesProvider = NotifierProvider<HomeTilesNotifier, List<HomeTile>>(HomeTilesNotifier.new);

class HomeTilesNotifier extends Notifier<List<HomeTile>> {
  static const storeKey = 'home_tiles';

  @override
  List<HomeTile> build() {
    final raw = ref.watch(reminderStoreProvider).read(storeKey);
    if (raw == null) return HomeTile.defaults;
    return [
      for (final name in raw.split(',')) ?HomeTile.values.where((t) => t.name == name).firstOrNull,
    ];
  }

  bool get isDefault => listEquals(state, HomeTile.defaults);

  Future<void> set(List<HomeTile> visible) async {
    state = List<HomeTile>.unmodifiable(visible.toSet());
    await ref.read(reminderStoreProvider).write(storeKey, state.map((t) => t.name).join(','));
  }

  Future<void> reset() async {
    state = HomeTile.defaults;
    await ref.read(reminderStoreProvider).write(storeKey, null);
  }
}
