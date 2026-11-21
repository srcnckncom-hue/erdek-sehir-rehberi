import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'launch/launch_gate.dart';

class ErdekApp extends StatelessWidget {
  const ErdekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
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
      themeMode: ThemeMode.system,
      // Açılış animasyonu → (ilk açılışta) tanıtım → ana iskelet.
      home: const LaunchGate(),
    );
  }
}
