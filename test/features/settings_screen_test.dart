import 'package:erdek_rehberi/core/settings/usage_store.dart';
import 'package:erdek_rehberi/core/system/system_bridge.dart';
import 'package:erdek_rehberi/features/prayer/presentation/notification_settings_sheet.dart';
import 'package:erdek_rehberi/features/settings/presentation/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erdek_rehberi/app/shell/app_drawer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  testWidgets('Ayarlar: bölümler, bağlantılar ve paylaş', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 6000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Ayarlar ve Hakkında'), findsOneWidget);
    expect(find.text('Görünüm'), findsOneWidget);
    expect(find.text('Vakit bildirimleri'), findsOneWidget);
    expect(find.text('Kapalı'), findsOneWidget);
    expect(find.text('Hata bildir'), findsOneWidget);
    expect(find.text('hello@erdeksehirrehberi.com.tr'), findsOneWidget);
    expect(find.text('Gizlilik Politikası'), findsOneWidget);
    expect(find.text('Kullanım Koşulları'), findsOneWidget);
    expect(find.textContaining('resmi kurumla bağlantısı yoktur'), findsOneWidget);

    await tester.tap(find.byKey(SettingsScreen.shareKey));
    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));
    final bridge = container.read(systemBridgeProvider) as NoopSystemBridge;
    expect(bridge.shared.single, contains('Erdek Şehir Rehberi'));
  });

  testWidgets('Vakit bildirimleri sayfasında Kapat düğmesi var ve kapatır', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 6000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp(const SettingsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vakit bildirimleri'));
    await tester.pumpAndSettle();
    expect(find.byKey(notificationSheetCloseKey), findsOneWidget);

    await tester.tap(find.byKey(notificationSheetCloseKey));
    await tester.pumpAndSettle();
    expect(find.byKey(notificationSheetCloseKey), findsNothing);
  });

  testWidgets('Dil seçimi yan menüde: Türkçe ve English seçenekleri', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 6000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Dil'), findsNothing);

    await tester.pumpWidget(testApp(const AppDrawer()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('drawer_language')), findsOneWidget);
    expect(find.text('Dil'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  group('Puanlama penceresi zamanı', () {
    final now = DateTime(2026, 12, 1, 12);

    test('ilk açılışlarda sorulmaz', () {
      final store = MemoryUsageStore(launchCount: 2, firstLaunch: now.subtract(const Duration(days: 10)));
      expect(shouldAskForReview(store, now), isFalse);
    });

    test('5. açılış ama 3 gün dolmadı → sorulmaz', () {
      final store = MemoryUsageStore(launchCount: 5, firstLaunch: now.subtract(const Duration(days: 1)));
      expect(shouldAskForReview(store, now), isFalse);
    });

    test('5+ açılış ve 3+ gün → bir kez sorulur', () async {
      final store = MemoryUsageStore(launchCount: 6, firstLaunch: now.subtract(const Duration(days: 4)));
      expect(shouldAskForReview(store, now), isTrue);
      await store.markReviewAsked();
      expect(shouldAskForReview(store, now), isFalse);
    });

    test('açılış sayacı', () async {
      final store = MemoryUsageStore();
      await store.recordLaunch(now);
      await store.recordLaunch(now);
      expect(store.launchCount, 2);
      expect(store.firstLaunch, now);
    });
  });
}
