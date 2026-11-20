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

  /// Bölüm başlığı ("Hızlı İşlemlerim")
  static const sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
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

  /// Beyaz kutucuk etiketi
  static const tileLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
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

  static TextTheme textTheme(Color heading, Color body, Color secondary) =>
      TextTheme(
        displayLarge: display.copyWith(color: heading),
        headlineSmall: cardTitle.copyWith(color: heading),
        titleLarge: sectionTitle.copyWith(color: heading),
        titleMedium: greeting.copyWith(color: heading),
        titleSmall: label.copyWith(color: body),
        bodyLarge: body.copyWith(color: body),
        bodyMedium: caption.copyWith(color: body),
        bodySmall: caption.copyWith(color: secondary),
        labelLarge: label.copyWith(color: body),
        labelMedium: tileLabel.copyWith(color: body),
        labelSmall: tabLabel.copyWith(color: secondary),
      );
}
