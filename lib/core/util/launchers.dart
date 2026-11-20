import 'package:url_launcher/url_launcher.dart';

/// Telefon ve harita bağlantıları. iOS'ta tel: doğrudan arama ekranını,
/// maps.apple.com bağlantısı Apple Haritalar'ı açar.
abstract final class Launchers {
  /// Boşlukları temizleyip arar ("+90 266 ..." → "tel:+90266...").
  static Future<bool> call(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return launchUrl(Uri(scheme: 'tel', path: cleaned));
  }

  /// Apple Haritalar'da yol tarifi. Koordinat yoksa adresle arar.
  static Future<bool> directions({
    required String name,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    final params = <String, String>{
      if (latitude != null && longitude != null) 'daddr': '$latitude,$longitude',
      if (latitude == null || longitude == null) 'daddr': address ?? name,
      'q': name,
    };
    return launchUrl(
      Uri.https('maps.apple.com', '/', params),
      mode: LaunchMode.externalApplication,
    );
  }
}
