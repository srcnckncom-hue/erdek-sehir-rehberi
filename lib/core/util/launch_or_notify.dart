import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// tel:/harita bağlantısını açar; açılamazsa kısa uyarı gösterir.
Future<void> launchOrNotify(BuildContext context, Future<bool> Function() launch) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final message = AppLocalizations.of(context).cannotOpen;
  var ok = false;
  try {
    ok = await launch();
  } catch (_) {
    ok = false;
  }
  if (!ok) messenger?.showSnackBar(SnackBar(content: Text(message)));
}
