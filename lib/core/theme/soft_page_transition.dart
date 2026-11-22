import 'package:material_ui/material_ui.dart';

/// Yumuşak sayfa geçişi: yeni sayfa hafifçe sağdan kayarak belirir, alttaki
/// sayfa biraz solar. "Hareketi azalt" açıksa efekt yok. Sol kenardan sağa
/// kaydırınca geri gider (iOS alışkanlığı).
class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final canSwipeBack = !route.isFirst && !route.fullscreenDialog;
    final page = canSwipeBack ? _EdgeSwipeBack(route: route, child: child) : child;
    if (MediaQuery.disableAnimationsOf(context)) return page;

    final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final covered = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(covered),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.04, 0)).animate(covered),
        child: FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(enter),
            child: page,
          ),
        ),
      ),
    );
  }
}

/// Sol kenardan (24 px) sağa hızlı ya da uzun kaydırma → geri.
class _EdgeSwipeBack extends StatefulWidget {
  const _EdgeSwipeBack({required this.route, required this.child});

  final PageRoute<dynamic> route;
  final Widget child;

  @override
  State<_EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<_EdgeSwipeBack> {
  double _dx = 0;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          widget.child,
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: 24,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) => _dx = 0,
              onHorizontalDragUpdate: (d) => _dx += d.delta.dx,
              onHorizontalDragEnd: (d) {
                if (_dx > 80 || (d.primaryVelocity ?? 0) > 400) widget.route.navigator?.maybePop();
              },
            ),
          ),
        ],
      );
}
