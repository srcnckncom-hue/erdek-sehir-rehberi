import 'package:material_ui/material_ui.dart';

import 'api.dart';
import 'screens/login_screen.dart';
import 'shell.dart';

/// Derleme sırasında GitHub Secrets'tan gelir (pages-deploy.yml).
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() {
  runApp(AdminApp(api: Api(url: _supabaseUrl, apiKey: _supabaseKey)));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erdek Rehberi · Reklam Paneli',
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0057FC),
        scaffoldBackgroundColor: const Color(0xFFF4F5F9),
      ),
      home: api.isConfigured ? _Gate(api: api) : const _NotConfigured(),
    );
  }
}

/// Kayıtlı oturum varsa geri yükler, yoksa giriş ekranı.
class _Gate extends StatefulWidget {
  const _Gate({required this.api});

  final Api api;

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  late final Future<bool> _restore = widget.api.restoreSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restore,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return widget.api.isSignedIn ? AdminShell(api: widget.api) : LoginScreen(api: widget.api);
      },
    );
  }
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Panel yapılandırılmamış: SUPABASE_URL / SUPABASE_ANON_KEY '
              'GitHub Secrets\'ta tanımlı olmalı.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}
