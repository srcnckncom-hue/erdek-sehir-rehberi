import 'package:erdek_rehberi/app/providers.dart';
import 'package:erdek_rehberi/core/data/json_sources.dart';
import 'package:erdek_rehberi/core/system/system_bridge.dart';
import 'package:erdek_rehberi/core/theme/app_theme.dart';
import 'package:erdek_rehberi/features/contacts/domain/contacts.dart';
import 'package:erdek_rehberi/features/emergency/emergency.dart';
import 'package:erdek_rehberi/features/emergency/emergency_screen.dart';
import 'package:erdek_rehberi/features/nearby/location_service.dart';
import 'package:erdek_rehberi/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  const point = GeoPoint(40.395512, 27.793049);

  test('koordinat ve harita bağlantısı', () {
    expect(formatCoordinates(point), '40.39551, 27.79305');
    final url = Uri.parse(emergencyMapsUrl(point));
    expect(url.host, 'www.google.com');
    expect(url.queryParameters['query'], '40.39551,27.79305');
  });

  test('paylaşım metni: başlık, bağlantı, koordinat', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    final text = emergencyShareText(l10n, point);
    final lines = text.split('\n');
    expect(lines.first, contains('Yardıma ihtiyacım var'));
    expect(lines[1], startsWith('https://www.google.com/maps/search/'));
    expect(text, contains('Koordinat: 40.39551, 27.79305'));
    expect(lines.last, contains('Erdek Şehir Rehberi'));
  });

  test('yerel numaralar: acil + kamu, 112 hariç, taksi yok', () {
    final data = ContactsData.fromJson({
      'categories': [
        {
          'id': 'acil',
          'title': 'Acil',
          'contacts': [
            {'name': 'Acil Çağrı', 'phone': '112'},
            {'name': 'Liman', 'phone': '+902660000001'},
          ],
        },
        {
          'id': 'kamu',
          'title': 'Kamu',
          'contacts': [
            {'name': 'Belediye', 'phone': '+902660000002'},
          ],
        },
        {
          'id': 'taksi',
          'title': 'Taksi',
          'contacts': [
            {'name': 'Merkez Taksi', 'phone': '+902660000003'},
          ],
        },
      ],
    });
    expect(localEmergencyContacts(data).map((c) => c.name), ['Liman', 'Belediye']);
    expect(localEmergencyContacts(null), isEmpty);
  });

  test('ulusal hatlar benzersiz ve 112 değil', () {
    final numbers = HelpLine.values.map((h) => h.number).toList();
    expect(numbers.toSet(), hasLength(numbers.length));
    expect(numbers, isNot(contains(Emergency.number)));
    expect(Emergency.assemblyAreaUrl, startsWith('https://www.turkiye.gov.tr/'));
  });

  testWidgets('acil ekranı: 112, hatlar, toplanma alanı; konum alınamazsa açıklama', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 6000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const EmergencyScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emergency_112')), findsOneWidget);
    expect(find.text('Acil Çağrı Merkezi'), findsOneWidget);
    expect(find.text('Ulusal Zehir Danışma Merkezi'), findsOneWidget);
    expect(find.byKey(const Key('emergency_assembly')), findsOneWidget);

    await tester.tap(find.byKey(const Key('emergency_locate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('emergency_location_error')), findsOneWidget);
    expect(find.text('Konum alınamadı'), findsOneWidget);
  });

  testWidgets('konum bulunca koordinat görünür ve paylaşılır', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 6000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final bridge = NoopSystemBridge();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jsonCacheProvider.overrideWithValue(MemoryJsonCache()),
          jsonFetcherProvider.overrideWithValue(FileJsonFetcher()),
          bundledJsonProvider.overrideWithValue(FileBundledJsonSource()),
          clockProvider.overrideWithValue(() => testNow),
          nowProvider.overrideWith((ref) => Stream.value(testNow)),
          locationServiceProvider.overrideWithValue(const FakeLocationService(point)),
          systemBridgeProvider.overrideWithValue(bridge),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('tr'),
          supportedLocales: const [Locale('tr')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const EmergencyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('emergency_locate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('emergency_location_ready')), findsOneWidget);
    expect(find.text('40.39551, 27.79305'), findsOneWidget);

    await tester.tap(find.byKey(const Key('emergency_share_other')));
    await tester.pump();
    expect(bridge.shared.single, contains('27.79305'));
  });
}
