import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'launch/launch_gate.dart';
import 'providers.dart';

class ErdekApp extends ConsumerWidget {
  const ErdekApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      // Varsayılan Türkçe; Ayarlar'dan İngilizce seçilebilir.
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      // Flutter 3.50: Material/Cupertino çevirileri artık material_ui içinde.
      // gen-l10n'in ürettiği AppLocalizations.localizationsDelegates eski
      // flutter_localizations delegelerini içerdiği için kullanılmıyor.
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Varsayılan AÇIK; kullanıcı ☰ menüden Koyu / Telefonla aynı seçebilir.
      themeMode: ref.watch(themeModeProvider),
      // Açılış animasyonu → (ilk açılışta) tanıtım → ana iskelet.
      home: const LaunchGate(),
    );
  }
}
