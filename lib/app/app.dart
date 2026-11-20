import 'package:flutter/material.dart';

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // GEÇİCİ: 3. adımda lib/core/theme (AppTheme.light / AppTheme.dark)
      // ile değiştirilecek. Burada renk/ölçü tanımlanmayacak.
      theme: ThemeData(useMaterial3: true),
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
                  style: Theme.of(context).textTheme.headlineSmall,
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
