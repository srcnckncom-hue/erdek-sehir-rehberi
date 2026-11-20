import 'package:material_ui/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Uygulamadaki tüm ikonlar TEK yerden: Phosphor Icons (MIT lisansı).
/// Görseldeki stil: açık dolgu + renkli kontur → "duotone".
/// İkon setini değiştirmek gerekirse yalnızca bu dosya değişir.
abstract final class AppIcons {
  // Özellikler
  static IconData get pharmacy => PhosphorIconsDuotone.firstAidKit;
  static IconData get pill => PhosphorIconsDuotone.pill;
  static IconData get prayer => PhosphorIconsDuotone.moonStars;
  static IconData get imsakiye => PhosphorIconsDuotone.calendarBlank;
  static IconData get ferry => PhosphorIconsDuotone.boat;
  static IconData get bus => PhosphorIconsDuotone.bus;
  static IconData get announcements => PhosphorIconsDuotone.megaphone;
  static IconData get contacts => PhosphorIconsDuotone.phone;
  static IconData get outage => PhosphorIconsDuotone.lightning;
  static IconData get market => PhosphorIconsDuotone.storefront;
  static IconData get event => PhosphorIconsDuotone.confetti;
  static IconData get emergency => PhosphorIconsDuotone.siren;

  // Genel
  static IconData get menu => PhosphorIconsRegular.list;
  static IconData get bell => PhosphorIconsRegular.bell;
  static IconData get search => PhosphorIconsRegular.magnifyingGlass;
  static IconData get arrowRight => PhosphorIconsRegular.arrowRight;
  static IconData get call => PhosphorIconsFill.phoneCall;
  static IconData get directions => PhosphorIconsFill.navigationArrow;
  static IconData get mapPin => PhosphorIconsRegular.mapPin;
  static IconData get refresh => PhosphorIconsRegular.arrowsClockwise;
  static IconData get humidity => PhosphorIconsRegular.drop;
  static IconData get wind => PhosphorIconsRegular.wind;
  static IconData get thermometer => PhosphorIconsRegular.thermometer;
  static IconData get info => PhosphorIconsDuotone.info;
  static IconData get warning => PhosphorIconsDuotone.warningCircle;
  static IconData get offline => PhosphorIconsDuotone.wifiSlash;
  static IconData get clock => PhosphorIconsDuotone.clock;

  // Alt menü: pasif = çizgi, aktif = dolu
  static IconData tabHome({required bool active}) =>
      active ? PhosphorIconsFill.house : PhosphorIconsRegular.house;
  static IconData tabPharmacy({required bool active}) =>
      active ? PhosphorIconsFill.firstAidKit : PhosphorIconsRegular.firstAidKit;
  static IconData tabPrayer({required bool active}) =>
      active ? PhosphorIconsFill.moonStars : PhosphorIconsRegular.moonStars;
  static IconData tabTransport({required bool active}) =>
      active ? PhosphorIconsFill.boat : PhosphorIconsRegular.boat;
  static IconData tabDirectory({required bool active}) =>
      active ? PhosphorIconsFill.addressBook : PhosphorIconsRegular.addressBook;

  /// MET Norway sembol kodu → ikon (çizgi stil, hero üzerinde beyaz).
  static IconData weather(String symbolCode) {
    final night = symbolCode.endsWith('_night');
    final base = symbolCode.split('_').first;
    if (base.contains('thunder')) return PhosphorIconsRegular.cloudLightning;
    if (base.contains('snow') || base.contains('sleet')) {
      return PhosphorIconsRegular.cloudSnow;
    }
    if (base.contains('rain')) return PhosphorIconsRegular.cloudRain;
    if (base == 'fog') return PhosphorIconsRegular.cloudFog;
    if (base == 'cloudy') return PhosphorIconsRegular.cloud;
    if (base == 'partlycloudy' || base == 'fair') {
      return night ? PhosphorIconsRegular.cloudMoon : PhosphorIconsRegular.cloudSun;
    }
    if (base == 'clearsky') {
      return night ? PhosphorIconsRegular.moon : PhosphorIconsRegular.sun;
    }
    return PhosphorIconsRegular.cloudSun;
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
