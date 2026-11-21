import 'package:erdek_rehberi/app/providers.dart';
import 'package:erdek_rehberi/core/settings/locale_store.dart';
import 'package:erdek_rehberi/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('varsayılan dil Türkçe; İngilizce seçilince kaydedilir', () async {
    final store = MemoryLocaleStore();
    final container = ProviderContainer(overrides: [localeStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);

    expect(container.read(localeProvider), const Locale('tr'));
    await container.read(localeProvider.notifier).setLocale(const Locale('en'));
    expect(container.read(localeProvider), const Locale('en'));
    expect(store.locale, const Locale('en'));
  });

  test('İngilizce metinler yüklenir', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final tr = lookupAppLocalizations(const Locale('tr'));
    expect(en.appTitle, 'Erdek City Guide');
    expect(tr.appTitle, 'Erdek Şehir Rehberi');
    expect(en.prayerName('aksam'), 'Maghrib');
    expect(en.monthName('11'), 'November');
    expect(en.weekdayName('6'), 'Saturday');
  });
}
