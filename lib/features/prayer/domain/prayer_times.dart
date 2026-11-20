import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock_time.dart';

/// Diyanet'in günlük vakitleri, gün içindeki sırasıyla.
enum PrayerName {
  imsak('imsak'),
  gunes('gunes'),
  ogle('ogle'),
  ikindi('ikindi'),
  aksam('aksam'),
  yatsi('yatsi');

  const PrayerName(this.jsonKey);

  final String jsonKey;
}

class PrayerDay {
  const PrayerDay({required this.date, required this.times, this.hijri});

  factory PrayerDay.fromJson(Map<String, dynamic> json) => PrayerDay(
        date: CalendarDate.parse(json['date'] as String),
        times: {
          for (final name in PrayerName.values)
            name: ClockTime.parse(json[name.jsonKey] as String),
        },
        hijri: json['hijri'] as String?,
      );

  final CalendarDate date;
  final Map<PrayerName, ClockTime> times;

  /// Hicri tarih, ör. "12 Cemaziyelahir 1448" (kaynak verirse).
  final String? hijri;

  ClockTime timeOf(PrayerName name) => times[name]!;
}

class PrayerTimesData {
  const PrayerTimesData({required this.locationName, required this.days});

  factory PrayerTimesData.fromJson(Map<String, dynamic> json) =>
      PrayerTimesData(
        locationName: json['location'] as String,
        days: (json['days'] as List<dynamic>)
            .map((e) => PrayerDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String locationName;
  final List<PrayerDay> days;

  PrayerDay? dayFor(CalendarDate date) =>
      days.where((d) => d.date == date).firstOrNull;

  /// İmsakiye ekranı için bir ayın günleri.
  List<PrayerDay> month(int year, int month) => days
      .where((d) => d.date.year == year && d.date.month == month)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}

class NextPrayer {
  const NextPrayer({
    required this.name,
    required this.date,
    required this.time,
    required this.remaining,
  });

  final PrayerName name;
  final CalendarDate date;
  final ClockTime time;

  /// Geri sayım için kalan süre.
  final Duration remaining;
}

/// [erdekNow] anından sonraki ilk vakit. Bugün kalmadıysa yarının imsakı.
/// Veride bugün/yarın yoksa null.
NextPrayer? findNextPrayer(PrayerTimesData data, DateTime erdekNow) {
  final today = CalendarDate.fromDateTime(erdekNow);
  final nowSeconds =
      erdekNow.hour * 3600 + erdekNow.minute * 60 + erdekNow.second;

  for (var offset = 0; offset <= 1; offset++) {
    final day = data.dayFor(today.addDays(offset));
    if (day == null) continue;
    for (final name in PrayerName.values) {
      final time = day.timeOf(name);
      final targetSeconds = offset * 86400 + time.minutesOfDay * 60;
      if (targetSeconds > nowSeconds) {
        return NextPrayer(
          name: name,
          date: day.date,
          time: time,
          remaining: Duration(seconds: targetSeconds - nowSeconds),
        );
      }
    }
  }
  return null;
}
