import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Sonraki adımlarda burada: timezone (Europe/Istanbul), hive_ce, Sentry,
  // Supabase başlatma. Hepsi lib/app/bootstrap.dart içine taşınacak.
  runApp(const ProviderScope(child: ErdekApp()));
}
