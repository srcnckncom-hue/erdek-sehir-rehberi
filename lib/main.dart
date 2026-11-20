import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/cache/hive_json_cache.dart';
import 'core/settings/seen_store.dart';
import 'core/time/erdek_time.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErdekTime.init();

  await Hive.initFlutter();
  final cacheBox = await Hive.openBox<String>(HiveJsonCache.boxName);
  final settingsBox = await Hive.openBox<String>(HiveAnnouncementsSeenStore.boxName);

  runApp(
    ProviderScope(
      overrides: [
        jsonCacheProvider.overrideWithValue(HiveJsonCache(cacheBox)),
        announcementsSeenStoreProvider.overrideWithValue(
          HiveAnnouncementsSeenStore(settingsBox),
        ),
      ],
      child: const ErdekApp(),
    ),
  );
}
