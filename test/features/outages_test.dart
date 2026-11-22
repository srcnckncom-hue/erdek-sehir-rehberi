import 'package:erdek_rehberi/features/outages/outages.dart';
import 'package:erdek_rehberi/features/outages/outages_screen.dart';
import 'package:erdek_rehberi/features/reminders/reminder_scheduler.dart';
import 'package:erdek_rehberi/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

final _data = OutagesData.fromJson({
  'areas': ['Cumhuriyet Mahallesi', 'Yalı Mahallesi', 'Ocaklar'],
  'outages': [
    {
      'id': 'su-1',
      'type': 'su',
      'areas': ['Cumhuriyet Mahallesi'],
      'startsAt': '2026-11-21T17:00',
      'endsAt': '2026-11-21T20:00',
    },
    {
      'id': 'elk-1',
      'type': 'elektrik',
      'areas': ['Yalı Mah.', 'Ocaklar'],
      'startsAt': '2026-11-22T09:00',
      'endsAt': '2026-11-22T15:00',
    },
    {'id': 'eski', 'type': 'su', 'areas': <String>[], 'startsAt': '2026-11-15T09:00', 'endsAt': '2026-11-15T12:00'},
    {'id': 'ariza', 'type': 'yok', 'areas': <String>[], 'startsAt': '2026-11-24T10:00'},
  ],
});

final _now = DateTime(2026, 11, 21, 18, 5);

void main() {
  test('mahalle adı: Mah./Mahallesi ve Türkçe harf farkı yok', () {
    expect(normalizeArea('Yalı Mah.'), 'yali');
    expect(normalizeArea('YALI MAHALLESİ'), 'yali');
    expect(normalizeArea('Mahmutbey'), 'mahmutbey');
    final elk = _data.outages[1];
    expect(elk.affects('yalı mahallesi'), isTrue);
    expect(elk.affects('Cumhuriyet'), isFalse);
    expect(_data.outages[2].affects('Herhangi'), isTrue); // tüm Erdek
  });

  test('güncel kesintiler: süren önce, bitenler yok; bitişsiz 12 saat sonra kalkar', () {
    expect(_data.current(_now).map((o) => o.id), ['su-1', 'elk-1', 'ariza']);
    final ariza = _data.outages[3];
    expect(ariza.type, OutageType.other);
    expect(ariza.endsAt, isNull);
    expect(ariza.isOverAt(DateTime(2026, 11, 24, 22, 1)), isTrue);
  });

  test('mahalle listesi tekrarsız; ana sayfa uyarısı mahallemi öne alır', () {
    expect(_data.allAreas(), ['Cumhuriyet Mahallesi', 'Ocaklar', 'Yalı Mahallesi']);
    expect(_data.headline(_now, null)?.id, 'su-1');
    expect(_data.headline(_now, 'Ocaklar')?.id, 'elk-1');
    // 24 saatten uzak arıza uyarıda çıkmaz.
    expect(_data.headline(DateTime(2026, 11, 22, 16), null), isNull);
  });

  test('metinler: bugün/yarın, giderilene kadar', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    expect(OutageStyle.when(l10n, _data.outages[0], _now), 'Bugün 17:00 – 20:00');
    expect(OutageStyle.when(l10n, _data.outages[1], _now), 'Yarın 09:00 – 15:00');
    expect(OutageStyle.when(l10n, _data.outages[3], _now), '24.11 10:00 – giderilene kadar');
    expect(OutageStyle.areas(l10n, _data.outages[3]), 'Tüm Erdek');
  });

  test('hatırlatma: yalnızca mahallemdekiler, 1 saat önce; kapalıysa silinir', () async {
    final scheduler = NoopReminderScheduler();
    Future<void> sync({required bool enabled, String? area}) => syncOutageReminders(
          scheduler: scheduler,
          data: _data,
          myArea: area,
          enabled: enabled,
          erdekNow: _now,
          title: (o) => o.id,
          body: (o) => '',
        );

    await sync(enabled: true, area: 'Ocaklar');
    // elk-1 (Ocaklar) + ariza (tüm Erdek); su-1 başlamış.
    expect(scheduler.scheduled.values.map((e) => e.$2), ['elk-1', 'ariza']);
    expect(scheduler.scheduled.values.first.$1, DateTime(2026, 11, 22, 8));
    expect(scheduler.scheduled.keys.first, NotificationIds.outageBase);

    await sync(enabled: false, area: 'Ocaklar');
    expect(scheduler.scheduled, isEmpty);
  });

  testWidgets('kesintiler sayfası: süren/planlı, mahallemi seç', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 5000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const OutagesScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Şu an süren'), findsOneWidget);
    expect(find.text('Planlı kesintiler'), findsOneWidget);
    expect(find.byKey(const Key('outage_su-1')), findsOneWidget);
    expect(find.byKey(const Key('outage_elk-1')), findsOneWidget);
    expect(find.byKey(const Key('outage_eski')), findsNothing);
    expect(find.text('Mahallende'), findsNothing);
    expect(find.byKey(const Key('outage_remind')), findsNothing);

    await tester.tap(find.byKey(const Key('outage_my_area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('area_Ocaklar')));
    await tester.pumpAndSettle();

    final c = ProviderScope.containerOf(tester.element(find.byType(OutagesScreen)));
    expect(c.read(myAreaProvider), 'Ocaklar');
    expect(find.text('Mahallende'), findsOneWidget);
    expect(find.byKey(const Key('outage_remind')), findsOneWidget);
  });

  testWidgets('ana sayfa uyarısı: süren kesinti', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(testApp(HomeOutageBanner(onTap: () => tapped++)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('Su kesintisi sürüyor'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_outage_banner')));
    expect(tapped, 1);
  });
}
