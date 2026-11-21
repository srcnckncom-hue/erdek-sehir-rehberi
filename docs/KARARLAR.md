# Erdek Şehir Rehberi — Alınan kararlar

> Yeni bir Claude sohbetinde devam ederken önce bu dosyayı okut. Proje kuralları,
> tasarım, sürümler ve sıradaki adım burada. Kod ve veri bu repoda.
>
> Yeni sohbete başlarken: GitHub reposunu (srcnckncom-hue/erdek-sehir-rehberi) bağla,
> Claude masaüstü uygulamasında `Documents\GitHub\erdek-sehir-rehberi` klasörünü ekle
> (+ → Add folder) ve şunu yaz: "docs/KARARLAR.md'yi oku, Erdek Şehir Rehberi'ne
> kaldığımız yerden devam ediyoruz."
>
> Son güncelleme: 21.11.2026, 13. adım tamam (TestFlight'a ilk derleme gitti).

## Durum
- 1–4. adım TAMAM: iskelet + CI, veri katmanı, tasarım sistemi + bileşenler + golden, ana sayfa gerçek veriyle (AppShell, HomeScreen, AdSlot stub, nowProvider, AnnouncementsSeenStore, Launchers).
- 5. adım TAMAM: PharmacyScreen, PageHeader/GroupedCard, DateTexts, launchOrNotify.
- 6. adım TAMAM (prayer-sync çalıştı → data/prayer_times.json gerçek veri, 2026-11-01..2026-12-31, isSample:false): vakit çekme scripti + prayer-sync.yml, bildirim planlayıcı + flutter_local_notifications ^23.0.3 (timezone ^0.11.2), AppDelegate delegate, PrayerScreen + imsakiye + bildirim ayar sayfası, test/fixtures/data.
- 7. adım TAMAM: TransportScreen, transport_selection.dart, golden 06_ulasim. Gestaş feribot tarifesi GERÇEK (8 hat, gidiş/dönüş + varış saati, Kış tarifesi); geçerlilik tarihleri 2026-11-21..2027-03-31 YER TUTUCU.
- 8. adım TAMAM:
  - Rehber sekmesi: DirectoryScreen(isActive) → Telefonlar / Duyurular anahtarı (directory_selection.dart). Telefonlar: kırmızı 112 kartı + kategori GroupedCard + ContactRow. Duyurular: kategori hapları, AnnouncementCard ("Yeni" rozeti, tarih aralığı, bağlantı). Duyurular yalnızca sekme gerçekten görünürken okundu sayılır (announcementsLastSeenProvider). Alt reklam contacts_bottom.
  - Ana sayfa: zil → Duyurular (okunmamış sayısı), kutucuklar Rehber'e segment seçerek gider.
  - Arama: openSearch() tam ekran; TextSearch Türkçe büyük/küçük + aksan katlama; en az 2 karakter, bölüm başına en fazla 8 sonuç.
  - Ulaşım 3. tür "Şehir İçi" (TransportMode.city): Balıkesir Büyükşehir mahalle hatları ÖRNEK, rota düzeyinde isSample:true. Şehirlerarası otobüs de ÖRNEK.
  - Ortak: pill_selectors.dart (SegmentedPills, PillChoiceRow), Launchers.openUrl/formatPhone, golden 07_rehber.
- 8b ara adım (Keşfet) TAMAM (CI yeşil, ekran görüntüleri onaylandı):
  - Ana sayfada "Şehir Hizmetleri" altına "Keşfet" bölümü (Gezilecek Yerler aqua, Erdek Tarihi mor); ☰ menüde de var. Metinler ÖRNEK. Fotoğraf yok → tür ikonu + "Fotoğraf yakında" (hakkı bize ait fotoğraflar gelince eklenecek).
  - data/places.json (area erdek/kapidag; category plaj/tarihi/doga/koy/manzara/diger; summary, paragraphs, tips?, address?, latitude/longitude?) — 6 ÖRNEK yer. data/history.json (intro?, sections: id/title/period?/paragraphs) — 4 ÖRNEK dönem.
  - lib/features/explore: PlacesScreen, PlaceDetailScreen, HistoryScreen (Navigator.push). PageHeader'a onBack eklendi.
  - Arama gezilecek yerleri de arıyor. Bu sayfalarda reklam YOK.
  - Golden 08_gezilecek_yerler, 09_yer_ayrinti, 10_erdek_tarihi.
- 9. adım reklam sistemi BAŞLADI (21.11.2026):
  - Kararlar: geçiş (tam ekran) reklamı YOK. Banner = görsel (2:1, 1200×600) + başlık (+ isteğe bağlı reklam veren adı), köşede "Reklam" etiketi.
  - Supabase projesi: https://kzoydwxugwhorbbjqctb.supabase.co, bölge Europe. Publishable key (herkese açık) GitHub Secret SUPABASE_ANON_KEY olarak; SUPABASE_URL de secret. Secret key sohbete yapıştırıldığı için SİLİNDİ; secret key kullanılmıyor, asla sohbete yazılmaz. Proje ayarı: Data API açık, otomatik grant kapalı, otomatik RLS açık.
  - 9a TAMAM (CI yeşil; SQL çalıştırıldı, kullanıcı admin; GitHub Secrets SUPABASE_URL + SUPABASE_ANON_KEY eklendi): supabase/migrations/0001_ads.sql (admins, ad_slots [6 slot], ads, ad_placements, ad_stats_daily; RLS; uygulama yalnızca get_active_ads() ve record_ad_event() RPC'lerini çağırır; ad-images public kovası, yalnız admin yazar; is_admin()). Uygulama: features/ads (Ad, pickAd [en yüksek öncelik + oturum başına dönüş], AdsRepository dio ile REST/RPC, apikey başlığı, önbellek 'ads_active', örnek ayarlarda ağa çıkmaz), gerçek AdSlot (gösterim/tıklama sayımı, index parametresi), ana sayfa yenilemesi reklamları da yeniler.
  - 9b TAMAM (panel yayında, kullanıcı reklam yayınladı): admin/ ayrı Flutter Web projesi (http + package:web; supabase_flutter KULLANILMADI). Giriş (Supabase Auth şifre, oturum localStorage'da refresh token), admin kontrolü, reklam listesi (durum, alanlar, tarih, 30 günlük gösterim/tıklama/oran), ekle/düzenle/sil, görsel seçme (≤1 MB, JPG/PNG/WEBP) + Storage'a yükleme, alan seçimi, TR günü ile başlangıç/bitiş, öncelik, yayında anahtarı, günlük istatistik tablosu. Adres: https://srcnckncom-hue.github.io/erdek-sehir-rehberi/admin/. Kök analysis_options admin/** hariç; admin analizi build_pages.sh içinde. pages-deploy.yml'e secrets env eklendi (kullanıcı elle taşır).
  - 9c TAMAM (SQL çalıştı, panel çalışıyor) — Kullanıcı kararı: içerikler panelden yönetilecek (App Store güncellemesi olmadan):
    - supabase/migrations/0002_content.sql: content_docs (id: contacts/announcements/pharmacy/transport/places/history; doc = data/*.json ile aynı zarf), admin RLS, get_content(id) RPC (anon).
    - Uygulama: ContentJsonFetcher (lib/core/network) → bu 6 dosya için önce Supabase get_content, belge yoksa/ayarsızsa GitHub Pages; hata olursa önbellek/gömülü kopya (OfflineFirstLoader). Namaz vakitleri hep Pages.
    - Panel: NavigationRail (Reklamlar, Telefonlar, Duyurular, Nöbetçi Eczane, Gezilecek Yerler, Erdek Tarihi, Ulaşım[yakında]). ContentEditor: belge Supabase'te yoksa yayındaki kopyadan (../data/<id>.json) başlar; ÖRNEK uyarısı anahtarı, kaynak notu, Kaydet (updatedAt TR saati). form_kit: diyalog formları, telefon normalize (+90…), paragraflar boş satırla, ipuçları satır satır.
    - repo data/*.json artık yalnızca uygulamayla gelen yedek kopya (validate_data.py hâlâ kontrol eder).
  - 9d TAMAM: panel Ulaşım düzenleyicisi (admin/lib/content/transport_editor.dart): tür sekmeleri, hat ekle/düzenle (yön, işletme, telefon, not, ÖRNEK işareti), tarife ekle/kopyala/sil (tarih aralığı), sefer sayfası (kalkış, varış, günler [boş = her gün], not; toplu ekleme "07:30-09:00" satırlarıyla). Bununla 9. adım tamamlanır.
- 10. adım TAMAM (CI yeşil). Karar: küçük = sıradaki vakit, orta = vakit + nöbetçi eczane. Kullanıcının ücretli Apple Developer hesabı VAR (daha önce uygulama yayınlamış).
  - Bundle: com.erdek.sehirrehberi.erdekrehberi, widget: …erdekrehberi.widget, App Group: group.com.erdek.sehirrehberi.erdekrehberi (12. adımda Apple'da App ID'lere App Groups yetkisi + match profilleri İKİ bundle için).
  - Flutter: lib/features/home_widget_sync/widget_sync.dart (7 günlük vakitler + 08:30 nöbet pencereleri, ISO +03:00) → MethodChannel 'erdek/widget' → AppDelegate UserDefaults(suiteName) 'widget_data' + WidgetCenter.reloadAllTimelines. AppShell veri değişince ve uygulama öne gelince gönderir.
  - iOS: ios/ErdekWidget (SwiftUI, StaticConfiguration, küçük/orta, iOS 16+, iOS 17 containerBackground), Info.plist sürümleri $(FLUTTER_BUILD_NAME/NUMBER) Widget.xcconfig ile; Runner.entitlements.
  - Hedef Xcode projesine CI'da scripts/add_widget_target.rb (xcodeproj gem, tekrar çalıştırılabilir, embed fazı Thin Binary'den önce) ile eklenir — ios-ci'de adım var, ios-release'de de OLMALI.
- 11. adım TAMAM (CI yeşil): logo ONAYLANDI ("şimdilik"): Bursa şehir rehberi rozet stilinden ilham; kemer içinde gün batımı + Kapıdağ silueti + deniz + yelkenli + martılar, sol kenarda zeytin dalı (Düzlerspor'dan yalnızca fikir, kopya değil), mavi levhada ERDEK, turuncu kurdelede ŞEHİR REHBERİ, Poppins Bold. Kaynak: assets/images/logo.svg; logo.png (drawer). İkon: krem #FFF6EA zemin + logo (tüm AppIcon boyutları). Açılış: LaunchImage 240×210 pt, beyaz zemin. Not: küçük boyda alt yazı zor okunuyor; kullanıcı böyle kalsın dedi.
- 12. adım TAMAM (ios-signing-setup yeşil; certs/profiles erdek-certificates'ta; PAT adı erdek-match-2, süresi dolunca MATCH_GIT_URL yenilenmeli): Gemfile (fastlane), fastlane/Appfile, Matchfile (git storage, appstore), Fastfile (lane certificates: match appstore, APP + WIDGET, API key ile, readonly false). Workflow ios-signing-setup.yml (workflow_dispatch, macos-26). Secrets: APPLE_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8 (p8 içeriği), MATCH_PASSWORD, MATCH_GIT_URL (https://x-access-token:<fine-grained PAT>@github.com/srcnckncom-hue/erdek-certificates.git). Apple tarafı elle: App Group + iki App ID (App Groups yetkisi, gruba bağlı) + App Store Connect API anahtarı (App Manager).
- 13. adım TAMAM (ios-release yeşil, ilk derleme TestFlight'a gitti; widget betiği ios-release'de `bundle exec ruby` ile çalışır): pubspec version 1.0.0+1. Fastfile lane beta: match readonly → update_code_signing_settings (Runner + ErdekWidget, manual, Apple Distribution) → build no = latest_testflight_build_number+1 → ExportOptions (app-store-connect, manual, iki profil) → flutter build ipa --dart-define-from-file=config/env.json → upload_to_testflight (beklemeden). Workflow ios-release.yml (workflow_dispatch, macos-26, Xcode 26.6): make_env.sh (DATA_BASE_URL Pages, WEATHER_USER_AGENT "ErdekSehirRehberi/1.0 github.com/srcnckncom-hue/erdek-sehir-rehberi"), add_widget_target.rb, fastlane ios beta. App Store Connect'te uygulama kaydı açıldı.
- Firebase: ERTELENDİ.
- SIRADAKİ:
  1. Kullanıcı TestFlight'ta kendi iPhone'unda deneyecek (Internal Testing grubu) ve geri bildirim verecek: logo/açılış, reklam, widget, panelden gelen içerikler.
  2. 14. adım App Store hazırlığı: ekran görüntüleri (golden 6.9" 1320×2868 tabanlı), açıklama/anahtar kelimeler/kategori, gizlilik politikası + kullanım koşulları (docs/legal → Pages /legal/), App Privacy formu (konum yok, takip yok; reklam sayımı anonim), destek URL'si, yaş derecelendirmesi, hero fotoğrafı kullanım hakkı teyidi, "resmi değil" ibaresi.
  3. Gerçek veriler panelden girilecek (telefonlar, eczane nöbetleri, şehir içi hatlar, gezilecek yerler, tarih).
  4. Ertelenenler: Firebase (Crashlytics + FCM, admin'den bildirim), Diyanet API'ye geçiş.

## Kullanıcıdan beklenen gerçek veriler
- Gestaş tarifesinin gerçek geçerlilik tarihleri ve telefonu.
- Erdek–Bandırma, Erdek–Balıkesir otobüs saatleri.
- Balıkesir Büyükşehir Erdek içi mahalle hatları (hat adı, mahalleler, saatler, gün tipleri).
- Önemli telefonlar, nöbetçi eczane listesi, duyurular.
- Gezilecek yerlerin ve Erdek tarihinin gerçek metinleri; kullanım hakkı olan fotoğraflar.

## Kurallar (kullanıcının şartnamesinden)
- Gizli anahtarlar repoya girmez; CI'da secrets'tan üretilen dosya + --dart-define-from-file.
- Belediye / eczacı odası logosu veya "resmi" izlenimi KULLANILMAZ.
- Diyanet API'si uygulamadan doğrudan çağrılmaz, kimlik bilgisi gömülmez.
- Gerçek telefon / saat / işletme uydurulmaz. Emin olunmayan veri veya tasarım detayı sorulur ya da ÖRNEK/TODO işaretlenir.

## Namaz vakti kaynağı
- Hürriyet sayfası kazıma REDDEDİLDİ (telif/kırılganlık).
- Şimdilik ezanvakti.imsakiyem.com (Diyanet verisi, ücretsiz, anahtarsız). Uç nokta: /api/prayer-times/{districtId}/range?startDate&endDate&limit=100; Erdek id 17881.
- Kullanıcı Diyanet Awqat Salah başvurusunu sonra yapacak → fetch_diyanet() tamamlanacak, secrets AWQAT_USERNAME/AWQAT_PASSWORD, PRAYER_SOURCE=diyanet.

## Tasarım (onaylandı 21.11.2026)
- Görseller (design/02_ana_sayfa_v2.png) yalnızca GÖRSEL STİL kaynağı; içerik şartnameden. Görselden ek: hava durumu.
- Ana sayfa: hero · ☰ menü · 🔔 duyurular · hava · arama · 3 renkli kart (Nöbetçi Eczane peach, Namaz Vakitleri mint, Feribot Saatleri aqua) · 8 kutucuk · home_feed_1 reklamı · Şehir Hizmetleri (kırmızı eczane kartı, sıradaki vakit, feribot + otobüs) · Keşfet. Alt sekmeler: Ana Sayfa, Eczane, Vakitler, Ulaşım, Rehber. Aktif sekme zemini primary %10.
- Alt sayfalar: PageHeader (26/700 + ikincil satır, isteğe bağlı geri düğmesi), beyaz kartlar r20, GroupedCard, InfoBanner, hap seçiciler, segment anahtarı.
- Palet: primary #0057FC, heading #061826, body #0A0F1A, secondary #5F6779, bg #F4F5F9, surface #FFF, accentRed #C81C18, badge #E82430, peach #FCE0B5/#D06F04, mint #C0F4D8/#068A55, aqua #BAF0F0/#00808C, ikon renkleri mor #6545C4 mavi #0858C2 kırmızı #E0241A bordo #D01030 turuncu #F49022 somon #F07A6E. Koyu tema türetildi.
- Font: Poppins 400/500/600/700. Ölçek: pageTitle 26/700, display 56/700, cardTitle 22/700, section 20/600, greeting 17/500, label 15/500, body 15/400, tile 13/500, caption 13/400, tab 11/500.
- Ölçüler: kenar 14, boşluk 8, bölüm 24, chip h50 r14, tile h70 r16, arama h48, kart r20, hero ~295 alt köşe 28.
- Reklam: ana sayfada YALNIZCA home_feed_1 (2:1, 1200×600). Sayfa altları: pharmacy_bottom, prayer_bottom, transport_bottom, contacts_bottom; liste içi transport_list_inline (her 5 sefer).
- Logo: 11. adımda onaylandı (assets/images/logo.svg). Hero fotoğrafının kullanım hakkı App Store öncesi teyit edilmeli.

## İkonlar
- phosphor_flutter KULLANMA. phosphoricons_flutter ^1.1.1; AppIconData + AppIcon; tek dosya app_icons.dart.

## Hava durumu
- Open-Meteo KULLANILMAZ (ücretsiz katman ticari değil). MET Norway: CC BY 4.0 atıf, User-Agent (WEATHER_USER_AGENT), Expires önbelleği.

## Veri katmanı
- Zarf: {schemaVersion:1, isSample, updatedAt, source, data}. data/*.json assets olarak gömülü ve GitHub Pages'te yayınlı; şemalar data/schemas, kontrol scripts/validate_data.py, açıklama docs/DATA.md.
- Yükleme: önbellek → uygulamayla gelen kopya → ağ (OfflineFirstLoader).
- Zaman hesapları Erdek saati ALANLARIYLA (CalendarDate/ClockTime). Tarih metinleri DateTexts (arb select).
- Elle fromJson. hive_ce_flutter ^2.5.0; kutular: json_cache, settings.

## Sürümler / dil kuralları
- Flutter 3.50.0 (Dart 3.14). Runner macos-26, Xcode 26.6. Min iOS 16.0.
- `package:material_ui/material_ui.dart`; analyze info'larda da fail.
- Lokalizasyon: [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]. arb placeholder adlarında `from` gibi kelimelerden kaçın.
- Lint dersleri: public `this.x` initializing formal; null-aware element (`?x`); parametre adı static üyeyle çakışmasın; doc yorumunda `<x>` backtick; buton metinleri Flexible + ellipsis; bekletilmeyen future'lar unawaited().
- Paket seçerken Flutter 3.44+/3.50 uyumluluğunu ve bağımlılık çakışmalarını kontrol et.
- Riverpod 3; testlerde testScope()/testApp(); test verisi test/fixtures/data, eşzamanlı File okuma. Testlerde bySemanticsLabel yerine Key kullan.

## Golden / ekran görüntüsü
- Cihazlar: iPhone SE 375×667@2, iPhone 16 Pro Max 440×956@3. Dosyalar 01–10.
- CI: `--exclude-tags golden` + `--tags golden --update-goldens` → "screenshots" artifact.

## Firebase (ERTELENDİ)
- Crashlytics + FCM (topic). Analytics kapalı. APNs key 12. adımda. Admin "Bildirim gönder" 9. adımda.

## Mimari
- riverpod 3, hive_ce_flutter, phosphoricons_flutter, dio, timezone ^0.11.2, url_launcher, flutter_local_notifications ^23.0.3.
- Admin paneli: Flutter Web. Pages: https://srcnckncom-hue.github.io/erdek-sehir-rehberi/
- iOS derleme/imzalama tamamen GitHub Actions macOS'ta (Mac yok); Xcode'da elle işlem yok.

## Çalışma düzeni
- Repo: github.com/srcnckncom-hue/erdek-sehir-rehberi (public). Windows + GitHub Desktop. Klon: C:\Users\sercan\Documents\GitHub\erdek-sehir-rehberi
- Claude dosyaları masaüstü uygulamasının klasör bağlantısıyla yazar; kullanıcı GitHub Desktop'ta commit + push eder, CI logunu yapıştırır.
- .github/workflows/ dosyaları uzaktan yazılamıyorsa Desktop\erdek-workflows\adimN klasörüne konur, kullanıcı elle taşır.
- Prayer-sync bot commit'lerinden sonra kullanıcı Pull yapmalı.
- Kullanıcı adım adım, kısa talimat istiyor; tam tıklama yolu ver.
