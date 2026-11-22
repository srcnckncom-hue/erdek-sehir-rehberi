import 'package:erdek_rehberi/features/home/home_layout.dart';
import 'package:erdek_rehberi/features/home/presentation/home_layout_screen.dart';
import 'package:erdek_rehberi/features/home/presentation/today_card.dart';
import 'package:erdek_rehberi/features/reminders/reminder_scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  test('kutucuklar: varsayılan, kaydet, bilinmeyen ad atlanır, sıfırla', () async {
    final store = MemoryReminderStore();
    final c = ProviderContainer(overrides: [reminderStoreProvider.overrideWithValue(store)]);
    addTearDown(c.dispose);
    expect(c.read(homeTilesProvider), HomeTile.defaults);

    await c.read(homeTilesProvider.notifier).set([HomeTile.favorites, HomeTile.bus, HomeTile.favorites]);
    expect(c.read(homeTilesProvider), [HomeTile.favorites, HomeTile.bus]);
    expect(store.read(HomeTilesNotifier.storeKey), 'favorites,bus');

    await store.write(HomeTilesNotifier.storeKey, 'trips,yok,map');
    c.invalidate(homeTilesProvider);
    expect(c.read(homeTilesProvider), [HomeTile.trips, HomeTile.map]);

    await c.read(homeTilesProvider.notifier).reset();
    expect(c.read(homeTilesProvider), HomeTile.defaults);
  });

  testWidgets('düzenle: anahtarla kutucuk eklenir', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 6000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const HomeLayoutScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home_layout_favorites')));
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(tester.element(find.byType(HomeLayoutScreen)));
    expect(c.read(homeTilesProvider).last, HomeTile.favorites);
    expect(find.byKey(const Key('home_layout_reset')), findsOneWidget);
  });

  testWidgets("Erdek'te bugün: kesinti, hava, eczane, pazar, etkinlik; kasımda deniz yok", (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 4000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var outages = 0;
    await tester.pumpWidget(testApp(TodayCard(
      onWeather: () {},
      onSea: () {},
      onPharmacy: () {},
      onMarkets: () {},
      onEvents: () {},
      onOutages: () => outages++,
    )));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('today_card')), findsOneWidget);
    for (final k in ['today_outage', 'today_weather', 'today_pharmacy', 'today_market', 'today_event']) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
    expect(find.byKey(const Key('today_sea')), findsNothing);
    await tester.tap(find.byKey(const Key('today_outage')));
    expect(outages, 1);
  });
}
