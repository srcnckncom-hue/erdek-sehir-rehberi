import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Ekran üstünde ince bilgi şeridi ("ÖRNEK VERİ", "Çevrimdışı · son güncelleme").
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.message});

  final AppIconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: AppSpacing.pagePadding,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: p.warning,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
        ),
        child: Row(
          children: [
            AppIcon(icon, size: 20, color: p.iconOrange),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message, style: AppTypography.caption.copyWith(color: p.textBody)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Boş / hata durumları için ortak görünüm.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final AppIconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = iconColor ?? p.primary;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppIcon(icon, size: 36, color: color),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTypography.label.copyWith(
              color: p.textHeading,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              style: AppTypography.caption.copyWith(color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Yükleniyor iskeleti (animasyonsuz; ekran görüntüsü testleri sabit kalsın).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = AppRadius.tile});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Liste ekranları için hazır iskelet: [count] kart.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.itemHeight = 72});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Yükleniyor',
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.gap),
              SkeletonBox(height: itemHeight),
            ],
          ],
        ),
      ),
    );
  }
}

abstract final class StateIcons {
  static AppIconData get empty => AppIcons.info;
  static AppIconData get error => AppIcons.warning;
  static AppIconData get offline => AppIcons.offline;
}
