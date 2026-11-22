import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/data_result.dart';

/// Panelden değiştirilebilen görünüm ayarları (data/appearance.json).
class AppearanceData {
  const AppearanceData({this.heroImages = const []});

  factory AppearanceData.fromJson(Map<String, dynamic> json) => AppearanceData(
        heroImages: [
          for (final h in json['heroImages'] as List<dynamic>? ?? const [])
            if ((h as Map<String, dynamic>)['url'] case final String url when url.startsWith('https://')) url,
        ],
      );

  /// Ana sayfadaki hava durumu kartının arka planı. Birden fazlaysa her gün
  /// sıradaki gösterilir; boşsa uygulamayla gelen fotoğraf.
  final List<String> heroImages;

  /// [date] gününün fotoğrafı (yılın gününe göre döner).
  String? heroFor(DateTime date) {
    if (heroImages.isEmpty) return null;
    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    return heroImages[dayOfYear % heroImages.length];
  }
}

final appearanceProvider = StreamProvider<DataResult<AppearanceData>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('appearance.json', AppearanceData.fromJson),
);

/// Bugünün ana sayfa arka planı (yoksa null → uygulamayla gelen).
final heroImageUrlProvider = Provider<String?>((ref) {
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
  return ref.watch(appearanceProvider).value?.data.heroFor(now);
});
