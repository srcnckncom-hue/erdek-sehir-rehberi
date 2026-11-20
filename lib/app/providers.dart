import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/json_sources.dart';
import '../core/data/offline_first_loader.dart';
import '../core/network/dio_json_fetcher.dart';
import '../core/time/erdek_time.dart';
import 'env.dart';

/// Erdek saati. Testlerde `clockProvider.overrideWithValue(() => ...)`.
final clockProvider = Provider<Clock>((ref) => ErdekTime.now);

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
