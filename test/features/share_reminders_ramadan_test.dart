import 'package:erdek_rehberi/app/providers.dart';
import 'package:erdek_rehberi/core/time/calendar_date.dart';
import 'package:erdek_rehberi/core/time/clock_time.dart';
import 'package:erdek_rehberi/features/pharmacy/domain/pharmacy.dart';
import 'package:erdek_rehberi/features/pharmacy/presentation/pharmacy_screen.dart';
import 'package:erdek_rehberi/features/prayer/domain/prayer_times.dart';
import 'package:erdek_rehberi/features/ramadan/ramadan.dart';
import 'package:erdek_rehberi/features/ramadan/ramadan_screen.dart';
import 'package:erdek_rehberi/features/reminders/departure_reminders.dart';
import 'package:erdek_rehberi/features/reminders/reminder_scheduler.dart';
import 'package:erdek_rehberi/features/share/share_actions.dart';
import 'package:erdek_rehberi/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

PrayerTimesData _prayer(List<String> dates) => PrayerTimesData.fromJson({
      'location': 'Erdek',
      'days': [
        for (final date in dates)
          {
            'date': date,
            'imsak': '06:20',
            'gunes': '07:45',
            'ogle': '13:00',
            'ikindi': '15:40',
            'aksam': '18:10',
            'yatsi': '19:35',
          },
      ],
    });

void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  group('Paylaşım metinleri', () {
    test('eczane: ad, adres, telefon, not ve harita', () {
      const pharmacy = Pharmacy(
        id: 'e1',
        name: 'Deniz Eczanesi',
        address: 'Çarşı Cd. No:1, Erdek',
        phone: '+902668350000',
        latitude: 40.39,
        longitude: 27.79,
      );
      final text = ShareTexts.pharmacy(
        l10n,
        pharmacy: pharmacy,
        dayLabel: 'Cumartesi, 21 Kasım',
        note: 'Gece 22:00\'a kadar nöbetçidir.',
      );
      expect(text, contains('Cumartesi, 21 Kasım nöbetçi eczane: Deniz Eczanesi'));
      expect(text, contains('Tel: 0266 835 00 00'));
      expect(text, contains('Gece 22:00'));
      expect(text, contains('Harita: https://maps.apple.com/?q=Deniz'));
      expect(text, contains('40.39'));
      expect(text, endsWith('— Erdek Şehir Rehberi'));
    });

    test('sefer: hat, gün, saat, varış', () {
      final text = ShareTexts.departure(
        l10n,
        routeTitle: 'Erdek → Avşa',
        dayLabel: 'Yarın',
        time: '09:00',
        arrival: '10:30',
      );
      expect(text.split('\n').first, 'Erdek → Avşa');
      expect(text, contains('Yarın, saat 09:00'));
      expect(text, contains('10:30'));
    });
  });

  group('Sefer hatırlatıcısı', () {
    ProviderContainer container(DateTime now, NoopReminderScheduler scheduler) {
      final c = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => now),
          reminderSchedulerProvider.overrideWithValue(scheduler),
          reminderStoreProvider.overrideWithValue(MemoryReminderStore()),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('kur → 30 dk önceye bildirim; tekrar dokun → kaldır', () async {
      final scheduler = NoopReminderScheduler();
      final c = container(DateTime(2026, 11, 21, 18, 5), scheduler);
      final notifier = c.read(departureRemindersProvider.notifier);

      final added = await notifier.toggle(
        routeId: 'feribot',
        date: const CalendarDate(2026, 11, 22),
        time: const ClockTime(9, 0),
        title: 'Erdek → Avşa',
        body: '09:00 seferine 30 dakika kaldı.',
      );
      expect(added, ReminderResult.added);
      expect(c.read(departureRemindersProvider), hasLength(1));
      final (at, title, _) = scheduler.scheduled.values.single;
      expect(at, DateTime(2026, 11, 22, 8, 30));
      expect(title, 'Erdek → Avşa');
      final id = scheduler.scheduled.keys.single;
      expect(id, greaterThanOrEqualTo(NotificationIds.departureBase));
      expect(id, lessThan(NotificationIds.departureEnd));

      final removed = await notifier.toggle(
        routeId: 'feribot',
        date: const CalendarDate(2026, 11, 22),
        time: const ClockTime(9, 0),
        title: '',
        body: '',
      );
      expect(removed, ReminderResult.removed);
      expect(scheduler.scheduled, isEmpty);
      expect(c.read(departureRemindersProvider), isEmpty);
    });

    test('kalkışa 30 dakikadan az kaldıysa kurulmaz', () async {
      final scheduler = NoopReminderScheduler();
      final c = container(DateTime(2026, 11, 21, 18, 45), scheduler);
      final result = await c.read(departureRemindersProvider.notifier).toggle(
            routeId: 'otobus',
            date: const CalendarDate(2026, 11, 21),
            time: const ClockTime(19, 0),
            title: '',
            body: '',
          );
      expect(result, ReminderResult.tooLate);
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('Ramazan', () {
    final period = ramadanPeriods.single;

    test('2027 tarihleri (Diyanet)', () {
      expect(period.firstFast, const CalendarDate(2027, 2, 8));
      expect(period.dayCount, 29);
      expect(period.dayNumber(const CalendarDate(2027, 2, 8)), 1);
      expect(period.dayNumber(const CalendarDate(2027, 3, 8)), 29);
      expect(period.dayNumber(const CalendarDate(2027, 3, 9)), isNull);
      expect(currentOrNextRamadan(const CalendarDate(2026, 11, 21)), same(period));
      expect(currentOrNextRamadan(const CalendarDate(2027, 3, 9)), isNull);
    });

    test('giriş 90 gün kala görünür', () {
      expect(showRamadanEntry(const CalendarDate(2026, 11, 9)), isFalse);
      expect(showRamadanEntry(const CalendarDate(2026, 11, 10)), isTrue);
      expect(showRamadanEntry(const CalendarDate(2027, 3, 8)), isTrue);
    });

    test('geri sayım: önce sahur, sonra iftar, sonra yarının sahuru', () {
      final data = _prayer(['2027-02-10', '2027-02-11']);
      final a = ramadanCountdown(period, data, DateTime(2027, 2, 10, 4))!;
      expect((a.target, a.time.toString()), (RamadanTarget.sahur, '06:20'));
      final b = ramadanCountdown(period, data, DateTime(2027, 2, 10, 12))!;
      expect((b.target, b.time.toString()), (RamadanTarget.iftar, '18:10'));
      expect(b.remaining, const Duration(hours: 6, minutes: 10));
      final c = ramadanCountdown(period, data, DateTime(2027, 2, 10, 20))!;
      expect((c.target, c.date), (RamadanTarget.sahur, const CalendarDate(2027, 2, 11)));
    });

    test('iftar bildirimleri: yalnızca Ramazan günleri, en fazla 7', () async {
      final scheduler = NoopReminderScheduler();
      final data = _prayer([for (var d = 1; d <= 28; d++) '2027-02-${d.toString().padLeft(2, '0')}']);
      await syncIftarNotifications(
        scheduler: scheduler,
        data: data,
        enabled: true,
        erdekNow: DateTime(2027, 2, 7, 12),
        title: 'İftar vakti',
        body: (time) => 'Akşam ezanı $time',
      );
      expect(scheduler.scheduled, hasLength(maxIftarNotifications));
      final first = scheduler.scheduled.values.map((v) => v.$1).reduce((a, b) => a.isBefore(b) ? a : b);
      expect(first, DateTime(2027, 2, 8, 18, 10));

      await syncIftarNotifications(
        scheduler: scheduler,
        data: data,
        enabled: false,
        erdekNow: DateTime(2027, 2, 7, 12),
        title: '',
        body: (time) => time,
      );
      expect(scheduler.scheduled, isEmpty);
    });

    testWidgets('Ramazan sayfası: kalan gün ve önemli günler', (tester) async {
      tester.view
        ..physicalSize = const Size(1170, 5000)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testApp(const RamadanScreen()));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();

      // testNow = 21.11.2026 → 8 Şubat 2027'ye 79 gün
      expect(find.text("Ramazan'a 79 gün kaldı"), findsOneWidget);
      expect(find.text('Kadir Gecesi'), findsOneWidget);
      expect(find.byKey(const Key('ramadan_iftar_switch')), findsOneWidget);
    });
  });

  testWidgets('eczane kartında WhatsApp paylaş düğmesi', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 4500)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const PharmacyScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pharmacy_share')), findsWidgets);
  });
}
