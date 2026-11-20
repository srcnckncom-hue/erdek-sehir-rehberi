import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/json_sources.dart';
import '../core/data/offline_first_loader.dart';
import '../core/network/dio_json_fetcher.dart';
import '../core/settings/seen_store.dart';
import '../core/time/erdek_time.dart';
import 'env.dart';

/// Erdek saati. Testlerde `clockProvider.overrideWithValue(() => ...)`.
final clockProvider = Provider<Clock>((ref) => ErdekTime.now);

/// Erdek saatiyle "şu an"; geri sayımlar için 30 saniyede bir yenilenir.
/// Testlerde sabit bir zamanla override edilir.
final nowProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock();
  yield* Stream<DateTime>.periodic(const Duration(seconds: 30), (_) => clock());
});

/// main() içinde Hive ile override edilir.
final announcementsSeenStoreProvider = Provider<AnnouncementsSeenStore>(
  (ref) => MemoryAnnouncementsSeenStore(),
);

/// main() içinde HiveJsonCache ile override edilir.
final jsonCacheProvider = Provider<JsonCache>(
  (ref) => throw UnimplementedError('jsonCacheProvider main() içinde override edilmeli.'),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final jsonFetcherProvider = Provider<JsonFetcher>(
  (ref) => DioJsonFetcher(ref.watch(dioProvider), baseUrl: Env.dataBaseUrl),
);

final bundledJsonProvider = Provider<BundledJsonSource>(
  (ref) => AssetBundledJsonSource(),
);

final offlineFirstLoaderProvider = Provider<OfflineFirstLoader>(
  (ref) => OfflineFirstLoader(
    fetcher: ref.watch(jsonFetcherProvider),
    cache: ref.watch(jsonCacheProvider),
    bundled: ref.watch(bundledJsonProvider),
  ),
);
