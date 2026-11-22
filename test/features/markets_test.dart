import 'package:erdek_rehberi/core/time/calendar_date.dart';
import 'package:erdek_rehberi/features/markets/markets.dart';
import 'package:erdek_rehberi/features/markets/markets_screen.dart';
import 'package:erdek_rehberi/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

final _data = MarketsData.fromJson({
  'markets': [
    {'id': 'cmt', 'name': 'Cumartesi', 'weekday': 6, 'startTime': '08:00', 'endTime': '14:00'},
    {'id': 'sali', 'name': 'Salı', 'weekday': 2},
    {
      'id': 'yaz',
      'name': 'Yaz',
      'weekday': 3,
      'months': [6, 7, 8],
    },
  ],
});

void main() {
  test('bugün açık olanlar: bitiş saatinden sonra düşer', () {
    expect(_data.todayOpen(DateTime(2026, 11, 21, 9)).map((m) => m.id), ['cmt']);
    expect(_data.todayOpen(DateTime(2026, 11, 21, 15)), isEmpty);
  });

  test('haftalık çizelge: mevsimlik pazar yalnızca kendi aylarında', () {
    expect(_data.byWeekday(const CalendarDate(2026, 11, 21)).keys.toSet(), {6, 2});
    expect(_data.byWeekday(const CalendarDate(2026, 7, 4)).keys.toSet(), {6, 2, 3});
    expect(_data.markets[2].nextDate(const CalendarDate(2026, 11, 21)), const CalendarDate(2027, 6, 2));
  });

  test('ay metni', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    expect(MarketTexts.months(l10n, _data.markets[2]), 'Haziran–Ağustos');
    expect(MarketTexts.hours(_data.markets[0]), '08:00–14:00');
    expect(MarketTexts.hours(_data.markets[1]), isNull);
  });

  testWidgets('pazarlar sayfası ve ana sayfa uyarısı', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 4000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const MarketsScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('Bugün pazar var: Merkez Pazarı'), findsOneWidget);
    expect(find.text('Bugün · Cumartesi'), findsOneWidget);
    expect(find.byKey(const Key('market_ocaklar')), findsOneWidget);
    expect(find.byKey(const Key('market_yaz')), findsNothing);

    await tester.pumpWidget(testApp(HomeMarketBanner(onTap: () {})));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_market_banner')), findsOneWidget);
  });
}
