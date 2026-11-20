import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Hero'daki hava durumu satırı için hazır metinler.
class HeroWeather {
  const HeroWeather({
    required this.temperature,
    required this.symbolCode,
    required this.description,
    this.humidityLabel,
    this.windLabel,
    this.rangeLabel,
  });

  /// ör. 16
  final int temperature;
  final String symbolCode;

  /// ör. "Parçalı bulutlu" (erişilebilirlik etiketi)
  final String description;

  /// ör. "%72 Nem"
  final String? humidityLabel;

  /// ör. "12 km/s"
  final String? windLabel;

  /// ör. "14°/22°"
  final String? rangeLabel;
}

/// Ana sayfanın üst kısmı: Erdek fotoğrafı, selamlama, menü, zil,
/// hava durumu. Görseldeki üst bölümün karşılığı.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.image,
    required this.greeting,
    required this.dayLabel,
    required this.locationLabel,
    required this.statusLabel,
    required this.menuLabel,
    required this.bell,
    this.weather,
    this.onMenu,
    this.onStatusTap,
  });

  final ImageProvider image;
  final String greeting;

  /// ör. "Cumartesi, Erdek"
  final String dayLabel;

  /// ör. "Erdek, Balıkesir"
  final String locationLabel;

  /// ör. "Güncel" veya "Çevrimdışı · 10:42"
  final String statusLabel;
  final String menuLabel;
  final Widget bell;
  final HeroWeather? weather;
  final VoidCallback? onMenu;
  final VoidCallback? onStatusTap;

  static const _fg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final detailStyle = AppTypography.caption.copyWith(
      color: _fg.withValues(alpha: 0.92),
      fontSize: 14,
    );

    return ClipRRect(
      borderRadius: AppRadius.heroBottom,
      child: SizedBox(
        height: AppSpacing.heroHeight - 54 + topInset.clamp(20.0, 80.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: image, fit: BoxFit.cover, excludeFromSemantics: true),
            // Okunabilirlik için üst ve alt koyulaştırma
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.35, 0.6, 1],
                  colors: [
                    Color(0x8C001A33),
                    Color(0x1A001A33),
                    Color(0x33001A33),
                    Color(0xA6001A33),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.page,
                topInset + AppSpacing.xxs,
                AppSpacing.page,
                AppSpacing.xxl + AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onMenu,
                        tooltip: menuLabel,
                        icon: AppIcon(AppIcons.menu, size: 28, color: _fg),
                      ),
                      Expanded(
                        child: Text(
                          greeting,
                          textAlign: TextAlign.center,
                          style: AppTypography.greeting.copyWith(color: _fg),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      bell,
                    ],
                  ),
                  const Spacer(),
                  if (weather != null)
                    Semantics(
                      label: '${weather!.temperature} derece, ${weather!.description}',
                      excludeSemantics: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weather!.temperature}°',
                            style: AppTypography.display.copyWith(color: _fg),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AppIcon(AppIcons.weather(weather!.symbolCode), size: 40, color: _fg),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    dayLabel,
                    style: AppTypography.greeting.copyWith(
                      color: _fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (weather != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    _DetailRow(
                      style: detailStyle,
                      items: [
                        if (weather!.humidityLabel != null)
                          (AppIcons.humidity, weather!.humidityLabel!),
                        if (weather!.windLabel != null) (AppIcons.wind, weather!.windLabel!),
                        if (weather!.rangeLabel != null)
                          (AppIcons.thermometer, weather!.rangeLabel!),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxs),
                  InkWell(
                    onTap: onStatusTap,
                    child: _DetailRow(
                      style: detailStyle,
                      items: [
                        (AppIcons.mapPin, locationLabel),
                        (AppIcons.refresh, statusLabel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.items, required this.style});

  final List<(IconData, String)> items;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('|', style: style),
          ),
        );
      }
      children
        ..add(AppIcon(items[i].$1, size: 18, color: style.color))
        ..add(const SizedBox(width: AppSpacing.xxs))
        ..add(Flexible(child: Text(items[i].$2, style: style, maxLines: 1, overflow: TextOverflow.ellipsis)));
    }
    return Row(children: children);
  }
}

/// Rozetli bildirim zili (hero üzerinde beyaz).
class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.count,
    required this.tooltip,
    this.onTap,
    this.color = Colors.white,
  });

  final int count;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          AppIcon(AppIcons.bell, size: 30, color: color),
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: p.badge,
                  borderRadius: AppRadius.pillAll,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: AppTypography.tabLabel.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
