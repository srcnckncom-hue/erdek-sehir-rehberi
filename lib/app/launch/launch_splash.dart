import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Her açılışta oynayan animasyon:
/// 1) Amblem küçükten büyüyerek 3 tur döner, yerine oturur; üzerinden ışık geçer.
/// 2) Altında sırayla: "ERDEK" (ortadan açılarak), "ŞEHİR REHBERİ", slogan.
///
/// iOS açılış ekranı (LaunchScreen.storyboard) boş beyazdır; animasyon da
/// beyaz zeminde başlar, geçiş fark edilmez. Zemin her temada BEYAZ.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.onFinished, this.previewValue});

  static const emblemAsset = 'assets/images/logo_emblem.png';
  static const erdekAsset = 'assets/images/logo_erdek.png';
  static const sehirAsset = 'assets/images/logo_sehir.png';

  /// main() bunları ilk kareden önce önbelleğe alır.
  static const precacheAssets = [emblemAsset, erdekAsset, sehirAsset];

  // Parçaların piksel ölçüleri (assets/images/logo_*.png). Oranlar korunur.
  static const _emblemPx = Size(759, 702);
  static const _erdekPx = Size(860, 197);
  static const _sehirPx = Size(717, 123);

  static const duration = Duration(milliseconds: 3200);

  /// "Hareketi azalt" açıkken: dönme yok, yalnızca kısa geçişler.
  static const reducedDuration = Duration(milliseconds: 1200);

  /// Amblemin dönüş sayısı.
  static const turns = 3;

  static const sloganColor = Color(0xFF1C2439);

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

  Animation<double> _interval(double begin, double end, Curve curve) => CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve),
      );

  // Zaman çizelgesi (0–1)
  late final _emblemFade = _interval(0.0, 0.12, Curves.easeOut);
  late final _emblemSpin = _interval(0.0, 0.50, Curves.easeOutCubic);
  late final _emblemScale = _interval(0.0, 0.50, Curves.easeOutBack);
  late final _shine = _interval(0.48, 0.68, Curves.easeInOut);
  late final _erdek = _interval(0.50, 0.68, Curves.easeOutCubic);
  late final _sehir = _interval(0.62, 0.80, Curves.easeOutCubic);
  late final _slogan = _interval(0.74, 0.92, Curves.easeOutCubic);

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
    // Amblem genişliği; diğer parçalar aynı ölçekle (logodaki oranlar).
    final emblemWidth = math.min(220.0, width * 0.56);
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
                SizedBox(height: 37 * k),
                _reveal(
                  _erdek.value,
                  wipe: true,
                  child: _image(LaunchSplash.erdekAsset, scaled(LaunchSplash._erdekPx)),
                ),
                SizedBox(height: 12 * k),
                _reveal(
                  _sehir.value,
                  child: _image(LaunchSplash.sehirAsset, scaled(LaunchSplash._sehirPx)),
                ),
                SizedBox(height: 28 * k),
                _reveal(
                  _slogan.value,
                  child: Text(
                    l10n.splashSlogan,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      fontSize: emblemWidth * 0.078,
                      fontWeight: FontWeight.w500,
                      color: LaunchSplash.sloganColor,
                      letterSpacing: _reduceMotion ? 0.3 : 0.3 + 2.0 * (1 - _slogan.value),
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

  /// Amblem: büyüyerek döner, sonunda üzerinden çapraz bir ışık geçer.
  Widget _emblem(Size size, String label) {
    final t = _emblemSpin.value;
    final angle = _reduceMotion ? 0.0 : -2 * math.pi * LaunchSplash.turns * (1 - t);
    final scale = _reduceMotion ? 1.0 : 0.15 + 0.85 * _emblemScale.value;
    final shine = _shine.value;

    Widget image = _image(LaunchSplash.emblemAsset, size, semanticLabel: label);
    if (!_reduceMotion && shine > 0 && shine < 1) {
      image = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final x = -0.6 + 2.2 * shine; // ışık bandının konumu (soldan sağa)
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0x00FFFFFF), Color(0x99FFFFFF), Color(0x00FFFFFF)],
            stops: [
              (x - 0.18).clamp(0.0, 1.0),
              x.clamp(0.0, 1.0),
              (x + 0.18).clamp(0.0, 1.0),
            ],
          ).createShader(rect);
        },
        child: image,
      );
    }

    return Opacity(
      opacity: _emblemFade.value,
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(scale: scale, child: image),
      ),
    );
  }

  /// Yazı parçası: yukarı kayarak belirir; [wipe] ise ortadan iki yana açılır.
  Widget _reveal(double t, {required Widget child, bool wipe = false}) {
    Widget result = Opacity(opacity: t, child: child);
    if (_reduceMotion) return result;
    if (wipe) {
      result = _CenterWipe(progress: t, child: result);
    }
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
