import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../nearby/points.dart';

/// Harita / Yakınımdakiler katmanlarının ikonu, rengi ve adı.
abstract final class MapLayerStyle {
  static AppIconData icon(MapLayer l) => switch (l) {
        MapLayer.pharmacy => AppIcons.pharmacy,
        MapLayer.business => AppIcons.businesses,
        MapLayer.place => AppIcons.places,
        MapLayer.taxi => AppIcons.serviceTaxi,
        MapLayer.atm => AppIcons.serviceAtm,
        MapLayer.parking => AppIcons.bizCar,
        MapLayer.wc => AppIcons.amenityWc,
        MapLayer.charging => AppIcons.outage,
        MapLayer.fuel => AppIcons.serviceFuel,
      };

  static Color color(AppPalette p, MapLayer l) => switch (l) {
        MapLayer.pharmacy => p.accentRed,
        MapLayer.business => p.iconOrange,
        MapLayer.place => p.iconBlue,
        MapLayer.taxi => p.iconOrange,
        MapLayer.atm => p.mint.foreground,
        MapLayer.parking => p.iconBlue,
        MapLayer.wc => p.aqua.foreground,
        MapLayer.charging => p.iconPurple,
        MapLayer.fuel => p.iconCrimson,
      };

  static String label(AppLocalizations l10n, MapLayer l) => switch (l) {
        MapLayer.pharmacy => l10n.mapFilterPharmacy,
        MapLayer.business => l10n.mapFilterBusinesses,
        MapLayer.place => l10n.mapFilterPlaces,
        MapLayer.taxi => l10n.serviceTaxi,
        MapLayer.atm => l10n.serviceAtm,
        MapLayer.parking => l10n.serviceParking,
        MapLayer.wc => l10n.serviceWc,
        MapLayer.charging => l10n.serviceCharging,
        MapLayer.fuel => l10n.serviceFuel,
      };
}
