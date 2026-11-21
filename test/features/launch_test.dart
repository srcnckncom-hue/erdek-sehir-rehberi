import 'package:erdek_rehberi/app/app.dart';
import 'package:erdek_rehberi/app/launch/launch_splash.dart';
import 'package:erdek_rehberi/app/launch/onboarding_screen.dart';
import 'package:erdek_rehberi/core/settings/onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  Future<void> openApp(WidgetTester tester, OnboardingStore store) async {
    await tester.pumpWidget(testScope(onboardingStore: store, child: const ErdekApp()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  }

  testWidgets('İlk açılış: logo animasyonu → 3 tanıtım sayfası → Başla → ana sayfa', (
    tester,
  ) async {
    final store = MemoryOnboardingStore();
    await openApp(tester, store);

    // Açılış animasyonu
    expect(find.byType(LaunchSplash), findsOneWidget);
    expect(find.text('Şehrin rehberi, cebinde'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(LaunchSplash), findsNothing);

    // 1. sayfa
    expect(find.text('Nöbetçi eczane ve namaz vakitleri'), findsOneWidget);
    expect(find.byKey(OnboardingScreen.skipKey), findsOneWidget);
    await tester.tap(find.byKey(OnboardingScreen.nextKey));
    await tester.pumpAndSettle();

    // 2. sayfa
    expect(find.text('Feribot ve otobüs saatleri'), findsOneWidget);
    await tester.tap(find.byKey(OnboardingScreen.nextKey));
    await tester.pumpAndSettle();

    // 3. sayfa: bildirim kartı + Başla
    expect(find.text('Rehber, duyurular ve keşfet'), findsOneWidget);
    expect(find.text('Başla'), findsOneWidget);
    expect(find.byType(Switch, skipOffstage: false), findsWidgets);
    await tester.tap(find.byKey(OnboardingScreen.nextKey));
    await tester.pumpAndSettle();

    expect(store.isDone, isTrue);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Hızlı İşlemlerim'), findsOneWidget);
  });

  testWidgets('"Geç" tanıtımı hemen bitirir', (tester) async {
    final store = MemoryOnboardingStore();
    await openApp(tester, store);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(OnboardingScreen.skipKey));
    await tester.pumpAndSettle();

    expect(store.isDone, isTrue);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Hızlı İşlemlerim'), findsOneWidget);
  });

  testWidgets('Sonraki açılışlar: yalnızca logo animasyonu, tanıtım yok', (tester) async {
    await openApp(tester, MemoryOnboardingStore(isDone: true));
    expect(find.byType(LaunchSplash), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byType(LaunchSplash), findsNothing);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Hızlı İşlemlerim'), findsOneWidget);
  });
}
