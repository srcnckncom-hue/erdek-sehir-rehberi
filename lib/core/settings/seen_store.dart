import 'package:hive_ce_flutter/hive_flutter.dart';

/// Duyurular en son ne zaman görüldü (zildeki rozet sayısı için).
/// Kişisel veri değildir; yalnızca cihazda tutulur.
abstract interface class AnnouncementsSeenStore {
  DateTime? get lastSeen;

  Future<void> markSeen(DateTime at);
}

class HiveAnnouncementsSeenStore implements AnnouncementsSeenStore {
  HiveAnnouncementsSeenStore(this.box);

  static const boxName = 'settings';
  static const _key = 'announcements_last_seen';

  final Box<String> box;

  @override
  DateTime? get lastSeen => DateTime.tryParse(box.get(_key) ?? '');

  @override
  Future<void> markSeen(DateTime at) => box.put(_key, at.toUtc().toIso8601String());
}

class MemoryAnnouncementsSeenStore implements AnnouncementsSeenStore {
  MemoryAnnouncementsSeenStore([this.lastSeen]);

  @override
  DateTime? lastSeen;

  @override
  Future<void> markSeen(DateTime at) async => lastSeen = at;
}
