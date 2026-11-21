import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';

/// Uygulama dili: Türkçe (VARSAYILAN) veya İngilizce. Telefonun dilinden
/// bağımsızdır; yalnızca Ayarlar'dan değişir. Yalnızca cihazda tutulur.
abstract interface class LocaleStore {
  Locale load();

  Future<void> save(Locale locale);
}

const supportedAppLocales = [Locale('tr'), Locale('en')];

Locale _parse(String? code) => code == 'en' ? const Locale('en') : const Locale('tr');

class HiveLocaleStore implements LocaleStore {
  HiveLocaleStore(this.box);

  static const _key = 'app_locale';

  final Box<String> box;

  @override
  Locale load() => _parse(box.get(_key));

  @override
  Future<void> save(Locale locale) => box.put(_key, locale.languageCode);
}

class MemoryLocaleStore implements LocaleStore {
  MemoryLocaleStore([this.locale = const Locale('tr')]);

  Locale locale;

  @override
  Locale load() => locale;

  @override
  Future<void> save(Locale locale) async => this.locale = locale;
}
