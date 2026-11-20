import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_result.dart';
import '../../../core/data/offline_first_loader.dart';
import '../domain/announcement.dart';

abstract interface class AnnouncementsRepository {
  Stream<DataResult<AnnouncementsData>> watch();
}

class JsonAnnouncementsRepository implements AnnouncementsRepository {
  JsonAnnouncementsRepository(this._loader);

  static const path = 'announcements.json';

  final OfflineFirstLoader _loader;

  @override
  Stream<DataResult<AnnouncementsData>> watch() =>
      _loader.watch(path, AnnouncementsData.fromJson);
}

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>(
  (ref) => JsonAnnouncementsRepository(ref.watch(offlineFirstLoaderProvider)),
);

final announcementsProvider = StreamProvider<DataResult<AnnouncementsData>>(
  (ref) => ref.watch(announcementsRepositoryProvider).watch(),
);
