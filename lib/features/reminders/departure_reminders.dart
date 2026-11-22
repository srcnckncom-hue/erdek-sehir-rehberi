import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/clock_time.dart';
import 'reminder_scheduler.dart';

/// Bir seferin kalkışından önce gelen tek seferlik bildirim.
@immutable
class DepartureReminder {
  const DepartureReminder({
    required this.id,
    required this.routeId,
    required this.date,
    required this.time,
  });

  factory DepartureReminder.fromJson(Map<String, dynamic> json) => DepartureReminder(
        id: json['id'] as int,
        routeId: json['routeId'] as String,
        date: CalendarDate.parse(json['date'] as String),
        time: ClockTime.parse(json['time'] as String),
      );

  /// Kaç dakika önce hatırlatılır.
  static const minutesBefore = 30;

  final int id;
  final String routeId;
  final CalendarDate date;
  final ClockTime time;

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeId': routeId,
        'date': date.toString(),
        'time': time.toString(),
      };

  bool matches(String route, CalendarDate day, ClockTime at) =>
      routeId == route && date == day && time == at;

  /// Kalkış anı (Erdek saati alanlarıyla).
  DateTime get departureAt => DateTime(date.year, date.month, date.day, time.hour, time.minute);

  DateTime get fireAt => departureAt.subtract(const Duration(minutes: minutesBefore));
}

enum ReminderResult { added, removed, tooLate, denied }

final departureRemindersProvider =
    NotifierProvider<DepartureRemindersNotifier, List<DepartureReminder>>(DepartureRemindersNotifier.new);

class DepartureRemindersNotifier extends Notifier<List<DepartureReminder>> {
  static const storeKey = 'departure_reminders';

  @override
  List<DepartureReminder> build() {
    final raw = ref.watch(reminderStoreProvider).read(storeKey);
    if (raw == null) return const [];
    final now = ref.watch(clockProvider)();
    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          DepartureReminder.fromJson(item as Map<String, dynamic>),
      ].where((r) => r.departureAt.isAfter(now)).toList();
    } catch (_) {
      return const [];
    }
  }

  bool isSet(String routeId, CalendarDate date, ClockTime time) =>
      state.any((r) => r.matches(routeId, date, time));

  /// Kuruluysa kaldırır, değilse kalkıştan 30 dk önceye kurar.
  /// [title] / [body]: bildirim metinleri (ekrandaki dilde).
  Future<ReminderResult> toggle({
    required String routeId,
    required CalendarDate date,
    required ClockTime time,
    required String title,
    required String body,
  }) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    final existing = state.where((r) => r.matches(routeId, date, time)).firstOrNull;
    if (existing != null) {
      await scheduler.cancel(existing.id);
      await _save([for (final r in state) if (r.id != existing.id) r]);
      return ReminderResult.removed;
    }

    final now = ref.read(clockProvider)();
    final candidate = DepartureReminder(id: _nextId(), routeId: routeId, date: date, time: time);
    if (!candidate.fireAt.isAfter(now)) return ReminderResult.tooLate;
    if (!await scheduler.requestPermission()) return ReminderResult.denied;

    await scheduler.schedule(id: candidate.id, erdekAt: candidate.fireAt, title: title, body: body);
    await _save([...state.where((r) => r.departureAt.isAfter(now)), candidate]);
    return ReminderResult.added;
  }

  int _nextId() {
    final used = {for (final r in state) r.id};
    var id = NotificationIds.departureBase +
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) %
            (NotificationIds.departureEnd - NotificationIds.departureBase);
    while (used.contains(id)) {
      id = id + 1 >= NotificationIds.departureEnd ? NotificationIds.departureBase : id + 1;
    }
    return id;
  }

  Future<void> _save(List<DepartureReminder> next) async {
    state = next;
    await ref.read(reminderStoreProvider).write(
          storeKey,
          jsonEncode([for (final r in next) r.toJson()]),
        );
  }
}
