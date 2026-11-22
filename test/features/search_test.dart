import 'package:erdek_rehberi/app/shell/app_tab.dart';
import 'package:erdek_rehberi/features/businesses/domain/business.dart';
import 'package:erdek_rehberi/features/contacts/domain/contacts.dart';
import 'package:erdek_rehberi/features/explore/domain/explore.dart';
import 'package:erdek_rehberi/features/pharmacy/domain/pharmacy.dart';
import 'package:erdek_rehberi/features/search/domain/search_index.dart';
import 'package:erdek_rehberi/features/search/presentation/search_screen.dart';
import 'package:erdek_rehberi/features/search/recent_searches.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  final pharmacy = PharmacyData.fromJson({
    'pharmacies': [
      {'id': 'a', 'name': 'Merkez Eczanesi', 'address': 'Yalı Cd.', 'phone': '+900000000000'},
      {'id': 'b', 'name': 'Deniz Eczanesi', 'address': 'Çarşı', 'phone': '+900000000000'},
    ],
    'duties': <Map<String, dynamic>>[],
  });
  final contacts = ContactsData.fromJson({
    'categories': [
      {
        'id': 'kamu',
        'title': 'Kamu Kurumları',
        'contacts': [
          {'name': 'Erdek Belediyesi', 'phone': '+900000000000'},
          {'name': 'Liman Başkanlığı', 'phone': '+900000000000'},
        ],
      },
    ],
  });

  test('2 harften kısa sorgu sonuç vermez', () {
    expect(searchAll(query: 'e', now: DateTime(2026), pharmacy: pharmacy).isEmpty, isTrue);
  });

  test('eczane adı ve adreste, Türkçe harf duyarsız', () {
    final r = searchAll(query: 'carsi', now: DateTime(2026), pharmacy: pharmacy);
    expect(r.pharmacies.map((p) => p.name), ['Deniz Eczanesi']);
  });

  test('telefonlarda kategori adıyla da bulunur', () {
    final r = searchAll(query: 'kamu', now: DateTime(2026), contacts: contacts);
    expect(r.contacts, hasLength(2));
    final r2 = searchAll(query: 'LİMAN', now: DateTime(2026), contacts: contacts);
    expect(r2.contacts.single.name, 'Liman Başkanlığı');
  });

  test('gezilecek yerlerde başlık ve özette arar', () {
    final places = PlacesData.fromJson({
      'places': [
        {
          'id': 'a',
          'title': 'Zeytin Adası',
          'area': 'erdek',
          'category': 'manzara',
          'summary': 'Kıyıya yakın küçük ada.',
          'paragraphs': ['Metin'],
        },
        {
          'id': 'b',
          'title': 'Orman Yolu',
          'area': 'kapidag',
          'category': 'doga',
          'summary': 'Çam ormanı içinde yürüyüş.',
          'paragraphs': ['Metin'],
        },
      ],
    });
    expect(searchAll(query: 'ZEYTIN', now: DateTime(2026), places: places).places.single.id, 'a');
    expect(searchAll(query: 'cam orman', now: DateTime(2026), places: places).places.single.id, 'b');
  });

  const titles = {
    SearchPage.wind: 'Rüzgâr durumu',
    SearchPage.ramadan: 'Ramazan',
    SearchPage.emergency: 'Acil Durum',
    SearchPage.ferry: 'Feribot Saatleri',
  };

  test('sayfalar: anahtar kelimeyle (poyraz → rüzgâr, iftar → Ramazan)', () {
    expect(searchAll(query: 'poyraz', now: DateTime(2026), pageTitles: titles).pages, [SearchPage.wind]);
    expect(searchAll(query: 'IFTAR', now: DateTime(2026), pageTitles: titles).pages, [SearchPage.ramadan]);
    expect(searchAll(query: 'avsa', now: DateTime(2026), pageTitles: titles).pages, [SearchPage.ferry]);
    // Adı verilmeyen sayfa çıkmaz.
    expect(searchAll(query: 'harita', now: DateTime(2026), pageTitles: titles).pages, isEmpty);
  });

  test('acil hatlar ve işletmeler', () {
    final r = searchAll(
      query: 'zehir',
      now: DateTime(2026),
      helpLines: const [
        Contact(name: 'Acil Çağrı 112', phone: '112', note: 'Ambulans · itfaiye'),
        Contact(name: 'Ulusal Zehir Danışma Merkezi', phone: '114'),
      ],
    );
    expect(r.helpLines.single.phone, '114');
    expect(
      searchAll(
        query: 'ambulans',
        now: DateTime(2026),
        helpLines: const [Contact(name: 'Acil Çağrı 112', phone: '112', note: 'Ambulans · itfaiye')],
      ).helpLines.single.phone,
      '112',
    );

    final businesses = BusinessesData.fromJson({
      'categories': [
        {'id': 'kafe', 'title': 'Kafe'},
        {'id': 'otel', 'title': 'Konaklama'},
      ],
      'businesses': [
        {'id': 'a', 'name': 'Liman Çay Bahçesi', 'categoryId': 'kafe'},
        {'id': 'b', 'name': 'Deniz Pansiyon', 'categoryId': 'otel', 'summary': 'Denize sıfır'},
      ],
    });
    expect(searchAll(query: 'kafe', now: DateTime(2026), businesses: businesses).businesses.single.id, 'a');
    expect(searchAll(query: 'denize sifir', now: DateTime(2026), businesses: businesses).businesses.single.id, 'b');
  });

  test('son aramalar: başa alır, tekrarı siler, en fazla 8', () {
    var list = <String>[];
    for (final q in ['feribot', 'eczane', 'FERİBOT', 'a']) {
      list = pushRecent(list, q);
    }
    expect(list, ['FERİBOT', 'eczane']);
    for (var i = 0; i < 10; i++) {
      list = pushRecent(list, 'arama $i');
    }
    expect(list, hasLength(8));
    expect(list.first, 'arama 9');
  });

  testWidgets('arama ekranı: öneriye dokun → sonuç; sayfa satırı açılır', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 4000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final tabs = <AppTab>[];
    await tester.pumpWidget(testApp(SearchScreen(onOpenTab: tabs.add)));
    await tester.pumpAndSettle();

    expect(find.text('Öneriler'), findsOneWidget);
    await tester.tap(find.byKey(const Key('search_suggest_rüzgâr')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search_page_wind')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zehir');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search_help_114')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Test Kafe');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search_business_test-kafe')), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(SearchScreen)));
    expect(container.read(recentSearchesProvider).first, 'Test Kafe');
  });
}
