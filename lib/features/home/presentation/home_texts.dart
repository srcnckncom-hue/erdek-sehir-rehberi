import '../../../core/time/calendar_date.dart';
import '../../../l10n/app_localizations.dart';

/// Ana sayfadaki küçük metin hesapları (test edilebilir, saf fonksiyonlar).
abstract final class HomeTexts {
  /// 05–11 Günaydın · 11–17 İyi günler · 17–22 İyi akşamlar · diğer İyi geceler
  static String greeting(AppLocalizations l10n, int hour) {
    if (hour >= 5 && hour < 11) return l10n.greetingMorning;
    if (hour >= 11 && hour < 17) return l10n.greetingDay;
    if (hour >= 17 && hour < 22) return l10n.greetingEvening;
    return l10n.greetingNight;
  }

  static String remaining(AppLocalizations l10n, Duration d) {
    // Kalan dakikayı yukarı yuvarla: 59 sn kala "1 dk kaldı".
    final totalMinutes = (d.inSeconds + 59) ~/ 60;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return hours > 0
        ? l10n.remainingHoursMinutes(hours, minutes)
        : l10n.remainingMinutes(minutes);
  }

  /// "Bugün", "Yarın" veya "24.11"
  static String relativeDay(AppLocalizations l10n, CalendarDate date, CalendarDate today) {
    if (date == today) return l10n.today;
    if (date == today.addDays(1)) return l10n.tomorrow;
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }
}
