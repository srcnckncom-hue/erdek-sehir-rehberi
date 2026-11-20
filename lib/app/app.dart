import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

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
      home: const _SetupPlaceholder(),
    );
  }
}

class _SetupPlaceholder extends StatelessWidget {
  const _SetupPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(l10n.setupInProgress, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
