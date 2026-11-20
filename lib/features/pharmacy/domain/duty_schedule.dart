import '../../../core/time/calendar_date.dart';

/// Nöbet değişim saati: 08:30.
const dutyChangeoverHour = 8;
const dutyChangeoverMinute = 30;

/// [erdekNow] anında geçerli olan nöbet günü.
///
/// Nöbet sabah 08:30'da değişir: 00:00–08:29 arası bir önceki günün
/// nöbetçisi geçerlidir. [erdekNow] Erdek (Europe/Istanbul) saati olmalı;
/// yalnızca alanları (saat/dakika/gün) kullanılır.
CalendarDate dutyDateFor(DateTime erdekNow) {
  final today = CalendarDate.fromDateTime(erdekNow);
  final minutes = erdekNow.hour * 60 + erdekNow.minute;
  const changeover = dutyChangeoverHour * 60 + dutyChangeoverMinute;
  return minutes < changeover ? today.addDays(-1) : today;
}
