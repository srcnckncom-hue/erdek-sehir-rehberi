import 'dart:io';

import 'package:erdek_rehberi/app/providers.dart';
import 'package:erdek_rehberi/core/data/data_result.dart';
import 'package:erdek_rehberi/core/data/json_sources.dart';
import 'package:erdek_rehberi/core/settings/seen_store.dart';
import 'package:erdek_rehberi/core/theme/app_theme.dart';
import 'package:erdek_rehberi/features/weather/data/weather_repository.dart';
import 'package:erdek_rehberi/features/weather/domain/weather.dart';
import 'package:erdek_rehberi/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Testlerde sabit "şu an": 21 Kasım 2026 Cumartesi 18:05 (Erdek saati).
/// Bu anda: nöbet günü 21.11, sıradaki vakit Yatsı 19:00 (55 dk),
/// sıradaki feribot yarın 09:00, sıradaki otobüs bugün 19:00.
final testNow = DateTime(2026, 11, 21, 18, 5);

/// İnternete çıkmadan: "uzak" JSON olarak repo'daki data/ dosyaları.
/// Diskten EŞZAMANLI okunur; test zamanlamasından bağımsız (asset yükleme
/// sahte zamanlı testlerde gecikebiliyor).
class FileJsonFetcher implements JsonFetcher {
  @override
  Future<String> fetch(String path) async => File('data/$path').readAsStringSync();
}

/// Uygulamayla gelen kopya yerine aynı dosyalar (eşzamanlı).
class FileBundledJsonSource implements BundledJsonSource {
  @override
  Future<String?> read(String path) async {
    final file = File('data/$path');
    return file.existsSync() ? file.readAsStringSync() : null;
  }
}

final testWeather = DataResult<CurrentWeather>(
  data: CurrentWeather(
    temperatureC: 16.2,
    symbolCode: 'partlycloudy_day',
    time: DateTime.utc(2026, 11, 21, 15),
    relativeHumidity: 72,
    windSpeedMs: 3.4,
    minTemperatureC: 14,
    maxTemperatureC: 22,
  ),
  origin: DataOrigin.network,
  isSample: false,
  updatedAt: DateTime.utc(2026, 11, 21, 15),
  fetchedAt: testNow,
);

/// Ağ, Hive ve gerçek saat olmadan uygulamayı çalıştıran ProviderScope.
Widget testScope({required Widget child, DateTime? now}) {
  final fixed = now ?? testNow;
  return ProviderScope(
    overrides: [
      jsonCacheProvider.overrideWithValue(MemoryJsonCache()),
      jsonFetcherProvider.overrideWithValue(FileJsonFetcher()),
      bundledJsonProvider.overrideWithValue(FileBundledJsonSource()),
      announcementsSeenStoreProvider.overrideWithValue(MemoryAnnouncementsSeenStore()),
      clockProvider.overrideWithValue(() => fixed),
      nowProvider.overrideWith((ref) => Stream.value(fixed)),
      currentWeatherProvider.overrideWith((ref) => Stream.value(testWeather)),
    ],
    child: child,
  );
}

/// Tek bir ekranı tema + Türkçe metinlerle test etmek için.
Widget testApp(Widget home, {DateTime? now}) => testScope(
      now: now,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('tr'),
        supportedLocales: const [Locale('tr')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(body: home),
      ),
    );
