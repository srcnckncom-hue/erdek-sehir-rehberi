import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/data/json_sources.dart';
import '../core/data/offline_first_loader.dart';
import '../core/network/content_json_fetcher.dart';
import '../core/network/dio_json_fetcher.dart';
import '../core/settings/onboarding_store.dart';
import '../core/settings/seen_store.dart';
import '../core/settings/theme_store.dart';
import '../core/settings/usage_store.dart';
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

/// main() içinde Hive ile override edilir. Varsayılan "görüldü": testler ve
/// önizlemeler tanıtım ekranına takılmasın.
final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => MemoryOnboardingStore(isDone: true),
);

/// main() içinde Hive ile override edilir (puanlama penceresi zamanlaması).
final usageStoreProvider = Provider<UsageStore>((ref) => MemoryUsageStore());

/// main() içinde Hive ile override edilir.
final themeModeStoreProvider = Provider<ThemeModeStore>((ref) => MemoryThemeModeStore());

/// Görünüm: Açık (varsayılan) / Koyu / Telefonla aynı. ☰ menüden değiştirilir.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(themeModeStoreProvider).load();

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(themeModeStoreProvider).save(mode);
  }
}

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

/// Önce Supabase (panelden düzenlenen içerikler), yoksa GitHub Pages.
final jsonFetcherProvider = Provider<JsonFetcher>(
  (ref) => ContentJsonFetcher(
    dio: ref.watch(dioProvider),
    fallback: DioJsonFetcher(ref.watch(dioProvider), baseUrl: Env.dataBaseUrl),
    supabaseUrl: Env.supabaseUrl,
    apiKey: Env.supabaseAnonKey,
  ),
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
