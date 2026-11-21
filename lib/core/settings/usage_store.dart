import 'package:hive_ce_flutter/hive_flutter.dart';

/// Puanlama penceresini doğru zamanda istemek için yalnızca cihazda tutulan
/// sayaçlar (kişisel veri değil, hiçbir yere gönderilmez).
abstract interface class UsageStore {
  int get launchCount;
  DateTime? get firstLaunch;
  bool get reviewAsked;

  Future<void> recordLaunch(DateTime now);
  Future<void> markReviewAsked();
}

class HiveUsageStore implements UsageStore {
  HiveUsageStore(this.box);

  static const _count = 'usage_launch_count';
  static const _first = 'usage_first_launch';
  static const _asked = 'usage_review_asked';

  final Box<String> box;

  @override
  int get launchCount => int.tryParse(box.get(_count) ?? '') ?? 0;

  @override
  DateTime? get firstLaunch => DateTime.tryParse(box.get(_first) ?? '');

  @override
  bool get reviewAsked => box.get(_asked) == 'true';

  @override
  Future<void> recordLaunch(DateTime now) async {
    if (firstLaunch == null) await box.put(_first, now.toUtc().toIso8601String());
    await box.put(_count, '${launchCount + 1}');
  }

  @override
  Future<void> markReviewAsked() => box.put(_asked, 'true');
}

class MemoryUsageStore implements UsageStore {
  MemoryUsageStore({this.launchCount = 0, this.firstLaunch, this.reviewAsked = false});

  @override
  int launchCount;

  @override
  DateTime? firstLaunch;

  @override
  bool reviewAsked;

  @override
  Future<void> recordLaunch(DateTime now) async {
    firstLaunch ??= now;
    launchCount++;
  }

  @override
  Future<void> markReviewAsked() async => reviewAsked = true;
}

/// En az 5. açılış ve ilk açılıştan en az 3 gün sonra, bir kez sorulur.
/// (Apple ayrıca yılda en fazla 3 kez gösterir.)
bool shouldAskForReview(UsageStore store, DateTime now) {
  final first = store.firstLaunch;
  return !store.reviewAsked &&
      store.launchCount >= 5 &&
      first != null &&
      now.difference(first).inDays >= 3;
}
