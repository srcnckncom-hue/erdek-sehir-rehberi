import 'package:firebase_core/firebase_core.dart';

import '../core/platform/device.dart';

/// Firebase (yalnızca Cloud Messaging) iOS ayarı.
///
/// Değerler Firebase konsolundaki GoogleService-Info.plist dosyasından
/// alınır. Gizli DEĞİLDİR (her iOS uygulamasının içinde bulunur); bildirim
/// GÖNDERMEK için ayrıca sunucu yetkisi gerekir.
/// Boşken Firebase hiç başlatılmaz, uygulama bildirimsiz çalışır.
abstract final class FirebaseConfig {
  static const _apiKey = 'AIzaSyDXGBFnsE12ZrEDXXuunJ7PjL4dgUmyEZc';
  static const _appId = '1:112186406573:ios:239008ca4e2c3000e97824';
  static const _senderId = '112186406573';
  static const _projectId = 'erdek-sehir-rehberi';
  static const _bundleId = 'com.erdek.sehirrehberi.erdekrehberi';

  /// Android: Firebase konsolu → Proje ayarları → Android uygulaması
  /// (paket adı com.erdek.sehirrehberi.erdekrehberi) → "Uygulama kimliği" ve
  /// google-services.json içindeki "current_key". Boşken Android'de anlık bildirim kapalı.
  static const _androidAppId = '';
  static const _androidApiKey = '';

  static FirebaseOptions? get options => isAndroidDevice ? _android : _ios;

  static FirebaseOptions? get _android => _androidAppId.isEmpty || _androidApiKey.isEmpty
      ? null
      : const FirebaseOptions(
          apiKey: _androidApiKey,
          appId: _androidAppId,
          messagingSenderId: _senderId,
          projectId: _projectId,
        );

  static FirebaseOptions? get _ios => _apiKey.isEmpty
      ? null
      : const FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _senderId,
          projectId: _projectId,
          iosBundleId: _bundleId,
        );
}
