import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/system/system_bridge.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/launchers.dart';
import '../../l10n/app_localizations.dart';
import '../pharmacy/domain/pharmacy.dart';

/// Paylaşım metinleri (WhatsApp vb.). Saf fonksiyonlar; test edilir.
abstract final class ShareTexts {
  /// Apple Haritalar bağlantısı (koordinat varsa iğneli, yoksa adres araması).
  static String mapsUrl({required String name, String? address, double? latitude, double? longitude}) {
    final params = <String, String>{
      'q': name,
      if (latitude != null && longitude != null) 'll': '$latitude,$longitude',
      if ((latitude == null || longitude == null) && address != null) 'address': address,
    };
    return Uri.https('maps.apple.com', '/', params).toString();
  }

  /// "Bugün nöbetçi eczane: X Eczanesi\nAdres\nTel: ...\nNot\nHarita: ...\n— Erdek Şehir Rehberi"
  static String pharmacy(
    AppLocalizations l10n, {
    required Pharmacy pharmacy,
    required String dayLabel,
    String? note,
  }) =>
      [
        l10n.sharePharmacyTitle(dayLabel, pharmacy.name),
        pharmacy.address,
        l10n.sharePhoneLine(Launchers.formatPhone(pharmacy.phone)),
        ?note,
        l10n.shareMapLine(
          mapsUrl(
            name: pharmacy.name,
            address: pharmacy.address,
            latitude: pharmacy.latitude,
            longitude: pharmacy.longitude,
          ),
        ),
        '— ${l10n.appTitle}',
      ].join('\n');

  /// "Erdek → Avşa feribotu\nBugün 08:30 (varış 10:00)\n— Erdek Şehir Rehberi"
  static String departure(
    AppLocalizations l10n, {
    required String routeTitle,
    required String dayLabel,
    required String time,
    String? arrival,
    String? note,
  }) =>
      [
        routeTitle,
        arrival == null ? l10n.shareDepartureLine(dayLabel, time) : '${l10n.shareDepartureLine(dayLabel, time)} · ${l10n.arrivalAt(arrival)}',
        ?note,
        '— ${l10n.appTitle}',
      ].join('\n');
}

/// WhatsApp'ı hazır metinle açar (kişi/grup seçilir). WhatsApp yoksa iOS
/// paylaşım penceresi açılır.
Future<void> shareToWhatsApp(WidgetRef ref, String text) async {
  var ok = false;
  try {
    ok = await Launchers.openUrl('https://wa.me/?text=${Uri.encodeComponent(text)}');
  } catch (_) {
    ok = false;
  }
  if (!ok) await ref.read(systemBridgeProvider).share(text);
}

/// Yuvarlak WhatsApp paylaş düğmesi (eczane kartı vb.).
class WhatsAppShareButton extends ConsumerWidget {
  const WhatsAppShareButton({super.key, required this.text, this.size = AppSpacing.minTouchTarget});

  final String text;
  final double size;

  static const _green = Color(0xFF25D366);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.shareWhatsApp,
      child: Semantics(
        button: true,
        label: l10n.shareWhatsApp,
        excludeSemantics: true,
        child: Material(
          color: _green.withValues(alpha: 0.14),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => shareToWhatsApp(ref, text),
            child: SizedBox.square(
              dimension: size,
              child: Center(child: AppIcon(AppIcons.whatsapp, size: 22, color: const Color(0xFF128C4B))),
            ),
          ),
        ),
      ),
    );
  }
}
