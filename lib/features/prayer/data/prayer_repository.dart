import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_result.dart';
import '../../../core/data/offline_first_loader.dart';
import '../domain/prayer_times.dart';

/// Vakitler uygulamadan Diyanet'e DOĞRUDAN istenmez: haftalık GitHub
/// Actions cron'u (6. adım) Awqat Salah API'sinden çekip
/// data/prayer_times.json olarak yayınlar; uygulama yalnızca onu okur.
abstract interface class PrayerRepository {
  Stream<DataResult<PrayerTimesData>> watch();
}

class JsonPrayerRepository implements PrayerRepository {
  JsonPrayerRepository(this._loader);

  static const path = 'prayer_times.json';

  final OfflineFirstLoader _loader;

  @override
  Stream<DataResult<PrayerTimesData>> watch() =>
      _loader.watch(path, PrayerTimesData.fromJson);
}

final prayerRepositoryProvider = Provider<PrayerRepository>(
  (ref) => JsonPrayerRepository(ref.watch(offlineFirstLoaderProvider)),
);

final prayerTimesProvider = StreamProvider<DataResult<PrayerTimesData>>(
  (ref) => ref.watch(prayerRepositoryProvider).watch(),
);
