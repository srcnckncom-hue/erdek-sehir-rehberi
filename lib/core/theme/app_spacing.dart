import 'package:material_ui/material_ui.dart';

/// Boşluklar (pt). Görselden ölçüldü: 1 pt ≈ 2,04 px.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;

  /// Ekran kenar boşluğu
  static const page = 14.0;

  /// Kartlar/kutucuklar arası
  static const gap = 8.0;

  /// Bölümler arası
  static const section = 24.0;

  static const pagePadding = EdgeInsets.symmetric(horizontal: page);

  // Bileşen yükseklikleri
  static const chipHeight = 50.0;
  static const tileHeight = 70.0;
  static const searchHeight = 48.0;
  static const heroHeight = 295.0;
  static const tabBarHeight = 64.0;
  static const minTouchTarget = 44.0;
}

/// Köşe yuvarlaklıkları (pt).
abstract final class AppRadius {
  static const xs = 6.0;
  static const sm = 10.0;
  static const chip = 14.0;
  static const tile = 16.0;
  static const card = 20.0;
  static const hero = 28.0;
  static const pill = 999.0;

  static const chipAll = BorderRadius.all(Radius.circular(chip));
  static const tileAll = BorderRadius.all(Radius.circular(tile));
  static const cardAll = BorderRadius.all(Radius.circular(card));
  static const pillAll = BorderRadius.all(Radius.circular(pill));
  static const heroBottom = BorderRadius.only(
    bottomLeft: Radius.circular(hero),
    bottomRight: Radius.circular(hero),
  );
}

/// Gölgeler. Renk temadan gelir (AppPalette.shadow).
abstract final class AppShadows {
  static List<BoxShadow> card(Color color) => [
        BoxShadow(color: color, offset: const Offset(0, 4), blurRadius: 12),
      ];

  static List<BoxShadow> raised(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: (color.a * 1.35).clamp(0, 1)),
          offset: const Offset(0, 6),
          blurRadius: 20,
        ),
      ];
}
