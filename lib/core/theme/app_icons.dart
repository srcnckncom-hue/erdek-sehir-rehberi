import 'package:material_ui/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Uygulamadaki tüm ikonlar TEK yerden: Phosphor Icons (MIT lisansı).
/// Görseldeki stil: açık dolgu + renkli kontur → "duotone".
/// İkon setini değiştirmek gerekirse yalnızca bu dosya değişir.
abstract final class AppIcons {
  // Özellikler
  static IconData get pharmacy => PhosphorIcons.duotone.firstAidKit;
  static IconData get pill => PhosphorIcons.duotone.pill;
  static IconData get prayer => PhosphorIcons.duotone.moonStars;
  static IconData get imsakiye => PhosphorIcons.duotone.calendarBlank;
  static IconData get ferry => PhosphorIcons.duotone.boat;
  static IconData get bus => PhosphorIcons.duotone.bus;
  static IconData get announcements => PhosphorIcons.duotone.megaphone;
  static IconData get contacts => PhosphorIcons.duotone.phone;
  static IconData get outage => PhosphorIcons.duotone.lightning;
  static IconData get market => PhosphorIcons.duotone.storefront;
  static IconData get event => PhosphorIcons.duotone.confetti;
  static IconData get emergency => PhosphorIcons.duotone.siren;

  // Genel
  static IconData get menu => PhosphorIcons.regular.list;
  static IconData get bell => PhosphorIcons.regular.bell;
  static IconData get search => PhosphorIcons.regular.magnifyingGlass;
  static IconData get arrowRight => PhosphorIcons.regular.arrowRight;
  static IconData get call => PhosphorIcons.fill.phoneCall;
  static IconData get directions => PhosphorIcons.fill.navigationArrow;
  static IconData get mapPin => PhosphorIcons.regular.mapPin;
  static IconData get refresh => PhosphorIcons.regular.arrowsClockwise;
  static IconData get humidity => PhosphorIcons.regular.drop;
  static IconData get wind => PhosphorIcons.regular.wind;
  static IconData get thermometer => PhosphorIcons.regular.thermometer;
  static IconData get info => PhosphorIcons.duotone.info;
  static IconData get warning => PhosphorIcons.duotone.warningCircle;
  static IconData get offline => PhosphorIcons.duotone.wifiSlash;
  static IconData get clock => PhosphorIcons.duotone.clock;

  // Alt menü: pasif = çizgi, aktif = dolu
  static IconData tabHome({required bool active}) =>
      active ? PhosphorIcons.fill.house : PhosphorIcons.regular.house;
  static IconData tabPharmacy({required bool active}) =>
      active ? PhosphorIcons.fill.firstAidKit : PhosphorIcons.regular.firstAidKit;
  static IconData tabPrayer({required bool active}) =>
      active ? PhosphorIcons.fill.moonStars : PhosphorIcons.regular.moonStars;
  static IconData tabTransport({required bool active}) =>
      active ? PhosphorIcons.fill.boat : PhosphorIcons.regular.boat;
  static IconData tabDirectory({required bool active}) =>
      active ? PhosphorIcons.fill.addressBook : PhosphorIcons.regular.addressBook;

  /// MET Norway sembol kodu → ikon (çizgi stil, hero üzerinde beyaz).
  static IconData weather(String symbolCode) {
    final night = symbolCode.endsWith('_night');
    final base = symbolCode.split('_').first;
    if (base.contains('thunder')) return PhosphorIcons.regular.cloudLightning;
    if (base.contains('snow') || base.contains('sleet')) {
      return PhosphorIcons.regular.cloudSnow;
    }
    if (base.contains('rain')) return PhosphorIcons.regular.cloudRain;
    if (base == 'fog') return PhosphorIcons.regular.cloudFog;
    if (base == 'cloudy') return PhosphorIcons.regular.cloud;
    if (base == 'partlycloudy' || base == 'fair') {
      return night ? PhosphorIcons.regular.cloudMoon : PhosphorIcons.regular.cloudSun;
    }
    if (base == 'clearsky') {
      return night ? PhosphorIcons.regular.moon : PhosphorIcons.regular.sun;
    }
    return PhosphorIcons.regular.cloudSun;
  }
}

/// Duotone ikonu doğru çizen ortak ikon. (Flutter'ın Icon'u duotone'u
/// tek renk çizer; bu yüzden ekranlarda her zaman AppIcon kullanılır.)
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = 24, this.color, this.semanticLabel});

  final IconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (icon is PhosphorIconData) {
      return PhosphorIcon(
        icon as PhosphorIconData,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      );
    }
    return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
  }
}
