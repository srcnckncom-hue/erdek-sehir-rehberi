import '../core/platform/device.dart';
import 'env.dart';

/// Uygulamanın herkese açık bilgileri (gizli DEĞİL).
abstract final class AppInfo {
  /// Hata bildirimi ve iletişim.
  static const supportEmail = 'hello@erdeksehirrehberi.com.tr';

  /// App Store Connect → Uygulamalar → Erdek Şehir Rehberi → Uygulama Bilgileri
  /// → "Apple Kimliği" (yalnızca rakam, ör. 6751234567).
  /// Boşken paylaşımda web sayfası kullanılır, "Değerlendir" düğmesi gizlenir.
  static const appStoreId = '6837640872';

  static bool get hasStoreId => appStoreId.isNotEmpty;

  /// Paylaşılan bağlantı.
  static String get shareUrl => isAndroidDevice
      ? playStoreUrl
      : hasStoreId
          ? 'https://apps.apple.com/tr/app/id$appStoreId'
          : '${Env.dataBaseUrl}/';

  /// Google Play sayfası (Android).
  static const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.erdek.sehirrehberi.erdekrehberi';

  /// App Store'da yorum yazma sayfası.
  static String get reviewUrl =>
      isAndroidDevice ? playStoreUrl : 'https://apps.apple.com/app/id$appStoreId?action=write-review';

  static String get privacyUrl => '${Env.dataBaseUrl}/legal/gizlilik.html';

  static String get termsUrl => '${Env.dataBaseUrl}/legal/kullanim-kosullari.html';
}
