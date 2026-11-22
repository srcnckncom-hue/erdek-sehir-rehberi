import 'package:erdek_rehberi/app/providers.dart';
import 'package:erdek_rehberi/core/system/system_bridge.dart';
import 'package:erdek_rehberi/core/time/calendar_date.dart';
import 'package:erdek_rehberi/features/events/event_reminders.dart';
import 'package:erdek_rehberi/features/events/events.dart';
import 'package:erdek_rehberi/features/events/events_screen.dart';
import 'package:erdek_rehberi/features/reminders/departure_reminders.dart';
import 'package:erdek_rehberi/features/reminders/reminder_scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

CityEvent _event(Map<String, dynamic> json) => CityEvent.fromJson({'id': 'e', 'title': 'E', ...json});

void main() {
  group('Etkinlik zamanı', () {
    test('saatli tek gün: bitiş saati yoksa +2 saat; hatırlatma 2 saat önce', () {
      final e = _event({'category': 'konser', 'date': '2026-11-21', 'startTime': '20:30'});
      expect(e.startsAt, DateTime(2026, 11, 21, 20, 30));
      expect(e.endsAt, DateTime(2026, 11, 21, 22, 30));
      expect(e.reminderAt, DateTime(2026, 11, 21, 18, 30));
      expect(e.isAllDay, isFalse);
    });

    test('gece yarısını geçen etkinlik ertesi gün biter', () {
      final e = _event({'category': 'konser', 'date': '2026-11-21', 'startTime': '22:00', 'endTime': '02:00'});
      expect(e.endsAt, DateTime(2026, 11, 22, 2));
    });

    test('çok günlü, saatsiz: son günün sonunda biter; sürerken bugün altında listelenir', () {
      final e = _event({'category': 'festival', 'date': '2026-11-20', 'endDate': '2026-11-23'});
      expect(e.isMultiDay, isTrue);
      expect(e.endsAt, DateTime(2026, 11, 24));
      expect(e.reminderAt, DateTime(2026, 11, 20, 9));
      expect(e.isOnAt(DateTime(2026, 11, 22, 12)), isTrue);
      expect(e.listDay(const CalendarDate(2026, 11, 22)), const CalendarDate(2026, 11, 22));
      expect(e.listDay(const CalendarDate(2026, 11, 18)), const CalendarDate(2026, 11, 20));
    });

    test('bilinmeyen tür → diğer; https olmayan bağlantı atılır', () {
      final e = _event({'category': 'yok', 'date': '2026-11-21', 'link': 'http://x.com'});
      expect(e.category, EventCategory.other);
      expect(e.link, isNull);
    });

    test('yaklaşanlar: bitenler çıkar, başlangıca göre sıralı', () {
      final data = EventsData.fromJson({
        'events': [
          {'id': 'b', 'title': 'B', 'category': 'spor', 'date': '2026-11-28', 'startTime': '10:00'},
          {'id': 'gecmis', 'title': 'G', 'category': 'spor', 'date': '2026-11-10'},
          {'id': 'a', 'title': 'A', 'category': 'konser', 'date': '2026-11-21', 'startTime': '20:30'},
        ],
      });
      final up = data.upcoming(DateTime(2026, 11, 21, 18));
      expect(up.map((e) => e.id), ['a', 'b']);
      expect(data.categoriesIn(up), [EventCategory.concert, EventCategory.sport]);
    });
  });

  test('hatırlatma: kur → bildirim, tekrar → kaldır; geç kalınca kurulmaz', () async {
    final scheduler = NoopReminderScheduler();
    final c = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 11, 21, 18)),
      reminderSchedulerProvider.overrideWithValue(scheduler),
      reminderStoreProvider.overrideWithValue(MemoryReminderStore()),
    ]);
    addTearDown(c.dispose);
    final notifier = c.read(eventRemindersProvider.notifier);
    final concert = _event({'id': 'konser', 'category': 'konser', 'date': '2026-11-21', 'startTime': '20:30'});

    expect(await notifier.toggle(concert, title: 't', body: 'b'), ReminderResult.added);
    final (at, _, _) = scheduler.scheduled.values.single;
    expect(at, DateTime(2026, 11, 21, 18, 30));
    final id = scheduler.scheduled.keys.single;
    expect(id, inInclusiveRange(NotificationIds.eventBase, NotificationIds.eventEnd - 1));
    expect(await notifier.toggle(concert, title: 't', body: 'b'), ReminderResult.removed);
    expect(scheduler.scheduled, isEmpty);

    final soon = _event({'id': 'yakin', 'category': 'konser', 'date': '2026-11-21', 'startTime': '19:00'});
    expect(await notifier.toggle(soon, title: 't', body: 'b'), ReminderResult.tooLate);
  });

  testWidgets('etkinlikler sayfası: bugün sürenler, süzgeç, ayrıntı, takvime ekle', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 5000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const EventsScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Test Konseri'), findsOneWidget);
    expect(find.text('Test Festivali'), findsOneWidget);
    expect(find.text('Test Pazarı'), findsOneWidget);
    expect(find.text('Geçmiş Etkinlik'), findsNothing);
    expect(find.text('Şimdi sürüyor'), findsOneWidget); // festival
    expect(find.byKey(const Key('events_filter')), findsOneWidget);

    await tester.tap(find.text('Konser (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Test Pazarı'), findsNothing);
    expect(find.text('Test Konseri'), findsOneWidget);

    await tester.tap(find.textContaining('Tümü'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event_test-konser')));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.text('Açık hava konseri.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('event_calendar')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(EventDetailScreen)));
    final bridge = container.read(systemBridgeProvider) as NoopSystemBridge;
    final entry = bridge.calendar.single;
    expect(entry.title, 'Test Konseri');
    expect(entry.start, DateTime(2026, 11, 21, 20, 30));
    expect(entry.end, DateTime(2026, 11, 21, 23));
    expect(entry.location, 'Cumhuriyet Meydanı, Erdek');
    expect(find.text('Takviminize eklendi.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('event_remind')));
    await tester.pump();
    expect(container.read(eventRemindersProvider).single.eventId, 'test-konser');

    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
