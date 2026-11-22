import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../reminders/departure_reminders.dart' show ReminderResult;
import '../reminders/reminder_scheduler.dart';
import 'events.dart';

/// Kurulu etkinlik hatırlatması (cihazda saklanır).
@immutable
class EventReminder {
  const EventReminder({required this.eventId, required this.id, required this.fireAt});

  factory EventReminder.fromJson(Map<String, dynamic> json) => EventReminder(
        eventId: json['eventId'] as String,
        id: json['id'] as int,
        fireAt: DateTime.parse(json['fireAt'] as String),
      );

  final String eventId;
  final int id;

  /// Erdek saati alanlarıyla.
  final DateTime fireAt;

  Map<String, dynamic> toJson() => {'eventId': eventId, 'id': id, 'fireAt': fireAt.toIso8601String()};
}

final eventRemindersProvider =
    NotifierProvider<EventRemindersNotifier, List<EventReminder>>(EventRemindersNotifier.new);

class EventRemindersNotifier extends Notifier<List<EventReminder>> {
  static const storeKey = 'event_reminders';

  @override
  List<EventReminder> build() {
    final raw = ref.watch(reminderStoreProvider).read(storeKey);
    if (raw == null) return const [];
    final now = ref.watch(clockProvider)();
    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          EventReminder.fromJson(item as Map<String, dynamic>),
      ].where((r) => r.fireAt.isAfter(now)).toList();
    } catch (_) {
      return const [];
    }
  }

  bool isSet(String eventId) => state.any((r) => r.eventId == eventId);

  /// Kuruluysa kaldırır; değilse [CityEvent.reminderAt] anına kurar.
  Future<ReminderResult> toggle(CityEvent event, {required String title, required String body}) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    final existing = state.where((r) => r.eventId == event.id).firstOrNull;
    if (existing != null) {
      await scheduler.cancel(existing.id);
      await _save([for (final r in state) if (r.id != existing.id) r]);
      return ReminderResult.removed;
    }
    final now = ref.read(clockProvider)();
    if (!event.reminderAt.isAfter(now)) return ReminderResult.tooLate;
    if (!await scheduler.requestPermission()) return ReminderResult.denied;

    final reminder = EventReminder(eventId: event.id, id: _idFor(event.id), fireAt: event.reminderAt);
    await scheduler.schedule(id: reminder.id, erdekAt: reminder.fireAt, title: title, body: body);
    await _save([...state.where((r) => r.fireAt.isAfter(now)), reminder]);
    return ReminderResult.added;
  }

  /// Etkinlik kimliğinden sabit bildirim kimliği (çakışırsa bir sonraki).
  int _idFor(String eventId) {
    const range = NotificationIds.eventEnd - NotificationIds.eventBase;
    var hash = 0;
    for (final c in eventId.codeUnits) {
      hash = (hash * 31 + c) % range;
    }
    final used = {for (final r in state) r.id};
    var id = NotificationIds.eventBase + hash;
    while (used.contains(id)) {
      id = id + 1 >= NotificationIds.eventEnd ? NotificationIds.eventBase : id + 1;
    }
    return id;
  }

  Future<void> _save(List<EventReminder> next) async {
    state = next;
    await ref.read(reminderStoreProvider).write(storeKey, jsonEncode([for (final r in next) r.toJson()]));
  }
}
