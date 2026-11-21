import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Duyuruların en son görüldüğü an (zildeki rozet + "Yeni" etiketi).
/// Kalıcı kopyası AnnouncementsSeenStore'da (Hive 'settings' kutusu).
final announcementsLastSeenProvider =
    NotifierProvider<AnnouncementsLastSeenNotifier, DateTime?>(
  AnnouncementsLastSeenNotifier.new,
);

class AnnouncementsLastSeenNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => ref.watch(announcementsSeenStoreProvider).lastSeen;

  Future<void> markSeen(DateTime at) async {
    state = at;
    await ref.read(announcementsSeenStoreProvider).markSeen(at);
  }
}
