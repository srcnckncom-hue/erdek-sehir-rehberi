import 'package:erdek_rehberi/features/push/push_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DeniedPush implements PushService {
  @override
  Future<bool> setAnnouncementsEnabled(bool on) async => !on;
}

void main() {
  test('duyuru bildirimi açılır/kapanır ve kaydedilir', () async {
    final service = NoopPushService();
    final prefs = MemoryPushPrefsStore();
    final container = ProviderContainer(
      overrides: [
        pushServiceProvider.overrideWithValue(service),
        pushPrefsStoreProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(announcementsPushProvider), isFalse);
    expect(await container.read(announcementsPushProvider.notifier).setEnabled(true), isTrue);
    expect(container.read(announcementsPushProvider), isTrue);
    expect(prefs.announcementsEnabled, isTrue);
    await container.read(announcementsPushProvider.notifier).setEnabled(false);
    expect(container.read(announcementsPushProvider), isFalse);
    expect(service.calls, [true, false]);
  });

  test('izin verilmezse kapalı kalır', () async {
    final prefs = MemoryPushPrefsStore();
    final container = ProviderContainer(
      overrides: [
        pushServiceProvider.overrideWithValue(_DeniedPush()),
        pushPrefsStoreProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(announcementsPushProvider.notifier).setEnabled(true), isFalse);
    expect(container.read(announcementsPushProvider), isFalse);
    expect(prefs.announcementsEnabled, isFalse);
  });
}
