import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/explore.dart';

/// Yer türüne göre ikon, renk ve metinler (tek yerden).
abstract final class PlaceStyle {
  static AppIconData icon(PlaceCategory c) => switch (c) {
        PlaceCategory.beach => AppIcons.placeBeach,
        PlaceCategory.history => AppIcons.placeHistoric,
        PlaceCategory.nature => AppIcons.placeNature,
        PlaceCategory.village => AppIcons.placeVillage,
        PlaceCategory.viewpoint => AppIcons.placeViewpoint,
        PlaceCategory.other => AppIcons.placeOther,
      };

  static Color color(AppPalette p, PlaceCategory c) => switch (c) {
        PlaceCategory.beach => p.aqua.foreground,
        PlaceCategory.history => p.iconPurple,
        PlaceCategory.nature => p.mint.foreground,
        PlaceCategory.village => p.peach.foreground,
        PlaceCategory.viewpoint => p.iconBlue,
        PlaceCategory.other => p.primary,
      };

  static String categoryName(AppLocalizations l10n, PlaceCategory c) =>
      l10n.placeCategoryName(c.jsonValue);

  static String areaName(AppLocalizations l10n, PlaceArea a) => l10n.areaName(a.jsonValue);

  /// "Erdek · Plaj"
  static String meta(AppLocalizations l10n, Place place) =>
      l10n.placeMeta(areaName(l10n, place.area), categoryName(l10n, place.category));
}
