import 'package:material_ui/material_ui.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Uygulamanın ikon tipi. Düz ikon (IconData) ya da iki katmanlı duotone
/// ikon (PhosphorDuotoneIconData) taşır. Bileşenler yalnızca bunu bilir;
/// ikon paketi değişirse sadece bu dosya değişir.
@immutable
class AppIconData {
  const AppIconData(this.value);

  /// IconData veya PhosphorDuotoneIconData
  final Object value;
}

/// Uygulamadaki tüm ikonlar TEK yerden: Phosphor Icons (MIT lisansı),
/// `phosphoricons_flutter` paketi (Flutter 3.44+ uyumlu).
/// Görseldeki stil: açık dolgu + renkli kontur → "duotone".
abstract final class AppIcons {
  static AppIconData _d(PhosphorDuotoneIconData icon) => AppIconData(icon);
  static AppIconData _i(IconData icon) => AppIconData(icon);

  // Özellikler (duotone)
  static AppIconData get pharmacy => _d(PhosphorIconsDuotone.firstAidKit);
  static AppIconData get pill => _d(PhosphorIconsDuotone.pill);
  static AppIconData get prayer => _d(PhosphorIconsDuotone.moonStars);
  static AppIconData get imsakiye => _d(PhosphorIconsDuotone.calendarBlank);
  static AppIconData get ferry => _d(PhosphorIconsDuotone.boat);
  static AppIconData get bus => _d(PhosphorIconsDuotone.bus);
  static AppIconData get cityBus => _d(PhosphorIconsDuotone.signpost);
  static AppIconData get announcements => _d(PhosphorIconsDuotone.megaphone);
  static AppIconData get contacts => _d(PhosphorIconsDuotone.phone);
  static AppIconData get outage => _d(PhosphorIconsDuotone.lightning);
  static AppIconData get market => _d(PhosphorIconsDuotone.storefront);
  static AppIconData get event => _d(PhosphorIconsDuotone.confetti);
  static AppIconData get emergency => _d(PhosphorIconsDuotone.siren);
  static AppIconData get assembly => _d(PhosphorIconsDuotone.usersThree);
  static AppIconData get myLocation => _i(PhosphorIconsRegular.crosshair);
  static AppIconData get info => _d(PhosphorIconsDuotone.info);
  static AppIconData get warning => _d(PhosphorIconsDuotone.warningCircle);
  static AppIconData get offline => _d(PhosphorIconsDuotone.wifiSlash);
  static AppIconData get clock => _d(PhosphorIconsDuotone.clock);
  static AppIconData get places => _d(PhosphorIconsDuotone.mapTrifold);
  static AppIconData get history => _d(PhosphorIconsDuotone.scroll);
  static AppIconData get placeBeach => _d(PhosphorIconsDuotone.umbrellaSimple);
  static AppIconData get placeHistoric => _d(PhosphorIconsDuotone.bank);
  static AppIconData get placeNature => _d(PhosphorIconsDuotone.tree);
  static AppIconData get placeVillage => _d(PhosphorIconsDuotone.houseLine);
  static AppIconData get placeViewpoint => _d(PhosphorIconsDuotone.binoculars);
  static AppIconData get placeOther => _d(PhosphorIconsDuotone.mapPin);
  static AppIconData get lightbulb => _d(PhosphorIconsDuotone.lightbulb);
  static AppIconData get ramadan => _d(PhosphorIconsDuotone.moon);
  static AppIconData get sea => _d(PhosphorIconsDuotone.waves);
  static AppIconData get map => _d(PhosphorIconsDuotone.mapPinLine);
  static AppIconData get nearby => _d(PhosphorIconsDuotone.navigationArrow);
  static AppIconData get businesses => _d(PhosphorIconsDuotone.buildings);
  static AppIconData get forecast => _d(PhosphorIconsDuotone.cloudSun);

  // İşletme kategorileri (panelde seçilen ikon anahtarı → ikon)
  static AppIconData get bizFood => _d(PhosphorIconsDuotone.forkKnife);
  static AppIconData get bizCafe => _d(PhosphorIconsDuotone.coffee);
  static AppIconData get bizHotel => _d(PhosphorIconsDuotone.bed);
  static AppIconData get bizMarket => _d(PhosphorIconsDuotone.shoppingCart);
  static AppIconData get bizShopping => _d(PhosphorIconsDuotone.shoppingBag);
  static AppIconData get bizService => _d(PhosphorIconsDuotone.wrench);
  static AppIconData get bizCar => _d(PhosphorIconsDuotone.car);
  static AppIconData get bizHealth => _d(PhosphorIconsDuotone.heartbeat);
  static AppIconData get bizBeauty => _d(PhosphorIconsDuotone.scissors);
  static AppIconData get bizOther => _d(PhosphorIconsDuotone.storefront);

  // Genel (düz)
  static AppIconData get menu => _i(PhosphorIconsRegular.list);
  static AppIconData get bell => _i(PhosphorIconsRegular.bell);
  static AppIconData get search => _i(PhosphorIconsRegular.magnifyingGlass);
  static AppIconData get arrowRight => _i(PhosphorIconsRegular.arrowRight);
  static AppIconData get call => _i(PhosphorIconsFill.phoneCall);
  static AppIconData get directions => _i(PhosphorIconsFill.navigationArrow);
  static AppIconData get mapPin => _i(PhosphorIconsRegular.mapPin);
  static AppIconData get refresh => _i(PhosphorIconsRegular.arrowsClockwise);
  static AppIconData get humidity => _i(PhosphorIconsRegular.drop);
  static AppIconData get wind => _i(PhosphorIconsRegular.wind);
  static AppIconData get thermometer => _i(PhosphorIconsRegular.thermometer);
  static AppIconData get locationArrow => _i(PhosphorIconsRegular.navigationArrow);
  static AppIconData get windArrow => _i(PhosphorIconsFill.arrowUp);
  static AppIconData get close => _i(PhosphorIconsRegular.x);
  static AppIconData get bellFilled => _i(PhosphorIconsFill.bell);
  static AppIconData get globe => _i(PhosphorIconsRegular.globe);
  static AppIconData get whatsapp => _i(PhosphorIconsRegular.whatsappLogo);
  static AppIconData get instagram => _i(PhosphorIconsRegular.instagramLogo);
  static AppIconData get facebook => _i(PhosphorIconsRegular.facebookLogo);
  static AppIconData get xLogo => _i(PhosphorIconsRegular.xLogo);
  static AppIconData get precipitation => _i(PhosphorIconsRegular.umbrella);
  static AppIconData get caretLeft => _i(PhosphorIconsRegular.caretLeft);
  static AppIconData get caretRight => _i(PhosphorIconsRegular.caretRight);
  static AppIconData get bellRinging => _d(PhosphorIconsDuotone.bellRinging);
  static AppIconData get sunrise => _d(PhosphorIconsDuotone.sunHorizon);
  static AppIconData get themeLight => _i(PhosphorIconsRegular.sun);
  static AppIconData get themeDark => _i(PhosphorIconsRegular.moon);
  static AppIconData get themeSystem => _i(PhosphorIconsRegular.deviceMobile);
  static AppIconData get appearance => _d(PhosphorIconsDuotone.palette);
  static AppIconData get image => _d(PhosphorIconsDuotone.image);
  static AppIconData get settings => _d(PhosphorIconsDuotone.gear);
  static AppIconData get share => _d(PhosphorIconsDuotone.shareNetwork);
  static AppIconData get report => _d(PhosphorIconsDuotone.flag);
  static AppIconData get star => _d(PhosphorIconsDuotone.star);
  static AppIconData get favoriteOn => _d(PhosphorIconsDuotone.star);
  static AppIconData get favoriteOff => _i(PhosphorIconsRegular.star);
  static AppIconData get shield => _d(PhosphorIconsDuotone.shieldCheck);
  static AppIconData get document => _d(PhosphorIconsDuotone.fileText);
  static AppIconData get dutyNote => _d(PhosphorIconsDuotone.clockCountdown);

  // Alt menü: pasif = çizgi, aktif = dolu
  static AppIconData tabHome({required bool active}) =>
      _i(active ? PhosphorIconsFill.house : PhosphorIconsRegular.house);
  static AppIconData tabPharmacy({required bool active}) =>
      _i(active ? PhosphorIconsFill.firstAidKit : PhosphorIconsRegular.firstAidKit);
  static AppIconData tabPrayer({required bool active}) =>
      _i(active ? PhosphorIconsFill.moonStars : PhosphorIconsRegular.moonStars);
  static AppIconData tabTransport({required bool active}) =>
      _i(active ? PhosphorIconsFill.boat : PhosphorIconsRegular.boat);
  static AppIconData tabDirectory({required bool active}) =>
      _i(active ? PhosphorIconsFill.addressBook : PhosphorIconsRegular.addressBook);

  /// MET Norway sembol kodu → ikon (çizgi stil, hero üzerinde beyaz).
  static AppIconData weather(String symbolCode) {
    final night = symbolCode.endsWith('_night');
    final base = symbolCode.split('_').first;
    if (base.contains('thunder')) return _i(PhosphorIconsRegular.cloudLightning);
    if (base.contains('snow') || base.contains('sleet')) {
      return _i(PhosphorIconsRegular.cloudSnow);
    }
    if (base.contains('rain')) return _i(PhosphorIconsRegular.cloudRain);
    if (base == 'fog') return _i(PhosphorIconsRegular.cloudFog);
    if (base == 'cloudy') return _i(PhosphorIconsRegular.cloud);
    if (base == 'partlycloudy' || base == 'fair') {
      return _i(night ? PhosphorIconsRegular.cloudMoon : PhosphorIconsRegular.cloudSun);
    }
    if (base == 'clearsky') {
      return _i(night ? PhosphorIconsRegular.moon : PhosphorIconsRegular.sun);
    }
    return _i(PhosphorIconsRegular.cloudSun);
  }
}

/// Ekranlarda her zaman bu kullanılır: duotone ikonları iki katman
/// (açık dolgu + kontur) olarak doğru çizer.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = 24, this.color, this.semanticLabel});

  final AppIconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final value = icon.value;
    if (value is PhosphorDuotoneIconData) {
      return PhosphorIcon(value, size: size, color: color, semanticLabel: semanticLabel);
    }
    return Icon(value as IconData, size: size, color: color, semanticLabel: semanticLabel);
  }
}
