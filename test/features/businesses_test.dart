import 'package:erdek_rehberi/core/widgets/widgets.dart';
import 'package:erdek_rehberi/features/businesses/domain/business.dart';
import 'package:erdek_rehberi/features/businesses/presentation/business_detail_screen.dart';
import 'package:erdek_rehberi/features/businesses/presentation/businesses_screen.dart';
import 'package:erdek_rehberi/features/settings/presentation/settings_screen.dart';
import 'package:erdek_rehberi/features/social/social_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  group('İşletme verisi', () {
    final data = BusinessesData.fromJson({
      'categories': [
        {'id': 'yeme-icme', 'title': 'Yeme-İçme', 'icon': 'food'},
        {'id': 'bos', 'title': 'Boş Kategori'},
        {'id': 'otel', 'title': 'Konaklama', 'icon': 'bilinmeyen'},
      ],
      'businesses': [
        {'id': 'a', 'name': 'A', 'categoryId': 'yeme-icme', 'summary': '  ', 'description': 'Bir\n\nİki'},
        {'id': 'b', 'name': 'B', 'categoryId': 'otel', 'latitude': 40.39, 'longitude': 27.79},
      ],
    });

    test('boş kategori filtrede görünmez, bilinmeyen ikon "other"', () {
      expect(data.usedCategories.map((c) => c.id), ['yeme-icme', 'otel']);
      expect(data.categories[1].icon, BusinessIcon.other);
      expect(data.categories[2].icon, BusinessIcon.other);
      expect(data.filter(categoryId: 'otel').map((b) => b.id), ['b']);
      expect(data.countIn('yeme-icme'), 1);
    });

    test('boş metin yok sayılır, paragraflar ayrılır', () {
      expect(data.businesses[0].summary, isNull);
      expect(data.businesses[0].paragraphs, ['Bir', 'İki']);
      expect(data.businesses[1].hasLocation, isTrue);
    });

    test('WhatsApp adresi', () {
      expect(whatsappUrl('+902661234567'), 'https://wa.me/902661234567');
    });
  });

  test('sosyal medya: yalnızca https adresleri', () {
    final links = SocialLinks.fromJson({
      'instagram': 'https://instagram.com/erdek',
      'facebook': 'http://facebook.com/erdek',
      'x': '',
    });
    expect(links.instagram, 'https://instagram.com/erdek');
    expect(links.facebook, isNull);
    expect(links.x, isNull);
    expect(const SocialLinks().isEmpty, isTrue);
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view
      ..physicalSize = const Size(1170, 6000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(screen));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets('işletmeler: liste ve kategori filtresi', (tester) async {
    await pump(tester, const BusinessesScreen());

    expect(find.text('İşletmeler'), findsOneWidget);
    expect(find.text('Test Lokantası'), findsOneWidget);
    expect(find.text('Test Oteli'), findsOneWidget);
    expect(find.text('Test Kafe'), findsOneWidget);

    // Haplar yatay kayar; ekranda görünen ilk kategori seçilir.
    await tester.tap(find.text('Yeme-İçme (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Test Lokantası'), findsOneWidget);
    expect(find.text('Test Oteli'), findsNothing);
    expect(find.text('Test Kafe'), findsNothing);
  });

  testWidgets('işletme ayrıntısı: saatler ve iletişim', (tester) async {
    await pump(tester, const BusinessesScreen());

    await tester.tap(find.text('Test Lokantası'));
    await tester.pumpAndSettle();

    expect(find.text('Çalışma saatleri'), findsOneWidget);
    expect(find.text('09:00–22:00'), findsOneWidget);
    expect(find.byKey(const Key('business_call')), findsOneWidget);
    expect(find.text('Yol tarifi'), findsOneWidget);

    await tester.tap(find.byKey(PageHeader.backKey));
    await tester.pumpAndSettle();
    expect(find.text('Test Kafe'), findsOneWidget);
  });

  testWidgets('ayarlar: girilen sosyal medya hesapları görünür', (tester) async {
    await pump(tester, const SettingsScreen());

    expect(find.text('Bizi takip edin'), findsOneWidget);
    expect(find.byKey(const Key('social_instagram')), findsOneWidget);
    expect(find.byKey(const Key('social_x')), findsOneWidget);
    expect(find.byKey(const Key('social_facebook')), findsNothing);
  });
}
