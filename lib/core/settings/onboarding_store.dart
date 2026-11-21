import 'package:hive_ce_flutter/hive_flutter.dart';

/// Tanıtım ekranları (ilk açılış) görüldü mü? Yalnızca cihazda tutulur.
abstract interface class OnboardingStore {
  bool get isDone;

  Future<void> markDone();
}

class HiveOnboardingStore implements OnboardingStore {
  HiveOnboardingStore(this.box);

  /// Tanıtım içeriği köklü değişirse anahtar sürümü artırılarak
  /// herkese yeniden gösterilebilir.
  static const _key = 'onboarding_done_v1';

  final Box<String> box;

  @override
  bool get isDone => box.get(_key) == 'true';

  @override
  Future<void> markDone() => box.put(_key, 'true');
}

class MemoryOnboardingStore implements OnboardingStore {
  MemoryOnboardingStore({this.isDone = false});

  @override
  bool isDone;

  @override
  Future<void> markDone() async => isDone = true;
}
