import 'package:erdek_rehberi/app/providers.dart';
import 'package:erdek_rehberi/core/settings/theme_store.dart';
import 'package:erdek_rehberi/features/explore/domain/explore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('Görünüm', () {
    test('varsayılan AÇIK; seçim kaydedilir', () async {
      final store = MemoryThemeModeStore();
      final container = ProviderContainer(
        overrides: [themeModeStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);
      await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(store.mode, ThemeMode.dark);
    });

    test('kayıtlı tercih açılışta okunur', () {
      final container = ProviderContainer(
        overrides: [
          themeModeStoreProvider.overrideWithValue(MemoryThemeModeStore(ThemeMode.system)),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('Gezilecek yer fotoğrafları', () {
    Map<String, dynamic> place({List<Object>? photos}) => {
          'id': 'yer-a',
          'title': 'Yer A',
          'area': 'erdek',
          'category': 'plaj',
          'summary': 'Özet',
          'paragraphs': ['Metin'],
          'photos': ?photos,
        };

    test('fotoğraf yoksa boş liste', () {
      expect(Place.fromJson(place()).photos, isEmpty);
    });

    test('adres ve isteğe bağlı kaynak okunur; sıra korunur', () {
      final p = Place.fromJson(
        place(
          photos: [
            {'url': 'https://ornek.test/1.jpg', 'credit': 'Sercan K.'},
            {'url': 'https://ornek.test/2.jpg'},
          ],
        ),
      );
      expect(p.photos.map((e) => e.url), ['https://ornek.test/1.jpg', 'https://ornek.test/2.jpg']);
      expect(p.photos.first.credit, 'Sercan K.');
      expect(p.photos.last.credit, isNull);
    });
  });
}
