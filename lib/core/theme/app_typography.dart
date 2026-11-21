import 'package:material_ui/material_ui.dart';

/// Poppins tabanlı yazı ölçeği (görselden ölçüldü, pt).
/// Renk verilmez; renk tema/AppPalette'ten gelir. Dynamic Type için
/// MediaQuery.textScaler otomatik uygulanır.
abstract final class AppTypography {
  static const fontFamily = 'Poppins';

  /// Sıcaklık "16°"
  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -1.5,
  );

  /// Alt sayfa başlığı ("Nöbetçi Eczane")
  static const pageTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Büyük kart başlığı (eczane adı)
  static const cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Küçük karttaki büyük değer ("12:15")
  static const value = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Bölüm başlığı ("Hızlı İşlemlerim") — 21.11.2026: 20 → 17 (kullanıcı isteği)
  static const sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  /// Selamlama ("Günaydın, Erdek")
  static const greeting = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// Geniş renkli kart etiketi, "Tümünü Gör"
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  /// Gövde / arama kutusu
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Beyaz kutucuk etiketi — 21.11.2026: 13 → 12 (kullanıcı isteği)
  static const tileLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  /// Küçük açıklama ("Bugün", "%72 Nem")
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  /// Alt menü etiketi, "Reklam" etiketi
  static const tabLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static TextTheme textTheme(Color headingColor, Color bodyColor, Color secondaryColor) =>
      TextTheme(
        displayLarge: display.copyWith(color: headingColor),
        headlineSmall: cardTitle.copyWith(color: headingColor),
        titleLarge: sectionTitle.copyWith(color: headingColor),
        titleMedium: greeting.copyWith(color: headingColor),
        titleSmall: label.copyWith(color: bodyColor),
        bodyLarge: body.copyWith(color: bodyColor),
        bodyMedium: caption.copyWith(color: bodyColor),
        bodySmall: caption.copyWith(color: secondaryColor),
        labelLarge: label.copyWith(color: bodyColor),
        labelMedium: tileLabel.copyWith(color: bodyColor),
        labelSmall: tabLabel.copyWith(color: secondaryColor),
      );
}
