import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Her açılışta oynayan kısa animasyon: logo siyah-beyazdan renkliye döner,
/// altından slogan gelir. iOS açılış ekranıyla (LaunchScreen.storyboard)
/// aynı yerde, aynı boyutta ve GRİ logoyla başlar; geçiş fark edilmez.
///
/// Zemin her temada beyaz: yerel açılış ekranı beyaz olduğu için.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.onFinished, this.previewValue});

  static const logoAsset = 'assets/images/logo.png';

  /// ios/Runner/Assets.xcassets/LaunchImage (240×210 pt) ile aynı.
  static const logoSize = Size(240, 210);

  static const duration = Duration(milliseconds: 2400);

  /// "Hareketi azalt" açıkken: yalnızca kısa geçişler.
  static const reducedDuration = Duration(milliseconds: 900);

  final VoidCallback onFinished;

  /// Ekran görüntüsü için: animasyonu bu noktada (0–1) dondurur.
  @visibleForTesting
  final double? previewValue;

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.previewValue == null) {
        widget.onFinished();
      }
    });

  bool _started = false;
  bool _reduceMotion = false;

  // Zaman çizelgesi (0–1): gri bekleme → renklenme + hafif büyüme →
  // slogan → altında çizgi → kısa bekleme.
  late final Animation<double> _saturation = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.08, 0.50, curve: Curves.easeInOut),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    const TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.04).chain(CurveTween(curve: Curves.easeOut)),
      weight: 20,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.04, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 18,
    ),
    const TweenSequenceItem(tween: ConstantTween(1.0), weight: 32),
  ]).animate(_controller);
  late final Animation<double> _slogan = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.42, 0.72, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _underline = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.58, 0.86, curve: Curves.easeOutCubic),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final preview = widget.previewValue;
    if (preview != null) {
      _controller.value = preview;
      return;
    }
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = _reduceMotion ? LaunchSplash.reducedDuration : LaunchSplash.duration;
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slogan = AppLocalizations.of(context).splashSlogan;
    final sloganStyle = AppTypography.greeting.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textHeading,
    );
    const half = 105.0; // LaunchSplash.logoSize.height / 2

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: Colors.white,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _slogan.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Transform.scale(
                    scale: _reduceMotion ? 1 : _scale.value,
                    child: ColorFiltered(
                      colorFilter: saturationFilter(_saturation.value),
                      child: Image.asset(
                        LaunchSplash.logoAsset,
                        width: LaunchSplash.logoSize.width,
                        height: LaunchSplash.logoSize.height,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        semanticLabel: AppLocalizations.of(context).appTitle,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.translate(
                    // Logonun altı + boşluk; slogan geldikçe yukarı kayar.
                    offset: Offset(0, half + 44 + (_reduceMotion ? 0 : 14 * (1 - t))),
                    child: Opacity(
                      opacity: t,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slogan,
                            textAlign: TextAlign.center,
                            style: sloganStyle.copyWith(
                              letterSpacing: _reduceMotion ? 0.2 : 0.2 + 2.4 * (1 - t),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: 44 * _underline.value,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppRadius.pillAll,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Doygunluk filtresi: 0 = siyah-beyaz, 1 = orijinal renkler.
/// Katsayılar (Rec. 709) iOS açılış ekranındaki gri logoyla aynı.
ColorFilter saturationFilter(double saturation) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final s = saturation.clamp(0.0, 1.0);
  final i = 1 - s;
  return ColorFilter.matrix(<double>[
    r * i + s, g * i, b * i, 0, 0, //
    r * i, g * i + s, b * i, 0, 0, //
    r * i, g * i, b * i + s, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);
}
