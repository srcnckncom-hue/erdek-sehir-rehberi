import 'package:firebase_core/firebase_core.dart';

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

  static FirebaseOptions? get options => _apiKey.isEmpty
      ? null
      : const FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _senderId,
          projectId: _projectId,
          iosBundleId: _bundleId,
        );
}
