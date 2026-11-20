import 'package:flutter/foundation.dart';

/// Gün içindeki saat (`HH:mm`). Material'in TimeOfDay'ine bağımlı olmamak
/// için domain katmanında bu kullanılır.
@immutable
class ClockTime implements Comparable<ClockTime> {
  const ClockTime(this.hour, this.minute)
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);

  factory ClockTime.parse(String value) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    if (match == null) {
      throw FormatException('Geçersiz saat (HH:mm bekleniyor)', value);
    }
    return ClockTime(int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  @override
  int compareTo(ClockTime other) => minutesOfDay - other.minutesOfDay;

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
