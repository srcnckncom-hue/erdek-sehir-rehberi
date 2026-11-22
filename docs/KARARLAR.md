# Erdek Şehir Rehberi — Alınan kararlar

> Yeni bir Claude sohbetinde devam ederken önce bu dosyayı okut. Proje kuralları,
> tasarım, sürümler ve sıradaki adım burada. Kod ve veri bu repoda.
>
> Yeni sohbete başlarken: GitHub reposunu (srcnckncom-hue/erdek-sehir-rehberi) bağla,
> Claude masaüstü uygulamasında `Documents\GitHub\erdek-sehir-rehberi` klasörünü ekle
> (+ → Add folder) ve şunu yaz: "docs/KARARLAR.md'yi oku, Erdek Şehir Rehberi'ne
> kaldığımız yerden devam ediyoruz."
>
> Son güncelleme: 21.11.2026, renkli logo + çizim animasyonu ONAYLANDI (golden). Özellik paketi AŞAMA 1 (1–6) yazıldı, CI bekleniyor. Kullanıcı 12 özelliğin HEPSİNİ seçti: Aşama 1 = 1–6, Aşama 2 = 7–9, Aşama 3 = 10–11 (12 İngilizce öne alındı, yapıldı).

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
- 11. adım TAMAM (CI yeşil) — NOT: bu logo 21.11.2026'da yenisiyle DEĞİŞTİRİLDİ (aşağıda "YENİ LOGO"): logo ONAYLANDI ("şimdilik"): Bursa şehir rehberi rozet stilinden ilham; kemer içinde gün batımı + Kapıdağ silueti + deniz + yelkenli + martılar, sol kenarda zeytin dalı (Düzlerspor'dan yalnızca fikir, kopya değil), mavi levhada ERDEK, turuncu kurdelede ŞEHİR REHBERİ, Poppins Bold. Kaynak: assets/images/logo.svg; logo.png (drawer). İkon: krem #FFF6EA zemin + logo (tüm AppIcon boyutları). Açılış: LaunchImage 240×210 pt, beyaz zemin. Not: küçük boyda alt yazı zor okunuyor; kullanıcı böyle kalsın dedi.
- 12. adım TAMAM (ios-signing-setup yeşil; certs/profiles erdek-certificates'ta; PAT adı erdek-match-2, süresi dolunca MATCH_GIT_URL yenilenmeli): Gemfile (fastlane), fastlane/Appfile, Matchfile (git storage, appstore), Fastfile (lane certificates: match appstore, APP + WIDGET, API key ile, readonly false). Workflow ios-signing-setup.yml (workflow_dispatch, macos-26). Secrets: APPLE_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8 (p8 içeriği), MATCH_PASSWORD, MATCH_GIT_URL (https://x-access-token:<fine-grained PAT>@github.com/srcnckncom-hue/erdek-certificates.git). Apple tarafı elle: App Group + iki App ID (App Groups yetkisi, gruba bağlı) + App Store Connect API anahtarı (App Manager).
- 13. adım TAMAM (ios-release yeşil, ilk derleme TestFlight'a gitti; widget betiği ios-release'de `bundle exec ruby` ile çalışır): pubspec version 1.0.0+1. Fastfile lane beta: match readonly → update_code_signing_settings (Runner + ErdekWidget, manual, Apple Distribution) → build no = latest_testflight_build_number+1 → ExportOptions (app-store-connect, manual, iki profil) → flutter build ipa --dart-define-from-file=config/env.json → upload_to_testflight (beklemeden). Workflow ios-release.yml (workflow_dispatch, macos-26, Xcode 26.6): make_env.sh (DATA_BASE_URL Pages, WEATHER_USER_AGENT "ErdekSehirRehberi/1.0 github.com/srcnckncom-hue/erdek-sehir-rehberi"), add_widget_target.rb, fastlane ios beta. App Store Connect'te uygulama kaydı açıldı.
- TestFlight geri bildirimi 1 (21.11.2026): ilk derleme kullanıcının iPhone'unda çalıştı. İstek: açılış animasyonu + 3 tanıtım ekranı. YAZILDI, CI + yeni TestFlight derlemesi bekleniyor:
  - Kararlar: slogan "Şehrin rehberi, cebinde". Logo animasyonu HER açılışta (~2,4 sn; "Hareketi azalt" açıkken 0,9 sn); tanıtım yalnız İLK açılışta ("Geç" / "Başla"). Tanıtım sayfaları: 1) nöbetçi eczane + namaz vakitleri, 2) feribot + otobüs, 3) rehber/duyurular/keşfet + widget; 3. sayfada vakit bildirimi anahtarı (iOS izni burada istenir, isteğe bağlı).
  - lib/app/launch: LaunchGate (MaterialApp.home; AppShell perdenin ARKASINDA baştan kurulur, veri animasyon sırasında yüklenir), LaunchSplash (gri → renkli ColorFilter doygunluk matrisi Rec.709, hafif büyüme, slogan kayarak + harf aralığı daralarak, altında mavi çizgi; zemin her temada BEYAZ), OnboardingScreen (PageView, noktalar, Key: onboarding_skip / onboarding_next).
  - iOS açılış ekranı (LaunchImage 1x/2x/3x) logonun GRİ hâli (aynı katsayılar) → Flutter'a boşluksuz geçiş. main() runApp'ten önce logoyu önbelleğe alır (en çok 2 sn).
  - core/settings/onboarding_store.dart: Hive 'settings' kutusu, anahtar onboarding_done_v1 (içerik köklü değişirse v2 ile herkese yeniden gösterilir). onboardingStoreProvider varsayılanı "görüldü" (testler); testScope(onboardingStore:) parametresi.
  - Reklam: AdImpressionGate (ad_slot.dart, InheritedWidget) perde açıkken gösterim SAYMAZ; perde kalkınca sayılır.
  - Testler: test/features/launch_test.dart. Golden 11_acilis_gri/renkli (yalnız açık), 12_tanitim_1..3.
  - Golden 11/12 kullanıcıya gösterildi, onaylandı. SE'de 3. sayfa sığmıyordu → görsel küçültüldü, 3. sayfa ve bildirim metni kısaltıldı.
- TestFlight geri bildirimi 2 (21.11.2026): YAZILDI, CI bekleniyor:
  - Tema: VARSAYILAN AÇIK (artık telefonu izlemiyor). ☰ menüde "Görünüm": Açık / Koyu / Sistem (SegmentedPills, Key theme_mode_selector). core/settings/theme_store.dart (Hive 'settings', anahtar theme_mode: light/dark/system), themeModeProvider + ThemeModeNotifier.setMode (app/providers.dart), ErdekApp ConsumerWidget. Açılış animasyonu zemini her temada beyaz kalır.
  - Gezilecek yerlere FOTOĞRAF: places.json'da isteğe bağlı photos: [{url (https), credit?}] en çok 10, ilki KAPAK. Şema + DATA.md güncellendi.
    - supabase/migrations/0003_content_images.sql: public "content-images" kovası (2 MB, JPG/PNG/WEBP), yalnız admin yazar. KULLANICI SQL'i ÇALIŞTIRMALI.
    - Panel (places_editor): her yer kartının altında fotoğraf şeridi: ekle (≤2 MB, isteğe bağlı sahibi/kaynak), "Kapak yap", sil; yükleme anında Storage'a gider ama yayına "Kaydet" ile çıkar. Silinen fotoğraf Storage'da kalır (kaydedilmemiş belgeyi bozmamak için). Api.uploadContentImage(folder: 'places') herkese açık adres döndürür.
    - Uygulama: liste kartında kapak (64×64), ayrıntıda 4:3 kaydırmalı galeri + noktalar + "Fotoğraf: …"; yüklenemezse/yoksa tür ikonu (PlaceIconTile, PlacePhotoImage, PlacePhotoGallery — explore/presentation/place_photos.dart).
    - Kural: yalnızca kullanım hakkı bize ait / izinli fotoğraflar.
- YENİ LOGO (21.11.2026, kullanıcı verdi): altın/bronz çizgisel amblem (zeytin dalı + yelkenli + güneş + dalgalar, çember), altında serif "ERDEK" ve "ŞEHİR REHBERİ", slogan "Şehrin rehberi, cebinde". Eski rozet logosu (logo.svg) ARTIK KULLANILMIYOR.
  - Kaynak görselden (JPG, beyaz zemin) parçalara ayrıldı, beyaz zemin saydamlaştırıldı (gölgeler atıldı): assets/images/logo_emblem.png (759×702), logo_erdek.png (860×197), logo_sehir.png (717×123); logo.png = üçü birlikte (☰ menüde, yükseklik 150).
  - Uygulama ikonu: beyaz zemin + amblem (%80), tüm AppIcon boyutları yeniden üretildi.
  - iOS açılış ekranı artık BOŞ BEYAZ (LaunchImage saydam) → animasyon beyazdan başlar.
  - Açılış animasyonu (LaunchSplash, 3,2 sn; "Hareketi azalt"ta 1,2 sn, dönme yok): amblem küçükten büyüyerek 3 TUR döner (easeOutCubic, ölçek easeOutBack) → üzerinden çapraz ışık geçer → "ERDEK" ortadan iki yana açılarak → "ŞEHİR REHBERİ" yukarı kayarak → slogan (Poppins 500, #1C2439, harf aralığı daralarak). Gri→renkli efekti KALDIRILDI. Slogan Flutter metni (testler 'Şehrin rehberi, cebinde' metnini arar).
  - Golden 11_acilis_donus / _yazilar / _son.
- LOGO YİNE DEĞİŞTİ (21.11.2026 16:00, KESİN): renkli amblem — yeşil zeytin dalı (yeşil + mor zeytinler), mavi çizgisel yelkenli + dalgalar, koyu yeşil/lacivert dağlar, turuncu güneş ve turuncu çift çember; altında mavi "ERDEK" (#258DC2, kalın sans), turuncu "ŞEHİR REHBERİ", lacivert slogan. Kaynak design/logo_kaynak.jpg. Altın logo artık KULLANILMIYOR.
  - Parçalar: logo_emblem.png (778×685), logo_emblem_line.png (amblemin gri ÇİZGİ hâli, kenar algılamayla üretildi, aynı boyut), logo_erdek.png (832×185), logo_sehir.png (715×123), logo.png (☰ menü). Aralıklar (px): amblem→ERDEK 53, ERDEK→ŞEHİR 23, ŞEHİR→slogan 37. Uygulama ikonu: beyaz zemin + renkli amblem %80.
  - Açılış (2,8 sn; "Hareketi azalt"ta 1 sn, çizim yok): 0–0,40 gri çizgiler tepeden saat yönünde çizilir (SweepGradient maskesi) → 0,32–0,50 gri tonlu dolgu → 0,48–0,62 renklenir → ERDEK (ortadan açılarak) 0,58 → ŞEHİR REHBERİ 0,66 → slogan 0,74 (Poppins 500 #142036). Dönme efekti KALDIRILDI. Golden 11_acilis_cizim / _gri / _yazilar / _son.
- NÖBETÇİ ECZANE OTOMATİK — ÇALIŞIYOR (21.11.2026: SQL, secret, dry-run ve gerçek çalıştırma yeşil; kullanıcı kararı; izin e-postası da önerildi, oda: yonetim@balikesireczaciodasi.org.tr):
  - Kaynak: https://www.balikesireczaciodasi.org.tr/nobetci-eczaneler . GET sayfası yalnız bugünü gösterir AMA sayfadaki form POST ile her günü verir: tarih1=YYYY-MM-DD, ilce=1356 (ERDEK), gnr=" NÖBETLERİ GÖSTER ". Sonuç kartları: class "nobet-kart", h4 "DD.MM.YYYY / ERDEK<br><strong>AD</strong>", fa-home adres, tel:, google maps?q=lat,lng. Oda listeyi önceden yayınlıyor (21.11'de 31.12'ye kadar dolu, Ocak boş). robots.txt izin veriyor; ayrı kullanım koşulu yok.
  - scripts/fetch_pharmacy_duty.py: bugün + 45 gün (1,5 sn arayla), get_content ile mevcut belgeyi okur, birleştirir (eczaneyi telefon/ad ile eşler, panelde düzeltilen ad/adres korunur, yalnız eksik konum tamamlanır; boş günlerde elle kayıt korunur; 60 günden eski nöbet atılır; isSample belge sıfırlanır), şemayla doğrular, sync_pharmacy_duty RPC ile yazar. --dry-run, --self-test (fixture scripts/fixtures/eczaci_odasi_ornek.html; data-validate.yml'de de çalışır). Notlar ("GECE 22:00'A KADAR") şimdilik yalnız loglanır, uygulamada gösterilmiyor.
  - supabase/migrations/0004_pharmacy_sync.sql: automation_tokens (yalnız SHA-256 özet, RLS kapalı-erişim), create_automation_token(name) (yalnız SQL Editor), sync_pharmacy_duty(p_token, p_doc) security definer, yalnız 'pharmacy' belgesi. Secret key YOK.
  - .github/workflows/pharmacy-sync.yml: her gün 07:41 ve 18:23 TSİ + elle (dry_run seçeneği). Secrets: SUPABASE_URL, SUPABASE_ANON_KEY, PHARMACY_SYNC_TOKEN (YENİ).
  - Menüdeki "Veri kaynakları" metni güncellendi (Eczacı Odası, otomatik). Oda logosu / "resmi" ibaresi YOK.
- İŞLETME EKLEME / ÜYELİK: ERTELENDİ (ilk sürüm sorunsuz çıksın). Yapılırsa: girişsiz "İşletmeni ekle" (e-posta + WhatsApp + panele düşen başvuru, admin onayı); uygulamada FİYAT/PAKET/ÖDEME bağlantısı YOK (Apple 3.1.3(g): aynı uygulamada gösterilecek reklam alımı IAP ister); ücret uygulama dışında.
- ÖZELLİK ADAYLARI (21.11.2026 listesi, kullanıcı seçecek): A) ilk sürüm öncesi: 1 Ayarlar/Hakkında (tema, bildirim, "resmi değil", kaynaklar, gizlilik/koşullar, sürüm), 2 nöbet notlarını eczane kartında göster ("22:00'a kadar"), 3 yarının nöbetçisi + 7 günlük liste, 4 "bugünkü son sefer" uyarısı, 5 paylaş + puanla (SKStoreReview), 6 "hata bildir" (mailto, adres gerekli). B) 1.1: 7 kilit ekranı widget'ı, 8 favoriler (cihazda), 9 Pazar Günleri + Etkinlikler sayfaları (panelden), 10 Ramazan sayfası (2027 Şubat), 11 hava 3–5 gün + rüzgar + deniz suyu (MET Norway), 12 İngilizce arayüz. C) sonra: 13 FCM bildirim, 14 konum (kıble/yakın eczane — ilk sürümde "konum yok" korunuyor), 15 işletme/üyelik, 16 Siri/Kısayollar. Önerilen ilk sürüm: 1, 2, 3.
- AŞAMA 1 (21.11.2026, yazıldı):
  - Ayarlar ve Hakkında (lib/features/settings/presentation/settings_screen.dart; ☰ menüden): Görünüm, Bildirimler (vakit bildirim ayarı), Destek (Hata bildir, Uygulamayı paylaş, [App Store kimliği varsa] Değerlendir), Hakkında (resmi değil notu, veri kaynakları, Gizlilik Politikası, Kullanım Koşulları, sürüm). ☰ menüde veri kaynakları kutusu kaldırıldı; yerine Ayarlar / Paylaş / Hata bildir satırları. Tema seçici menüde de duruyor.
  - Yasal sayfalar: docs/legal/gizlilik.html, kullanim-kosullari.html → Pages /legal/ (build_pages.sh zaten kopyalıyor). Uygulamadaki bağlantılar Env.dataBaseUrl + /legal/...; App Store'daki gizlilik URL'si de bu.
  - lib/app/app_info.dart: supportEmail hello@erdeksehirrehberi.com.tr, appStoreId (BOŞ — kullanıcıdan Apple Kimliği bekleniyor; boşken paylaşımda Pages adresi, Değerlendir gizli).
  - Yerel köprü: MethodChannel 'erdek/system' (AppDelegate.swift: share → UIActivityViewController, requestReview → SKStoreReviewController, appVersion → "1.0.0 (N)"); Dart: core/system/system_bridge.dart (Noop testlerde, Channel main'de). Paket EKLENMEDİ.
  - Puanlama penceresi: core/settings/usage_store.dart (Hive: usage_launch_count, usage_first_launch, usage_review_asked); en az 5. açılış + ilk açılıştan 3 gün; bir kez; tanıtım açılışında sorulmaz; LaunchGate perde kalkınca 4 sn sonra.
  - Hata bildir: Launchers.email (mailto, konu "Erdek Şehir Rehberi – Hata bildirimi: <bölüm>", metinde sürüm). ReportIssueLink ("Bu bilgi yanlış mı? Bildirin") eczane, ulaşım, yer ayrıntısı sayfalarının altında.
  - Nöbet notları: şema duties[].notes {eczaneId: metin} (isteğe bağlı); fetch_pharmacy_duty.py notu düzeltip yazar ("Gece 22:00'a kadar nöbetçidir."); PharmacyDuty.notes, PharmacyData.noteFor; eczane kartında turuncu uyarı kutusu, önümüzdeki günlerde parantez içinde. Panel bir günü düzenlerse o günün notu düşer; ertesi çalıştırmada geri gelir.
  - Eczane sayfası: önümüzdeki 7 gün (önce 6); ilk satır "Yarın · <gün>" vurgulu. Kaynak notu: otomatik Eczacı Odası listesi.
  - Ulaşım: sıradaki sefer kartında "Bugünkü son sefer HH:MM" (son sefer henüz kalkmadıysa) / "Bugünün son seferi".
  - Testler: settings_screen_test (bölümler, paylaş, puanlama zamanı), pharmacy/transport testleri güncellendi; fixture pharmacy.json'da 21.11 notu. Golden 13_ayarlar.
- TestFlight geri bildirimi 3 (21.11.2026 akşam):
  - Vakit bildirimleri sayfası (alt pencere): görünür "Kapat" düğmesi (Key notification_sheet_close) + useSafeArea.
  - Yazı boyutları küçültüldü: sectionTitle 20→17 (tüm bölüm başlıkları), "Tümünü Gör" caption 13 w500 + ok 16, tileLabel 13→12 (8 beyaz kutucuk), arama kutusu metni 13.5 + ikon 20.
  - Ana sayfadaki renkli kısayollar 3 → 2: Nöbetçi Eczane + Feribot Saatleri (Namaz Vakitleri çıkarıldı; alt sekmede ve kutucuklarda var). "Tüm Hizmetler" sayfasında da 2 sütun.
  - İNGİLİZCE (Aşama 3'ten öne alındı): lib/l10n/app_en.arb (tüm 218 metin). VARSAYILAN TÜRKÇE, telefon dilinden BAĞIMSIZ; Ayarlar → Dil (Türkçe / English). core/settings/locale_store.dart (Hive 'app_locale'), localeProvider + LocaleNotifier.setLocale. Bildirim metinleri kayıtlı dilde (dil değişince bir sonraki açılışta). Panelden gelen içerik ve iOS widget metinleri Türkçe kalır. Testler Türkçe (testApp locale tr).
- FIREBASE / ÖNEMLİ DUYURU BİLDİRİMLERİ (21.11.2026, kullanıcı istedi; YAZILDI, kurulum sürüyor):
  - Yalnızca FCM (firebase_core ^5.1.0, firebase_messaging ^17.0.1). Analytics/Crashlytics YOK. Konu (topic): "duyurular". Herkese aynı bildirim; kişiye özel değil.
  - Ayar: lib/app/firebase_config.dart (GoogleService-Info.plist değerleri; gizli değil; boşken Firebase hiç başlamaz). Kullanıcı plist'i config/ klasörüne koyar → Claude değerleri aktarır; plist .gitignore'da.
  - lib/features/push/push_service.dart: FirebasePushService.initialize (ön planda da göster), setAnnouncementsEnabled (izin → setAutoInitEnabled(true) → APNs anahtarını bekle → subscribe/unsubscribe); Hive 'push_announcements'; announcementsPushProvider (+ refresh açılışta LaunchGate'te); pushAvailableProvider (Firebase ayarlıysa true).
  - Varsayılan KAPALI. Ayarlar → Bildirimler → "Önemli duyurular" anahtarı; tanıtımın 3. sayfasında da ikinci anahtar. Info.plist FirebaseMessagingAutoInitEnabled=false (açılmadan kimlik üretilmez).
  - iOS: Runner.entitlements aps-environment=production; AppDelegate'te FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate çalışma anında (NSClassFromString) çağrılır. Fastfile certificates lane: match force:true (Push yetkisiyle profil yeniden üretimi için ios-signing-setup tekrar çalıştırılmalı).
  - Apple: App ID'de Push Notifications açık; APNs anahtarı (.p8, "Erdek APNs", Sandbox & Production) Firebase'e yüklendi (kullanıcı yapar).
  - Gönderme (şimdilik): Firebase konsolu → Messaging → yeni kampanya → Hedef: Konu "duyurular". Panelden gönderme SONRA (Supabase Edge Function + servis hesabı).
  - Gizlilik politikası güncellendi. App Store "App Privacy": Identifiers → Device ID (Uygulama İşlevselliği, kullanıcıyla ilişkilendirilmez, izleme yok) eklenecek.
- İŞLETMELER + SOSYAL MEDYA + HAVA TAHMİNİ + PANEL TASARIMI (21.11.2026 gece, kullanıcı istedi; YAZILDI):
  - İşletmeler: data/businesses.json {categories:[{id,title,icon}], businesses:[{id,name,categoryId, summary?, description?, phone?, whatsapp?, address?, latitude?, longitude?, website?, instagram?, hours?, photos?}]}. Kategoriler panelden eklenir/sıralanır; ikon anahtarları food/cafe/hotel/market/shopping/service/car/health/beauty/other. Uygulamada yalnızca BOŞ OLMAYAN kategoriler filtre hapı olur. Uygulamayla gelen kopyada 8 varsayılan kategori, işletme YOK (uydurma işletme eklenmez). Ekranlar: lib/features/businesses (liste + ayrıntı: ara, WhatsApp wa.me, web, Instagram, yol tarifi, çalışma saatleri, fotoğraflar). Giriş: ana sayfa Keşfet (2×2) ve ☰ menü. Ücret/ödeme bağlantısı YOK (Apple 3.1.3). İşletme başvuru/üyelik formu YOK (ertelendi); işletmeleri admin ekler.
  - Sosyal medya: data/social.json {instagram?, facebook?, x?} (yalnızca https). Uygulamada ☰ menünün en altında ve Ayarlar → "Bizi takip edin" (boşsa gizli).
  - Supabase: 0005_businesses_social.sql (content_docs id listesine businesses, social). Fotoğraflar content-images/businesses/.
  - Hava: MET Norway compact ~10 gün veriyor → DailyForecast.fromMetTimeseries (Erdek günü UTC+3; min/maks, yerel öğlene en yakın simge, yağış mm, en yüksek rüzgâr). Sayfa: lib/features/weather/presentation/weather_screen.dart; hero sıcaklığına dokununca ve Keşfet kartından açılır. 15 GÜN İSTENDİ ama ücretsiz ve ticari kullanıma izin veren kaynak (MET) en çok ~10 gün veriyor; 15 gün için ücretli kaynak gerekir (Open-Meteo ticari abonelik vb.) — kullanıcı karar verecek.
  - Panel tasarımı: admin/lib/theme.dart (lacivert/mavi/turuncu), gruplu kenar çubuğu (Genel: Reklamlar, Duyurular, Sosyal Medya · Şehir Rehberi: Nöbetçi Eczane, Telefonlar, Ulaşım · Keşfet: İşletmeler, Gezilecek Yerler, Erdek Tarihi), logolu giriş, dar ekranda menü. Ortak fotoğraf şeridi admin/lib/content/photo_strip.dart.
  - Testler: businesses_test, weather_forecast_test, data_files_test (+2). Golden 14_isletmeler, 15_hava_durumu.
- 8 ÖZELLİK (21.11.2026 gece, kullanıcı hepsini istedi) — aşamalı:
  - AŞAMA 1 (YAZILDI): (a) Paylaş: eczane kartında yeşil WhatsApp düğmesi (wa.me/?text=; WhatsApp yoksa iOS paylaşım penceresi), metin: gün + ad + adres + tel + not + Apple Haritalar bağlantısı + "— Erdek Şehir Rehberi". Sefer satırına dokununca alt pencere: hatırlat / WhatsApp / diğer. lib/features/share/share_actions.dart. (b) Feribot/otobüs hatırlatıcısı: sefer satırında zil; kalkıştan 30 dk önce yerel bildirim; Hive 'departure_reminders'; geçmişler açılışta düşer. lib/features/reminders/. (c) Ramazan sayfası: lib/features/ramadan/ (2027: ilk oruç 8 Şubat, son 8 Mart, Kadir 5 Mart, Bayram 9 Mart — Diyanet; her yıl ramadanPeriods'a eklenir). Ramazan'a kalan gün / sahur–iftar geri sayımı, önemli günler, iftar bildirimi (varsayılan kapalı, Hive 'iftar_notifications', en fazla 7 gün önceden), Ramazan imsakiyesi (vakit verisi geldikçe dolar). Giriş: Vakitler sekmesinde kart + ☰ menü (başlangıçtan 90 gün önce → bayram).
  - Bildirim kimlikleri: vakit < 1e9 (en fazla 48), iftar 1.1e9+, sefer 1.5e9–2e9. Vakit bildirimleri yeniden kurulurken artık cancelAll DEĞİL, yalnızca vakit kimlikleri silinir.
  - AŞAMA 2 (YAZILDI): (a) Widget'lar: ios/ErdekWidget artık WidgetBundle — "Erdek Rehberi" (vakit; küçük/orta + kilit ekranı dikdörtgen/yuvarlak/satır), "Nöbetçi Eczane" (küçük + kilit dikdörtgen/satır), "Sıradaki Sefer" (önce feribot, yoksa otobüs; küçük + kilit dikdörtgen/satır). Veri: HomeWidgetSync snapshot version 2 + departures [{mode, route, at}] (bugün+yarın, en fazla 40). (b) Panel → Bildirim Gönder (önizleme + onay + son gönderilenler) ve Duyurular'da her duyurunun yanında ✈ "bildirim olarak gönder". Sunucu: supabase/functions/send-push (admin kontrolü is_admin, FCM HTTP v1, konu "duyurular", 24 saatte en fazla 10, push_log tablosu 0006). Firebase servis hesabı JSON → Supabase secret FIREBASE_SERVICE_ACCOUNT (kurulum docs/BILDIRIM_GONDER.md).
  - AŞAMA 3 (YAZILDI): (a) Yakınımdakiler: konum YALNIZCA bu sayfa açılınca istenir (AppDelegate 'erdek/location' kanalı, CoreLocation, paket yok); konum telefonda kalır. Bugünün nöbetçi eczaneleri + işletmeler + gezilecek yerler, haversine ile yakından uzağa; konumu olmayanlar sonda. Info.plist NSLocationWhenInUseUsageDescription eklendi; gizlilik politikasına "Konum" bölümü eklendi. App Store App Privacy: konum TOPLANMIYOR (cihazda işlenir). (b) Erdek haritası: Apple MapKit platform view ('erdek/map', AppDelegate içinde; iğne renkleri eczane kırmızı/işletme turuncu/yer mavi; balondaki (i) → ayrıntı). Süzgeç hapları; iOS dışında (testler) liste. Giriş: ana sayfa Keşfet 3. satır + ☰ menü.
  - DENİZ BİLGİSİ (YAZILDI): Copernicus Marine — su sıcaklığı: cmems_mod_blk_phy-tem_anfc_mrm-500m_P1D-m (Karadeniz modelinin Marmara 500 m alt alanı, thetao, yüzey); dalga: cmems_mod_glo_wav_anfc_0.083deg_PT3H-i (VHM0; Karadeniz dalga modeli 40.5°K'nin kuzeyini kapsadığı için Erdek dışında kalıyor → küresel model). Hedef 40.40K 27.78D, en yakın deniz hücresi. scripts/fetch_sea.py + _tasinacak/sea-sync.yml (her gün 07:23 TSİ, data/sea.json commit + Pages). Secrets: COPERNICUSMARINE_SERVICE_USERNAME / _PASSWORD. Uygulamada Hava Durumu sayfasında "Deniz" bölümü + zorunlu atıf "E.U. Copernicus Marine Service Information". MET Norway Oceanforecast Marmara'yı KAPSAMIYOR.
- HAVA/DENİZ/RÜZGÂR + HİKÂYELER (22.11.2026, kullanıcı istedi; YAZILDI):
  - Hava Durumu sayfası 3 sekme (SegmentedPills): Hava · Deniz · Rüzgâr. MET Norway artık locationforecast/2.0/COMPLETE (hamle wind_speed_of_gust için; yanıt biçimi aynı). CurrentWeather: windGustMs, windFromDegrees, hourly (25 saat); DailyForecast: maxWindGustMs, windFromDegrees (en kuvvetli rüzgârın yönü). Rüzgâr sekmesi: büyük kart (ok, km/s, Beaufort adı + bofor, "Kuzeydoğu (Poyraz) yönünden", hamle), saatlik yatay liste, günlük en kuvvetli rüzgâr. Yön adları 8 dilim + geleneksel Marmara rüzgâr adları (Yıldız, Poyraz, Gündoğusu, Keşişleme, Kıble, Lodos, Günbatısı, Karayel). Ok = estiği yön (geldiği yön + 180°). Deniz sekmesi veri yoksa "Deniz bilgisi hazırlanıyor".
  - Hikâyeler: data/stories.json {stories:[{id,title(≤24),cover,slides:[{url,caption?,link?(https),linkLabel?}],startsAt?,endsAt?}]}; Supabase 0007_stories.sql; panel → Hikâyeler (kapak + fotoğraf yükleme content-images/stories/, sıralama, yayın tarihleri, uygulama önizlemesi). Uygulama: ana sayfada Hızlı İşlemler'in ÜSTÜNDE yuvarlak şerit (başlık yuvarlağın ALTINDA; izlenmemiş = turuncu-pembe-mor halka, izlenmiş = gri; izlenmemişler önde). Tam ekran izleyici: ilerleme çubukları, 6 sn/sayfa, sağa dokun sonraki, sola önceki, basılı tut durdur, aşağı kaydır kapat, yana kaydır hikâye değiştir, alt yazı + bağlantı düğmesi. İzlenenler Hive 'stories_seen' (id:sayfaSayısı; sayfa eklenince yeniden "yeni").
- ANA SAYFA ARKA PLAN FOTOĞRAFI panelden (22.11.2026; YAZILDI): data/appearance.json {heroImages:[{url, credit?}]}; Supabase 0008_appearance.sql; panel → Genel → Görünüm (yükleme content-images/appearance/, sıralama, uygulama önizlemesi). Uygulama: HeroHeader.imageUrl — uygulamayla gelen hero_erdek.jpg her zaman altta, panel fotoğrafı inince üstünde belirir (inemezse/çevrimdışıysa gömülü fotoğraf kalır). Birden fazla fotoğraf → yılın gününe göre her gün sıradaki.
- SIRADAKİ:
  1. CI yeşil + 0003 SQL çalıştırıldı → panelden bir yere fotoğraf ekle + Kaydet → ios-release ile yeni derleme → TestFlight'ta açılış/tanıtım denemesi (tanıtımı yeniden görmek için uygulamayı silip kur). Sonra kalan kontroller: reklam, widget, panelden gelen içerikler. (TestFlight: Internal Testing grubu "Ben" kuruldu.)
  2. 14. adım App Store hazırlığı: ekran görüntüleri (golden 6.9" 1320×2868 tabanlı), açıklama/anahtar kelimeler/kategori, gizlilik politikası + kullanım koşulları (docs/legal → Pages /legal/), App Privacy formu (konum yok, takip yok; reklam sayımı anonim), destek URL'si, yaş derecelendirmesi, hero fotoğrafı kullanım hakkı teyidi, "resmi değil" ibaresi.
  3. Gerçek veriler panelden girilecek (telefonlar, eczane nöbetleri, şehir içi hatlar, gezilecek yerler, tarih).
  4. Ertelenenler: Firebase (Crashlytics + FCM, admin'den bildirim), Diyanet API'ye geçiş.

## Kullanıcıdan beklenen gerçek veriler
- Gestaş tarifesinin gerçek geçerlilik tarihleri ve telefonu.
- Erdek–Bandırma, Erdek–Balıkesir otobüs saatleri.
- Balıkesir Büyükşehir Erdek içi mahalle hatları (hat adı, mahalleler, saatler, gün tipleri).
- Önemli telefonlar, duyurular. (Nöbetçi eczane artık otomatik.)
- Gezilecek yerlerin ve Erdek tarihinin gerçek metinleri; kullanım hakkı olan fotoğraflar (artık panelden yüklenebilir).

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
- Logo: 21.11.2026 16:00'da KESİNLEŞTİ (renkli amblem; assets/images/logo_*.png). logo.svg ve altın logo kullanılmıyor. Hero fotoğrafının kullanım hakkı App Store öncesi teyit edilmeli.

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
- Cihazlar: iPhone SE 375×667@2, iPhone 16 Pro Max 440×956@3. Dosyalar 01–12.
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

## Acil Durum sayfası (r23)
- Ana sayfadaki "Acil" kutucuğu artık doğrudan 112'yi aramıyor; **Acil Durum** sayfasını açıyor (menüde de var).
- 112 büyük kırmızı düğme. 110/155/156/158/177/122'nin 112'ye bağlandığı notu (İçişleri Bakanlığı, 81 il).
- Ulusal hatlar koda gömülü (internetsiz): 114 Zehir Danışma, 184 SABİM, 183 Sosyal Destek, 185 Su arıza, 186 Elektrik arıza, 187 Doğal gaz.
- "Erdek'teki numaralar": Rehberin `acil` ve `kamu` kategorileri (panelden düzenlenir).
- "Konumumu bul": koordinat (112'ye okunur), WhatsApp / paylaş / kopyala. Harita bağlantısı Google Haritalar (karşı taraf Android de olabilir). Konum kaydedilmez; gizlilik metni güncellendi.
- e-Devlet AFAD toplanma alanı sorgulama bağlantısı.

## Favoriler (r24)
- İşletme, gezilecek yer ve eczane sayfalarında ☆ düğmesi; "Favorilerim" sayfası menüde.
- Cihazda saklanır (Hive, anahtar `favorites`), en yeni başta, en fazla 100. Sunucuya gönderilmez.
- Eczane favorisi bugün nöbetçiyse "Bugün nöbetçi" yazar; değilse adres.
- Panelden silinen yer listede görünmez (kayıt cihazda kalır, geri gelirse görünür).

## Arama genişletildi (r25)
- Yeni bölümler: **Sayfalar** (anahtar kelimeyle: "poyraz" → Rüzgâr, "iftar" → Ramazan, "avşa" → Feribot, "deprem" → Acil Durum…), **Acil ve önemli hatlar** (112 + ulusal hatlar, internetsiz), **İşletmeler** (ad, kategori, özet, açıklama, adres).
- Boş arama ekranında **Son aramalar** (cihazda, en fazla 8, Temizle) ve **Öneriler**.
- Bir sonuca dokununca ya da klavyede Ara'ya basınca sorgu son aramalara eklenir.
- Sayfa anahtar kelimeleri `SearchPage` (lib/features/search/domain/search_index.dart) içinde; yeni kelime eklemek için oraya yazılır.

## Bildirim konuları (r26)
- 4 FCM konusu: `duyurular` (Önemli duyurular, eski aboneler korunur), `kesintiler`, `ulasim`, `etkinlikler`.
- Uygulama: Ayarlar › Bildirim konuları (her biri ayrı anahtar). Eski sürümde "Önemli duyurular" açık olanlarda yeni konular da açık başlar; açılışta açık konulara abonelik tazelenir.
- Panel: Bildirim Gönder'de konu seçimi; Duyurular ✈ türüne göre konu seçer. send-push yalnızca bu 4 konuyu kabul eder, push_log.topic'e yazar. Günlük sınır tüm konular için toplam 10.

## Etkinlik takvimi (r28)
- Yeni içerik belgesi `events` (data/events.json, panel → Genel › Etkinlikler, SQL: 0009_events.sql). Fotoğraflar content-images/events/.
- Alanlar: başlık, tür (konser/festival/kultur/spor/cocuk/pazar/diger), tarih, son gün (çok günlü), başlangıç/bitiş saati (boşsa tüm gün), yer, enlem/boylam, kısa tanım, açıklama, düzenleyen, bağlantı (https), fotoğraflar.
- Uygulama: Etkinlikler sayfası (ana sayfadaki Etkinlik kutucuğu, menü, arama). Güne göre gruplu; süren çok günlü etkinlik "bugün" altında, "Şimdi sürüyor". Bitenler kendiliğinden kalkar.
- Ayrıntı: Takvime ekle (iOS EKEventEditViewController; iOS 17+ izin istemez, eskide bir kez takvim izni — Info.plist NSCalendars…), Hatırlat (2 saat önce; tüm gün ise 09:00; bildirim kimlikleri 2.000.000.000–2.099.999.999), Yol tarifi, WhatsApp'ta paylaş, bilet/ayrıntı bağlantısı.
- Etkinlik duyuruları (Duyurular › Etkinlik) yerinde kalır; Etkinlikler sayfasının altından ulaşılır.

## Kesintiler (r30)
- Yeni içerik belgesi `outages` (data/outages.json, panel → Şehir Rehberi › Kesintiler, SQL: 0010_outages.sql).
- Panel: mahalle listesi (her satıra bir) + kesintiler: tür (su/elektrik/dogalgaz/yol/diger), mahalleler (virgülle; boş = tüm Erdek), başlangıç, bitiş (boş = "giderilene kadar", uygulama 12 saat sonra kaldırır), sebep, kaynak, not. ✈ → "Kesintiler" konusuna bildirim.
- Uygulama: Kesintiler sayfası (Şu an süren / Planlı), ana sayfada uyarı şeridi (süren ya da 24 saat içinde başlayacak; Mahallem öncelikli), menü, arama ("su", "elektrik", "arıza"…). Ana sayfa "Kesinti" kutucuğu bu sayfayı açar; kesinti duyuruları sayfanın altından.
- Mahallem: cihazda (`my_area`). Mahalle eşleştirmesi "Mah./Mahallesi", büyük-küçük ve Türkçe harf farkına bakmaz.
- "Mahallemdeki kesintileri hatırlat": başlamadan 1 saat önce yerel bildirim (en fazla 10; kimlikler 2.100.000.000–2.100.000.999). Veri, mahalle ya da ayar değişince ve uygulama öne gelince yeniden kurulur.

## Plajlar ve yüzme puanı (r31)
- Plajlar = gezilecek yerlerde türü "plaj" olanlar. Yeni alan `amenities` (mavi_bayrak, cankurtaran, dus, wc, sezlong, otopark, engelli, sig, kum, cakil, restoran); panel → Gezilecek Yerler formunda çoklu seçim (form_kit: FieldKind.multiChoice).
- "Bugün denize girilir mi?" puanı (0–100): su sıcaklığı, hava (anlık/bugünkü en yüksek), dalga (Copernicus), rüzgâr, yağış/fırtına. ≥75 Harika, ≥55 Girilir, ≥35 İdare eder, altı Uygun değil. Kabaca; plaj uyarılarına uyulması notu.
- Görünür: Plajlar sayfası (menü, arama "plaj/yüzme/mavi bayrak", Hava › Deniz sekmesi), plaj ayrıntı sayfası.
