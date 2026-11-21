import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/ads/presentation/ad_slot.dart';
import '../providers.dart';
import '../shell/app_shell.dart';
import 'launch_splash.dart';
import 'onboarding_screen.dart';

/// Açılış sırası: animasyonlu logo (her açılışta) → tanıtım (yalnız ilk
/// açılışta) → ana iskelet.
///
/// Ana iskelet en baştan, perdenin ARKASINDA kurulur: veriler (vakit, eczane,
/// hava, reklam) animasyon oynarken yüklenir, perde kalkınca ana sayfa hazırdır.
/// Perde açıkken arkadaki reklam gösterimleri sayılmaz ([AdImpressionGate]).
class LaunchGate extends ConsumerStatefulWidget {
  const LaunchGate({super.key, this.child = const AppShell()});

  final Widget child;

  @override
  ConsumerState<LaunchGate> createState() => _LaunchGateState();
}

enum _Phase { splash, onboarding, done }

class _LaunchGateState extends ConsumerState<LaunchGate> {
  _Phase _phase = _Phase.splash;

  void _onSplashFinished() {
    final needsOnboarding = !ref.read(onboardingStoreProvider).isDone;
    setState(() => _phase = needsOnboarding ? _Phase.onboarding : _Phase.done);
  }

  void _onOnboardingFinished() => setState(() => _phase = _Phase.done);

  @override
  Widget build(BuildContext context) {
    final covered = _phase != _Phase.done;
    final overlay = switch (_phase) {
      _Phase.splash => LaunchSplash(
          key: const ValueKey('splash'),
          onFinished: _onSplashFinished,
        ),
      _Phase.onboarding => OnboardingScreen(
          key: const ValueKey('onboarding'),
          onFinished: _onOnboardingFinished,
        ),
      _Phase.done => const SizedBox.shrink(key: ValueKey('done')),
    };

    return AdImpressionGate(
      paused: covered,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            ignoring: covered,
            child: ExcludeSemantics(excluding: covered, child: widget.child),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, ?current],
            ),
            child: overlay,
          ),
        ],
      ),
    );
  }
}
