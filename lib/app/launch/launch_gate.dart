import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/settings/usage_store.dart';
import '../../core/system/system_bridge.dart';
import '../../features/ads/presentation/ad_slot.dart';
import '../../features/push/push_service.dart';
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
    unawaited(_countLaunch(askReview: !needsOnboarding));
  }

  /// Açılışı sayar; yeterince kullanıldıysa (bkz. [shouldAskForReview]) bir
  /// kez Apple'ın puanlama penceresini ister. Tanıtım ekranı açılışında sormaz.
  Future<void> _countLaunch({required bool askReview}) async {
    // Duyuru bildirimleri açıksa aboneliği tazele.
    await ref.read(announcementsPushProvider.notifier).refresh();
    final store = ref.read(usageStoreProvider);
    final now = ref.read(clockProvider)();
    await store.recordLaunch(now);
    if (!askReview || !shouldAskForReview(store, now)) return;
    await store.markReviewAsked();
    // Ana sayfa göründükten biraz sonra, kullanıcıyı bölmeden.
    await Future<void>.delayed(const Duration(seconds: 4));
    if (mounted) await ref.read(systemBridgeProvider).requestReview();
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
