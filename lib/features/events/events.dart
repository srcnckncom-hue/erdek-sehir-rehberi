import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/data_result.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/clock_time.dart';
import '../explore/domain/explore.dart';

/// Etkinlik türü (panelde seçilir). Bilinmeyen değer → [other].
enum EventCategory {
  concert('konser'),
  festival('festival'),
  culture('kultur'),
  sport('spor'),
  kids('cocuk'),
  market('pazar'),
  other('diger');

  const EventCategory(this.jsonValue);

  final String jsonValue;

  static EventCategory fromJson(String? v) =>
      EventCategory.values.where((c) => c.jsonValue == v).firstOrNull ?? EventCategory.other;
}

/// Panelden eklenen bir etkinlik (data/events.json). Saatler Erdek saatidir.
@immutable
class CityEvent {
  const CityEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.endDate,
    this.startTime,
    this.endTime,
    this.place,
    this.latitude,
    this.longitude,
    this.summary,
    this.paragraphs = const [],
    this.organizer,
    this.link,
    this.photos = const [],
  });

  factory CityEvent.fromJson(Map<String, dynamic> json) {
    final end = _text(json['endDate']);
    final start = _text(json['startTime']);
    final finish = _text(json['endTime']);
    return CityEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      category: EventCategory.fromJson(json['category'] as String?),
      date: CalendarDate.parse(json['date'] as String),
      endDate: end == null ? null : CalendarDate.parse(end),
      startTime: start == null ? null : ClockTime.parse(start),
      endTime: finish == null ? null : ClockTime.parse(finish),
      place: _text(json['place']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      summary: _text(json['summary']),
      paragraphs: [
        for (final p in json['paragraphs'] as List<dynamic>? ?? const []) ?_text(p),
      ],
      organizer: _text(json['organizer']),
      link: switch (_text(json['link'])) {
        final l? when l.startsWith('https://') => l,
        _ => null,
      },
      photos: [
        for (final p in json['photos'] as List<dynamic>? ?? const [])
          PlacePhoto.fromJson(p as Map<String, dynamic>),
      ],
    );
  }

  final String id;
  final String title;
  final EventCategory category;

  /// İlk gün; [endDate] varsa çok günlü (festival vb.).
  final CalendarDate date;
  final CalendarDate? endDate;

  /// Yoksa "tüm gün".
  final ClockTime? startTime;
  final ClockTime? endTime;
  final String? place;
  final double? latitude;
  final double? longitude;
  final String? summary;
  final List<String> paragraphs;
  final String? organizer;

  /// Yalnızca https:// (bilet / ayrıntı sayfası).
  final String? link;
  final List<PlacePhoto> photos;

  CalendarDate get lastDay => endDate ?? date;
  bool get isMultiDay => endDate != null && endDate != date;
  bool get isAllDay => startTime == null;

  /// Başlangıç anı (Erdek saati alanlarıyla). Saat yoksa 00:00.
  DateTime get startsAt => DateTime(date.year, date.month, date.day, startTime?.hour ?? 0, startTime?.minute ?? 0);

  /// Bitiş anı: bitiş saati varsa o; tek günlükte saat varsa +2 saat; yoksa son günün sonu.
  DateTime get endsAt {
    final last = lastDay;
    if (endTime case final t?) {
      final end = DateTime(last.year, last.month, last.day, t.hour, t.minute);
      // Gece yarısını geçen etkinlik (22:00–02:00).
      return end.isAfter(startsAt) ? end : end.add(const Duration(days: 1));
    }
    if (startTime != null && !isMultiDay) return startsAt.add(const Duration(hours: 2));
    return DateTime(last.year, last.month, last.day).add(const Duration(days: 1));
  }

  bool isOverAt(DateTime now) => !now.isBefore(endsAt);
  bool isOnAt(DateTime now) => !now.isBefore(startsAt) && now.isBefore(endsAt);

  /// Hatırlatma: başlamadan 2 saat önce; saat yoksa ilk gün 09:00.
  DateTime get reminderAt => isAllDay
      ? DateTime(date.year, date.month, date.day, 9)
      : startsAt.subtract(const Duration(hours: 2));

  /// Listede hangi günün altında görünür: sürüyorsa bugün, değilse ilk gün.
  CalendarDate listDay(CalendarDate today) => isMultiDay && !today.isBefore(date) ? today : date;
}

class EventsData {
  const EventsData({required this.events});

  factory EventsData.fromJson(Map<String, dynamic> json) => EventsData(
        events: [
          for (final e in json['events'] as List<dynamic>? ?? const [])
            CityEvent.fromJson(e as Map<String, dynamic>),
        ],
      );

  final List<CityEvent> events;

  /// Bitmemiş etkinlikler, başlangıca göre (sürenler önce).
  List<CityEvent> upcoming(DateTime now) =>
      [for (final e in events) if (!e.isOverAt(now)) e]..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  /// Kullanılan türler (filtre için, enum sırasıyla).
  List<EventCategory> categoriesIn(List<CityEvent> list) {
    final used = {for (final e in list) e.category};
    return [for (final c in EventCategory.values) if (used.contains(c)) c];
  }
}

String? _text(Object? v) {
  final t = (v as String?)?.trim();
  return t == null || t.isEmpty ? null : t;
}

final eventsDataProvider = StreamProvider<DataResult<EventsData>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('events.json', EventsData.fromJson),
);

/// Ana sayfa / arama: bitmemiş etkinlikler.
final upcomingEventsProvider = Provider<List<CityEvent>>((ref) {
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
  return ref.watch(eventsDataProvider).value?.data.upcoming(now) ?? const [];
});
