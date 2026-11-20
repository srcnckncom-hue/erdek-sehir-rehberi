import '../../l10n/app_localizations.dart';
import '../time/calendar_date.dart';

/// Türkçe tarih metinleri ("21 Kasım", "Cumartesi, 21 Kasım").
/// intl tarih verisine bağımlı olmamak için ay/gün adları arb'den gelir.
abstract final class DateTexts {
  static String dayMonth(AppLocalizations l10n, CalendarDate date) =>
      l10n.dayMonth(date.day, l10n.monthName('${date.month}'));

  static String weekdayDayMonth(AppLocalizations l10n, CalendarDate date) =>
      l10n.weekdayDayMonth(
        l10n.weekdayName('${date.weekday}'),
        date.day,
        l10n.monthName('${date.month}'),
      );
}
