import 'package:erdek_rehberi/core/time/calendar_date.dart';
import 'package:erdek_rehberi/features/home/presentation/home_texts.dart';
import 'package:erdek_rehberi/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  test('selamlama saate göre', () {
    expect(HomeTexts.greeting(l10n, 6), 'Günaydın, Erdek');
    expect(HomeTexts.greeting(l10n, 13), 'İyi günler, Erdek');
    expect(HomeTexts.greeting(l10n, 18), 'İyi akşamlar, Erdek');
    expect(HomeTexts.greeting(l10n, 23), 'İyi geceler, Erdek');
    expect(HomeTexts.greeting(l10n, 3), 'İyi geceler, Erdek');
  });

  test('kalan süre yukarı yuvarlanır', () {
    expect(HomeTexts.remaining(l10n, const Duration(minutes: 55)), '55 dk kaldı');
    expect(HomeTexts.remaining(l10n, const Duration(seconds: 30)), '1 dk kaldı');
    expect(HomeTexts.remaining(l10n, const Duration(hours: 2, minutes: 14, seconds: 1)), '2 sa 15 dk kaldı');
  });

  test('göreli gün', () {
    const today = CalendarDate(2026, 11, 21);
    expect(HomeTexts.relativeDay(l10n, today, today), 'Bugün');
    expect(HomeTexts.relativeDay(l10n, today.addDays(1), today), 'Yarın');
    expect(HomeTexts.relativeDay(l10n, today.addDays(3), today), '24.11');
  });

  test('ICU seçimleri', () {
    expect(l10n.weekdayName('6'), 'Cumartesi');
    expect(l10n.weekdayName('7'), 'Pazar');
    expect(l10n.prayerName('ikindi'), 'İkindi');
    expect(l10n.statusOffline('10:42'), 'Çevrimdışı · 10:42');
  });
}
