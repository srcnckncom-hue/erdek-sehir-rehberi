import '../../l10n/app_localizations.dart';
import '../contacts/domain/contacts.dart';
import '../nearby/location_service.dart';

/// Acil durum ekranının uygulamaya gömülü bilgileri. İnternet olmadan da
/// çalışsın diye panelden değil koddan gelir (ulusal numaralar değişmez).
abstract final class Emergency {
  /// Tek acil numara. 110, 155, 156, 158, 177 ve 122 de buraya bağlanır.
  static const number = '112';

  /// e-Devlet › Afet ve Acil Durum Toplanma Alanı Sorgulama (AFAD).
  static const assemblyAreaUrl =
      'https://www.turkiye.gov.tr/afet-ve-acil-durum-yonetimi-acil-toplanma-alani-sorgulama';

  /// Rehberdeki bu kategoriler "Yerel numaralar" olarak gösterilir.
  static const localCategoryIds = {'acil', 'kamu'};
}

enum HelpLine {
  poison('114'),
  health('184'),
  social('183'),
  water('185'),
  electricity('186'),
  gas('187');

  const HelpLine(this.number);

  final String number;

  String title(AppLocalizations l10n) => switch (this) {
        HelpLine.poison => l10n.helpLinePoison,
        HelpLine.health => l10n.helpLineHealth,
        HelpLine.social => l10n.helpLineSocial,
        HelpLine.water => l10n.helpLineWater,
        HelpLine.electricity => l10n.helpLineElectricity,
        HelpLine.gas => l10n.helpLineGas,
      };

  Contact toContact(AppLocalizations l10n) => Contact(name: title(l10n), phone: number);
}

/// Rehberden acil ve kamu numaraları (112 hariç, o en üstte).
List<Contact> localEmergencyContacts(ContactsData? data) => [
      for (final c in data?.categories ?? const <ContactCategory>[])
        if (Emergency.localCategoryIds.contains(c.id))
          for (final contact in c.contacts)
            if (contact.phone != Emergency.number) contact,
    ];

/// "40.39550, 27.79300" (112'ye okunacak biçim; nokta ile).
String formatCoordinates(GeoPoint point) =>
    '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';

/// Her telefonda açılan harita bağlantısı (Google Haritalar, iOS/Android/web).
String emergencyMapsUrl(GeoPoint point) => Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}',
    }).toString();

/// WhatsApp / paylaşım metni.
String emergencyShareText(AppLocalizations l10n, GeoPoint point) => [
      l10n.emergencyShareTitle,
      emergencyMapsUrl(point),
      l10n.emergencyShareCoordinates(formatCoordinates(point)),
      '— ${l10n.appTitle}',
    ].join('\n');
