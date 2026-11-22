import 'package:erdek_rehberi/features/push/push_service.dart';
import 'package:erdek_rehberi/features/push/push_topics_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

class _DeniedPush implements PushService {
  @override
  Future<bool> setTopic(PushTopic topic, bool on) async => !on;
}

ProviderContainer _container(PushService service, PushPrefsStore prefs) {
  final c = ProviderContainer(
    overrides: [
      pushServiceProvider.overrideWithValue(service),
      pushPrefsStoreProvider.overrideWithValue(prefs),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('konu adları panel ve send-push ile aynı', () {
    expect(PushTopic.values.map((t) => t.topic), ['duyurular', 'kesintiler', 'ulasim', 'etkinlikler']);
    expect(HivePushPrefsStore.keyFor(PushTopic.general), 'push_announcements');
    expect(HivePushPrefsStore.keyFor(PushTopic.outages), 'push_topic_kesintiler');
  });

  test('konu açılır/kapanır ve kaydedilir', () async {
    final service = NoopPushService();
    final prefs = MemoryPushPrefsStore();
    final c = _container(service, prefs);
    final notifier = c.read(pushTopicsProvider.notifier);

    expect(c.read(pushTopicsProvider), isEmpty);
    expect(await notifier.setEnabled(PushTopic.outages, true), isTrue);
    expect(await notifier.setEnabled(PushTopic.events, true), isTrue);
    expect(c.read(pushTopicsProvider), {PushTopic.outages, PushTopic.events});
    await notifier.setEnabled(PushTopic.outages, false);
    expect(c.read(pushTopicsProvider), {PushTopic.events});
    expect(prefs.values[PushTopic.outages], isFalse);
    expect(service.calls.last, (PushTopic.outages, false));
  });

  test('izin verilmezse kapalı kalır', () async {
    final prefs = MemoryPushPrefsStore();
    final c = _container(_DeniedPush(), prefs);
    expect(await c.read(pushTopicsProvider.notifier).setEnabled(PushTopic.general, true), isFalse);
    expect(c.read(pushTopicsProvider), isEmpty);
    expect(prefs.values[PushTopic.general], isFalse);
  });

  test('eski "Önemli duyurular" açıksa yeni konular da açık başlar; açılışta abone olunur', () async {
    final service = NoopPushService();
    final prefs = MemoryPushPrefsStore()..values[PushTopic.general] = true;
    prefs.values[PushTopic.events] = false; // kullanıcı kapatmış → kapalı kalır
    final c = _container(service, prefs);

    expect(c.read(pushTopicsProvider), {PushTopic.general, PushTopic.outages, PushTopic.transport});
    await c.read(pushTopicsProvider.notifier).refresh();
    expect(service.calls.map((e) => e.$1).toSet(), {PushTopic.general, PushTopic.outages, PushTopic.transport});
    expect(prefs.values[PushTopic.outages], isTrue);
  });

  testWidgets('bildirim konuları sayfası: anahtar dokununca açılır', (tester) async {
    await tester.pumpWidget(testApp(const PushTopicsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Su ve elektrik kesintileri'), findsOneWidget);
    await tester.tap(find.byKey(const Key('push_topic_kesintiler')));
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(tester.element(find.byType(PushTopicsScreen)));
    expect(c.read(pushTopicsProvider), {PushTopic.outages});
  });
}
