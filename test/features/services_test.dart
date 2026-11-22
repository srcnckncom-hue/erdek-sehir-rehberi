import 'package:erdek_rehberi/features/map/map_screen.dart';
import 'package:erdek_rehberi/features/nearby/points.dart';
import 'package:erdek_rehberi/features/services/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

final _data = ServicesData.fromJson({
  'points': [
    {'id': 't', 'type': 'taksi', 'name': 'Taksi', 'latitude': 40.39, 'longitude': 27.79},
    {'id': 'a', 'type': 'atm', 'name': 'ATM', 'latitude': 40.391, 'longitude': 27.791, 'note': 'Ziraat'},
    {'id': 'x', 'type': 'yok', 'name': 'X', 'latitude': 40.39, 'longitude': 27.79},
  ],
});

void main() {
  test('bilinmeyen tür atlanır; katman ve iğne türü', () {
    expect(_data.points.map((p) => p.type), [ServiceType.taxi, ServiceType.atm]);
    final points = collectPoints(erdekNow: DateTime(2026, 11, 21), pharmacyLabel: '', services: _data);
    expect(points.map((p) => p.layer), [MapLayer.taxi, MapLayer.atm]);
    expect(points.last.toPin()['kind'], 'atm');
    expect(points.last.subtitle, 'Ziraat');
    expect(filterLayers(points), [MapLayer.pharmacy, MapLayer.business, MapLayer.place, MapLayer.taxi, MapLayer.atm]);
  });

  testWidgets('harita: hizmet süzgeci ve bilgi penceresi', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 4000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const MapScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('ATM'), 100, scrollable: find.descendant(
      of: find.byKey(const Key('map_filter')),
      matching: find.byType(Scrollable),
    ));
    await tester.tap(find.text('ATM'));
    await tester.pumpAndSettle();
    expect(find.text('Çarşı ATM'), findsOneWidget);
    expect(find.text('Merkez Taksi'), findsNothing);

    await tester.tap(find.text('Çarşı ATM'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('service_sheet')), findsOneWidget);
    expect(find.byKey(const Key('service_directions')), findsOneWidget);
  });
}
