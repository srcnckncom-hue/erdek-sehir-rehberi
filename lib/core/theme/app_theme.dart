import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

/// Uygulamanın tek tema kaynağı. Ekranlarda renk/ölçü yazılmaz;
/// buradan ve `context.palette`'ten okunur.
abstract final class AppTheme {
  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: p.primary,
      onPrimary: p.onPrimary,
      surface: p.surface,
      onSurface: p.textBody,
      onSurfaceVariant: p.textSecondary,
      error: p.accentRed,
      outlineVariant: p.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: p.background,
      textTheme: AppTypography.textTheme(p.textHeading, p.textBody, p.textSecondary),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.tileAll),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textHeading,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.greeting.copyWith(
          color: p.textHeading,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
          textStyle: AppTypography.label,
        ),
      ),
      extensions: [p],
    );
  }
}
