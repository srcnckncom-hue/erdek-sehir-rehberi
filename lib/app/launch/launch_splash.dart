import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Her açılışta oynayan animasyon (~2,8 sn):
/// 1) Amblem gri ÇİZGİLERLE çember boyunca (saat yönünde) çizilir.
/// 2) Çizim gri tonlarda dolar.
/// 3) Gri tonlar RENKLENİR.
/// 4) Altında sırayla: "ERDEK" (ortadan açılarak), "ŞEHİR REHBERİ", slogan.
///
/// iOS açılış ekranı (LaunchScreen.storyboard) boş beyazdır; animasyon da
/// beyaz zeminde başlar. Zemin her temada BEYAZ.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.onFinished, this.previewValue});

  static const emblemAsset = 'assets/images/logo_emblem.png';

  /// Amblemin çizgi hâli (aynı boyut; logodan üretildi).
  static const emblemLineAsset = 'assets/images/logo_emblem_line.png';
  static const erdekAsset = 'assets/images/logo_erdek.png';
  static const sehirAsset = 'assets/images/logo_sehir.png';

  /// main() bunları ilk kareden önce önbelleğe alır.
  static const precacheAssets = [emblemLineAsset, emblemAsset, erdekAsset, sehirAsset];

  // Parçaların piksel ölçüleri (assets/images/logo_*.png) ve logodaki
  // aralıklar (piksel). Oranlar korunur.
  static const _emblemPx = Size(778, 685);
  static const _erdekPx = Size(832, 185);
  static const _sehirPx = Size(715, 123);
  static const _gapEmblemErdek = 53.0;
  static const _gapErdekSehir = 23.0;
  static const _gapSehirSlogan = 37.0;

  static const duration = Duration(milliseconds: 2800);

  /// "Hareketi azalt" açıkken: çizim yok, yalnızca kısa geçişler.
  static const reducedDuration = Duration(milliseconds: 1000);

  static const sloganColor = Color(0xFF142036);

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

  Animation<double> _interval(double begin, double end, [Curve curve = Curves.easeInOut]) =>
      CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: curve));

  // Zaman çizelgesi (0–1)
  late final _draw = _interval(0.00, 0.40);
  late final _fill = _interval(0.32, 0.50);
  late final _lineOut = _interval(0.45, 0.56);
  late final _color = _interval(0.48, 0.62);
  late final _erdek = _interval(0.58, 0.72, Curves.easeOutCubic);
  late final _sehir = _interval(0.66, 0.80, Curves.easeOutCubic);
  late final _slogan = _interval(0.74, 0.88, Curves.easeOutCubic);

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
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final emblemWidth = math.min(230.0, width * 0.58);
    final k = emblemWidth / LaunchSplash._emblemPx.width;
    Size scaled(Size px) => Size(px.width * k, px.height * k);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: Colors.white,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _emblem(scaled(LaunchSplash._emblemPx), l10n.appTitle),
                SizedBox(height: LaunchSplash._gapEmblemErdek * k),
                _reveal(
                  _erdek.value,
                  wipe: true,
                  child: _image(LaunchSplash.erdekAsset, scaled(LaunchSplash._erdekPx)),
                ),
                SizedBox(height: LaunchSplash._gapErdekSehir * k),
                _reveal(
                  _sehir.value,
                  child: _image(LaunchSplash.sehirAsset, scaled(LaunchSplash._sehirPx)),
                ),
                SizedBox(height: LaunchSplash._gapSehirSlogan * k),
                _reveal(
                  _slogan.value,
                  child: Text(
                    l10n.splashSlogan,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      fontSize: emblemWidth * 0.082,
                      fontWeight: FontWeight.w500,
                      color: LaunchSplash.sloganColor,
                      letterSpacing: _reduceMotion ? 0.2 : 0.2 + 2.0 * (1 - _slogan.value),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Amblem: çizgi çizimi (çember boyunca açılır) → gri dolgu → renk.
  Widget _emblem(Size size, String label) {
    if (_reduceMotion) {
      return Opacity(
        opacity: _fill.value,
        child: _image(LaunchSplash.emblemAsset, size, semanticLabel: label),
      );
    }

    final drawn = _draw.value;
    final lineOpacity = 1 - _lineOut.value;
    return SizedBox.fromSize(
      size: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (lineOpacity > 0 && drawn > 0)
            Opacity(
              opacity: lineOpacity,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => _sweep(rect, drawn),
                child: _image(LaunchSplash.emblemLineAsset, size),
              ),
            ),
          Opacity(
            opacity: _fill.value,
            child: ColorFiltered(
              colorFilter: saturationFilter(_color.value),
              child: _image(LaunchSplash.emblemAsset, size, semanticLabel: label),
            ),
          ),
        ],
      ),
    );
  }

  /// Tepeden başlayıp saat yönünde [progress] kadarını gösteren maske.
  Shader _sweep(Rect rect, double progress) {
    final p = progress.clamp(0.0, 1.0);
    final soft = math.min(p + 0.03, 1.0);
    return SweepGradient(
      colors: const [Colors.white, Colors.white, Color(0x00FFFFFF), Color(0x00FFFFFF)],
      stops: [0, p, soft, 1],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);
  }

  /// Yazı parçası: yukarı kayarak belirir; [wipe] ise ortadan iki yana açılır.
  Widget _reveal(double t, {required Widget child, bool wipe = false}) {
    Widget result = Opacity(opacity: t, child: child);
    if (_reduceMotion) return result;
    if (wipe) result = _CenterWipe(progress: t, child: result);
    return Transform.translate(offset: Offset(0, 14 * (1 - t)), child: result);
  }

  Widget _image(String asset, Size size, {String? semanticLabel}) => Image.asset(
        asset,
        width: size.width,
        height: size.height,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
      );
}

/// Doygunluk filtresi: 0 = siyah-beyaz (gri tonlar), 1 = orijinal renkler.
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

/// Çocuğunu ortadan iki yana doğru açarak gösterir (0 = gizli, 1 = tam).
class _CenterWipe extends StatelessWidget {
  const _CenterWipe({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: _CenterWipeClipper(progress.clamp(0.0, 1.0)),
        child: child,
      );
}

class _CenterWipeClipper extends CustomClipper<Path> {
  _CenterWipeClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    final half = size.width / 2 * progress;
    return Path()
      ..addRect(Rect.fromLTRB(size.width / 2 - half, -20, size.width / 2 + half, size.height + 20));
  }

  @override
  bool shouldReclip(_CenterWipeClipper oldClipper) => oldClipper.progress != progress;
}
