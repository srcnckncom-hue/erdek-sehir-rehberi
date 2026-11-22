import 'package:erdek_rehberi/features/businesses/domain/business.dart';
import 'package:erdek_rehberi/features/businesses/presentation/business_detail_screen.dart';
import 'package:erdek_rehberi/features/favorites/favorites.dart';
import 'package:erdek_rehberi/features/favorites/favorites_screen.dart';
import 'package:erdek_rehberi/features/nearby/points.dart';
import 'package:erdek_rehberi/features/pharmacy/domain/pharmacy.dart';
import 'package:erdek_rehberi/features/reminders/reminder_scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

final _businesses = BusinessesData.fromJson({
  'categories': [
    {'id': 'k', 'title': 'Kafe'},
  ],
  'businesses': [
    {'id': 'liman-kafe', 'name': 'Liman Kafe', 'categoryId': 'k'},
  ],
});

final _pharmacy = PharmacyData.fromJson({
  'pharmacies': [
    {'id': 'a', 'name': 'A Eczanesi', 'address': 'Çarşı', 'phone': '+902660000001'},
    {'id': 'b', 'name': 'B Eczanesi', 'address': 'Sahil', 'phone': '+902660000002'},
  ],
  'duties': [
    {
      'date': '2026-11-21',
      'pharmacyIds': ['a'],
    },
  ],
});

void main() {
  test('favoriler: sıra korunur, silinenler atlanır, nöbetçi etiketi', () {
    final items = resolveFavorites(
      keys: ['pharmacy:b', 'place:yok', 'business:liman-kafe', 'pharmacy:a', 'bozuk'],
      erdekNow: DateTime(2026, 11, 21, 18),
      onDutyLabel: 'Bugün nöbetçi',
      pharmacy: _pharmacy,
      businesses: _businesses,
    );
    expect(items.map((e) => e.title), ['B Eczanesi', 'Liman Kafe', 'A Eczanesi']);
    expect(items[0].subtitle, 'Sahil');
    expect(items[1].kind, PointKind.business);
    expect(items[1].subtitle, 'Kafe');
    expect(items[2].subtitle, 'Bugün nöbetçi');
  });

  test('ekle / çıkar, en yeni başta, cihaza yazılır', () async {
    final store = MemoryReminderStore();
    final c = ProviderContainer(overrides: [reminderStoreProvider.overrideWithValue(store)]);
    addTearDown(c.dispose);
    final notifier = c.read(favoritesProvider.notifier);

    expect(await notifier.toggle('business:x'), isTrue);
    expect(await notifier.toggle('place:y'), isTrue);
    expect(c.read(favoritesProvider), ['place:y', 'business:x']);
    expect(store.read(FavoritesNotifier.storeKey), contains('business:x'));

    expect(await notifier.toggle('business:x'), isFalse);
    expect(c.read(favoritesProvider), ['place:y']);

    // Yeniden açılışta cihazdan okunur.
    final c2 = ProviderContainer(overrides: [reminderStoreProvider.overrideWithValue(store)]);
    addTearDown(c2.dispose);
    expect(c2.read(favoritesProvider), ['place:y']);
  });

  testWidgets('boş favoriler: açıklama', (tester) async {
    await tester.pumpWidget(testApp(const FavoritesScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('favorites_empty')), findsOneWidget);
    expect(find.text('Henüz favori yok'), findsOneWidget);
  });

  testWidgets('işletme sayfasında yıldız: ekler ve kaldırır', (tester) async {
    final b = _businesses.businesses.single;
    await tester.pumpWidget(testApp(BusinessDetailScreen(business: b)));
    await tester.pumpAndSettle();

    final star = find.byKey(const Key('fav_business:liman-kafe'));
    expect(star, findsOneWidget);
    await tester.tap(star);
    await tester.pump();
    expect(find.text('Favorilere eklendi'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(BusinessDetailScreen)));
    expect(container.read(favoritesProvider), ['business:liman-kafe']);

    await tester.tap(star);
    await tester.pump();
    expect(container.read(favoritesProvider), isEmpty);

    // Bildirim (SnackBar) süresinin dolmasını bekle; zamanlayıcı kalmasın.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
