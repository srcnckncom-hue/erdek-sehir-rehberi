import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';

/// Görünüm tercihi (Açık / Koyu / Telefonla aynı). Varsayılan: AÇIK.
/// Yalnızca cihazda tutulur.
abstract interface class ThemeModeStore {
  ThemeMode load();

  Future<void> save(ThemeMode mode);
}

class HiveThemeModeStore implements ThemeModeStore {
  HiveThemeModeStore(this.box);

  static const _key = 'theme_mode';

  final Box<String> box;

  @override
  ThemeMode load() => switch (box.get(_key)) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };

  @override
  Future<void> save(ThemeMode mode) => box.put(_key, mode.name);
}

class MemoryThemeModeStore implements ThemeModeStore {
  MemoryThemeModeStore([this.mode = ThemeMode.light]);

  ThemeMode mode;

  @override
  ThemeMode load() => mode;

  @override
  Future<void> save(ThemeMode mode) async => this.mode = mode;
}
