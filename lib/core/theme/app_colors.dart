import 'package:material_ui/material_ui.dart';

/// Tasarım görselinden (design/02_ana_sayfa_v2.png) ölçülen ham renkler.
/// Ekranlar bunları DOĞRUDAN kullanmaz; [AppPalette] üzerinden okur
/// (açık/koyu tema farkı tek yerde kalsın diye).
abstract final class AppColors {
  // Marka
  static const primary = Color(0xFF0057FC);
  static const accentRed = Color(0xFFC81C18);
  static const badgeRed = Color(0xFFE82430);

  // Metin (açık tema)
  static const textHeading = Color(0xFF061826);
  static const textBody = Color(0xFF0A0F1A);
  static const textSecondary = Color(0xFF5F6779);

  // Yüzeyler (açık tema)
  static const background = Color(0xFFF4F5F9);
  static const surface = Color(0xFFFFFFFF);

  // Geniş renkli kartlar (zemin / ikon)
  static const peach = Color(0xFFFCE0B5);
  static const peachIcon = Color(0xFFD06F04);
  static const mint = Color(0xFFC0F4D8);
  static const mintIcon = Color(0xFF068A55);
  static const aqua = Color(0xFFBAF0F0);
  static const aquaIcon = Color(0xFF00808C);

  // Kutucuk ikon renkleri
  static const iconPurple = Color(0xFF6545C4);
  static const iconBlue = Color(0xFF0858C2);
  static const iconRed = Color(0xFFE0241A);
  static const iconCrimson = Color(0xFFD01030);
  static const iconOrange = Color(0xFFF49022);
  static const iconCoral = Color(0xFFF07A6E);

  // Koyu tema (görselde yok; açık temadan türetildi — onaya sunulacak)
  static const darkBackground = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF141C2B);
  static const darkSurfaceHigh = Color(0xFF1C2638);
  static const darkTextHeading = Color(0xFFF2F5FA);
  static const darkTextBody = Color(0xFFE4E8F0);
  static const darkTextSecondary = Color(0xFF98A2B6);
  static const darkPrimary = Color(0xFF5B8DFF);
  static const darkAccentRed = Color(0xFFB3241F);
  static const darkPeach = Color(0xFF3A2A12);
  static const darkPeachIcon = Color(0xFFF5A443);
  static const darkMint = Color(0xFF0F3324);
  static const darkMintIcon = Color(0xFF43D18F);
  static const darkAqua = Color(0xFF0B3236);
  static const darkAquaIcon = Color(0xFF3CCFD9);
}

/// Bir renkli kartın zemin + ikon/metin rengi çifti.
@immutable
class ToneColors {
  const ToneColors(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static ToneColors lerp(ToneColors a, ToneColors b, double t) => ToneColors(
        Color.lerp(a.background, b.background, t)!,
        Color.lerp(a.foreground, b.foreground, t)!,
      );
}

/// Ekranların kullandığı anlamsal renkler. `context.palette` ile okunur.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textHeading,
    required this.textBody,
    required this.textSecondary,
    required this.accentRed,
    required this.badge,
    required this.peach,
    required this.mint,
    required this.aqua,
    required this.iconPurple,
    required this.iconBlue,
    required this.iconRed,
    required this.iconCrimson,
    required this.iconOrange,
    required this.iconCoral,
    required this.shadow,
    required this.tabBar,
    required this.divider,
    required this.warning,
  });

  final Color primary;
  final Color onPrimary;

  /// Aktif sekme arka planı vb. (#0057FC %10).
  final Color primarySoft;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textHeading;
  final Color textBody;
  final Color textSecondary;
  final Color accentRed;
  final Color badge;
  final ToneColors peach;
  final ToneColors mint;
  final ToneColors aqua;
  final Color iconPurple;
  final Color iconBlue;
  final Color iconRed;
  final Color iconCrimson;
  final Color iconOrange;
  final Color iconCoral;
  final Color shadow;

  /// Buzlu cam alt menü zemini (yarı saydam).
  final Color tabBar;
  final Color divider;

  /// "ÖRNEK VERİ" / çevrimdışı şeridi.
  final Color warning;

  static const light = AppPalette(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primarySoft: Color(0x1A0057FC),
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceMuted: Color(0xFFE9ECF3),
    textHeading: AppColors.textHeading,
    textBody: AppColors.textBody,
    textSecondary: AppColors.textSecondary,
    accentRed: AppColors.accentRed,
    badge: AppColors.badgeRed,
    peach: ToneColors(AppColors.peach, AppColors.peachIcon),
    mint: ToneColors(AppColors.mint, AppColors.mintIcon),
    aqua: ToneColors(AppColors.aqua, AppColors.aquaIcon),
    iconPurple: AppColors.iconPurple,
    iconBlue: AppColors.iconBlue,
    iconRed: AppColors.iconRed,
    iconCrimson: AppColors.iconCrimson,
    iconOrange: AppColors.iconOrange,
    iconCoral: AppColors.iconCoral,
    shadow: Color(0x0F101828),
    tabBar: Color(0xD9FFFFFF),
    divider: Color(0xFFE3E6EE),
    warning: Color(0xFFFFF1D6),
  );

  static const dark = AppPalette(
    primary: AppColors.darkPrimary,
    onPrimary: Colors.white,
    primarySoft: Color(0x295B8DFF),
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceMuted: AppColors.darkSurfaceHigh,
    textHeading: AppColors.darkTextHeading,
    textBody: AppColors.darkTextBody,
    textSecondary: AppColors.darkTextSecondary,
    accentRed: AppColors.darkAccentRed,
    badge: AppColors.badgeRed,
    peach: ToneColors(AppColors.darkPeach, AppColors.darkPeachIcon),
    mint: ToneColors(AppColors.darkMint, AppColors.darkMintIcon),
    aqua: ToneColors(AppColors.darkAqua, AppColors.darkAquaIcon),
    iconPurple: Color(0xFFA38BF0),
    iconBlue: Color(0xFF6FA2FF),
    iconRed: Color(0xFFFF6B5E),
    iconCrimson: Color(0xFFFF5C77),
    iconOrange: Color(0xFFFFB25C),
    iconCoral: Color(0xFFFF9C90),
    shadow: Color(0x40000000),
    tabBar: Color(0xD9141C2B),
    divider: Color(0xFF263042),
    warning: Color(0xFF3A3016),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      primarySoft: c(primarySoft, other.primarySoft),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      textHeading: c(textHeading, other.textHeading),
      textBody: c(textBody, other.textBody),
      textSecondary: c(textSecondary, other.textSecondary),
      accentRed: c(accentRed, other.accentRed),
      badge: c(badge, other.badge),
      peach: ToneColors.lerp(peach, other.peach, t),
      mint: ToneColors.lerp(mint, other.mint, t),
      aqua: ToneColors.lerp(aqua, other.aqua, t),
      iconPurple: c(iconPurple, other.iconPurple),
      iconBlue: c(iconBlue, other.iconBlue),
      iconRed: c(iconRed, other.iconRed),
      iconCrimson: c(iconCrimson, other.iconCrimson),
      iconOrange: c(iconOrange, other.iconOrange),
      iconCoral: c(iconCoral, other.iconCoral),
      shadow: c(shadow, other.shadow),
      tabBar: c(tabBar, other.tabBar),
      divider: c(divider, other.divider),
      warning: c(warning, other.warning),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
