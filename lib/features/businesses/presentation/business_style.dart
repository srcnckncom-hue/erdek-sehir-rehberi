import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/business.dart';

/// Kategori ikonuna göre ikon ve renk (tek yerden).
abstract final class BusinessStyle {
  static AppIconData icon(BusinessIcon i) => switch (i) {
        BusinessIcon.food => AppIcons.bizFood,
        BusinessIcon.cafe => AppIcons.bizCafe,
        BusinessIcon.hotel => AppIcons.bizHotel,
        BusinessIcon.market => AppIcons.bizMarket,
        BusinessIcon.shopping => AppIcons.bizShopping,
        BusinessIcon.service => AppIcons.bizService,
        BusinessIcon.car => AppIcons.bizCar,
        BusinessIcon.health => AppIcons.bizHealth,
        BusinessIcon.beauty => AppIcons.bizBeauty,
        BusinessIcon.other => AppIcons.bizOther,
      };

  static Color color(AppPalette p, BusinessIcon i) => switch (i) {
        BusinessIcon.food => p.peach.foreground,
        BusinessIcon.cafe => p.iconOrange,
        BusinessIcon.hotel => p.iconBlue,
        BusinessIcon.market => p.mint.foreground,
        BusinessIcon.shopping => p.iconPurple,
        BusinessIcon.service => p.primary,
        BusinessIcon.car => p.aqua.foreground,
        BusinessIcon.health => p.iconRed,
        BusinessIcon.beauty => p.iconCoral,
        BusinessIcon.other => p.primary,
      };
}

/// Fotoğraf yoksa: kategori ikonu (renkli zemin).
class BusinessIconTile extends StatelessWidget {
  const BusinessIconTile({super.key, required this.icon, this.iconSize = 32});

  final BusinessIcon icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final color = BusinessStyle.color(context.palette, icon);
    return ColoredBox(
      color: color.withValues(alpha: 0.12),
      child: Center(child: AppIcon(BusinessStyle.icon(icon), size: iconSize, color: color)),
    );
  }
}
