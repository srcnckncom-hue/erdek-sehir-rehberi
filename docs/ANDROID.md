# Android sürümü

Uygulamanın Dart kodu iki platformda ortak. Android'e özel parçalar:

| iOS | Android |
|---|---|
| MapKit haritası | OpenStreetMap (osmdroid, anahtar gerekmez) — `ErdekMapView.kt` |
| CoreLocation | LocationManager — `LocationHelper.kt` |
| WidgetKit (3 widget) | AppWidget: Namaz Vakti, Nöbetçi Eczane, Sıradaki Sefer — `Widgets.kt` |
| Takvim penceresi | Takvim uygulamasının "Etkinlik ekle" ekranı (izin gerekmez) |
| Siri kısayolları | Yok (Android karşılığı sonra eklenebilir) |
| Apple Haritalar bağlantıları | Google Haritalar |
| App Store bağlantısı | Google Play bağlantısı |

## Derleme

Repoda yalnızca bize özel dosyalar var. Gradle dosyaları derlemede
`scripts/setup_android.sh` ile kurulu Flutter sürümüne göre üretilir
(`android/app/erdek.gradle` en sona eklenir).

GitHub: **Actions → android-build → Run workflow**. Bitince sayfanın altındaki
**erdek-android** dosyasını indirin:
- `ErdekRehberi.apk` → Android telefona doğrudan kurulur (deneme).
- `ErdekRehberi.aab` → Google Play Console'a yüklenir.

## Google Play için yükleme anahtarı

Play'e yüklemek için bir kez yükleme anahtarı oluşturulur ve GitHub Secrets'a eklenir:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
Sırlar yoksa derleme deneme anahtarıyla imzalanır (telefona kurulur, Play kabul etmez).

## Anlık bildirim (Firebase)

Firebase konsolu → Proje ayarları → **Android uygulaması ekle** →
paket adı `com.erdek.sehirrehberi.erdekrehberi`. İndirilen `google-services.json`
içindeki `mobilesdk_app_id` ve `current_key` değerleri `lib/app/firebase_config.dart`
içindeki `_androidAppId` ve `_androidApiKey` alanlarına yazılır. Boşken Android'de
yalnızca anlık (sunucu) bildirimler kapalıdır; vakit ve hatırlatma bildirimleri çalışır.
