import 'package:flutter/foundation.dart';

/// Saat dilimi taşımayan takvim günü (Erdek yerel günü).
///
/// Tarih karşılaştırmaları cihazın saat diliminden etkilenmesin diye
/// DateTime yerine bu sınıf kullanılır.
@immutable
class CalendarDate implements Comparable<CalendarDate> {
  const CalendarDate(this.year, this.month, this.day);

  /// DateTime'ın yalnızca yıl/ay/gün alanlarını alır (anı değil).
  factory CalendarDate.fromDateTime(DateTime value) =>
      CalendarDate(value.year, value.month, value.day);

  /// `yyyy-MM-dd` biçimini okur. Geçersiz gün (ör. 2026-02-30) hata verir.
  factory CalendarDate.parse(String value) {
    final parts = value.split('-');
    if (parts.length != 3) {
      throw FormatException('Geçersiz tarih', value);
    }
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final check = DateTime.utc(year, month, day);
    if (check.year != year || check.month != month || check.day != day) {
      throw FormatException('Geçersiz tarih', value);
    }
    return CalendarDate(year, month, day);
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  CalendarDate addDays(int days) =>
      CalendarDate.fromDateTime(_utc.add(Duration(days: days)));

  /// [other] tarihine kaç gün var (geçmişse negatif).
  int daysUntil(CalendarDate other) => other._utc.difference(_utc).inDays;

  /// 1 = Pazartesi ... 7 = Pazar
  int get weekday => _utc.weekday;

  bool isBefore(CalendarDate other) => compareTo(other) < 0;

  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  @override
  int compareTo(CalendarDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${_two(month)}-${_two(day)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
