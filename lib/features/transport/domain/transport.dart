import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock_time.dart';

enum TransportMode {
  ferry('ferry'),
  bus('bus');

  const TransportMode(this.jsonValue);

  final String jsonValue;

  static TransportMode fromJson(String value) =>
      values.firstWhere((m) => m.jsonValue == value);
}

class Departure {
  const Departure({required this.time, required this.weekdays, this.note});

  factory Departure.fromJson(Map<String, dynamic> json) => Departure(
        time: ClockTime.parse(json['time'] as String),
        weekdays: json['days'] == null
            ? allWeekdays
            : (json['days'] as List<dynamic>).cast<int>().toSet(),
        note: json['note'] as String?,
      );

  static const allWeekdays = {1, 2, 3, 4, 5, 6, 7};

  final ClockTime time;

  /// 1 = Pazartesi ... 7 = Pazar
  final Set<int> weekdays;
  final String? note;

  bool runsOn(CalendarDate date) => weekdays.contains(date.weekday);
}

/// Bir tarife dönemi (ör. "Kış tarifesi" 1 Ekim – 31 Mayıs).
class Timetable {
  const Timetable({
    required this.name,
    required this.validFrom,
    required this.validTo,
    required this.departures,
  });

  factory Timetable.fromJson(Map<String, dynamic> json) => Timetable(
        name: json['name'] as String,
        validFrom: CalendarDate.parse(json['validFrom'] as String),
        validTo: CalendarDate.parse(json['validTo'] as String),
        departures: (json['departures'] as List<dynamic>)
            .map((e) => Departure.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String name;
  final CalendarDate validFrom;
  final CalendarDate validTo;
  final List<Departure> departures;

  bool isActiveOn(CalendarDate date) =>
      !date.isBefore(validFrom) && !date.isAfter(validTo);
}

class TransportRoute {
  const TransportRoute({
    required this.id,
    required this.mode,
    required this.title,
    required this.from,
    required this.to,
    required this.timetables,
    this.operatorName,
    this.phone,
    this.note,
  });

  factory TransportRoute.fromJson(Map<String, dynamic> json) => TransportRoute(
        id: json['id'] as String,
        mode: TransportMode.fromJson(json['mode'] as String),
        title: json['title'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        operatorName: json['operator'] as String?,
        phone: json['phone'] as String?,
        note: json['note'] as String?,
        timetables: (json['timetables'] as List<dynamic>)
            .map((e) => Timetable.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final TransportMode mode;
  final String title;
  final String from;
  final String to;
  final String? operatorName;
  final String? phone;
  final String? note;
  final List<Timetable> timetables;

  Timetable? timetableFor(CalendarDate date) =>
      timetables.where((t) => t.isActiveOn(date)).firstOrNull;

  /// [date] günündeki seferler, saate göre sıralı.
  List<Departure> departuresOn(CalendarDate date) {
    final timetable = timetableFor(date);
    if (timetable == null) return const [];
    return timetable.departures.where((d) => d.runsOn(date)).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }
}

class TransportData {
  const TransportData({required this.routes});

  factory TransportData.fromJson(Map<String, dynamic> json) => TransportData(
        routes: (json['routes'] as List<dynamic>)
            .map((e) => TransportRoute.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final List<TransportRoute> routes;

  List<TransportRoute> byMode(TransportMode mode) =>
      routes.where((r) => r.mode == mode).toList();
}

class UpcomingDeparture {
  const UpcomingDeparture({
    required this.route,
    required this.date,
    required this.departure,
  });

  final TransportRoute route;
  final CalendarDate date;
  final Departure departure;
}

/// [erdekNow] anından sonraki ilk [limit] sefer (en fazla [lookaheadDays] gün ileri).
List<UpcomingDeparture> upcomingDepartures(
  TransportRoute route,
  DateTime erdekNow, {
  int limit = 3,
  int lookaheadDays = 7,
}) {
  final today = CalendarDate.fromDateTime(erdekNow);
  final nowMinutes = erdekNow.hour * 60 + erdekNow.minute;
  final result = <UpcomingDeparture>[];

  for (var offset = 0; offset <= lookaheadDays && result.length < limit; offset++) {
    final date = today.addDays(offset);
    for (final departure in route.departuresOn(date)) {
      if (offset == 0 && departure.time.minutesOfDay <= nowMinutes) continue;
      result.add(UpcomingDeparture(route: route, date: date, departure: departure));
      if (result.length == limit) break;
    }
  }
  return result;
}
