import 'package:material_ui/material_ui.dart';

/// Panelin renkleri: uygulama logosundaki lacivert, mavi ve turuncu.
abstract final class AdminColors {
  static const navy = Color(0xFF142036);
  static const blue = Color(0xFF268EC5);
  static const orange = Color(0xFFED681B);
  static const background = Color(0xFFF4F6FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE3E8EF);
  static const muted = Color(0xFF5F6B7D);
  static const sidebar = Color(0xFF142036);
  static const sidebarMuted = Color(0xFF9AA6B8);
}

abstract final class AdminTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AdminColors.blue).copyWith(
      primary: AdminColors.blue,
      secondary: AdminColors.orange,
      surface: AdminColors.surface,
      outlineVariant: AdminColors.border,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AdminColors.background,
      dividerTheme: const DividerThemeData(color: AdminColors.border, thickness: 1, space: 1),
      cardTheme: const CardThemeData(
        color: AdminColors.surface,
        elevation: 0,
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AdminColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AdminColors.surface,
        foregroundColor: AdminColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: AdminColors.navy, fontSize: 20, fontWeight: FontWeight.w700),
        shape: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

/// Sayfa içi bölüm başlığı (ince turuncu çizgi + başlık + açıklama).
class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 4,
              height: subtitle == null ? 20 : 38,
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                color: AdminColors.orange,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminColors.navy),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(fontSize: 13, color: AdminColors.muted)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      );
}
