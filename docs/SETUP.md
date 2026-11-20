# Kurulum — Adım 1

Mac gerekmez. Her şey tarayıcı + GitHub Actions ile yapılır.

## 1. GitHub repo'su

1. github.com → **New repository** → ad: `erdek-sehir-rehberi`.
   - **Public** önerilir: ücretsiz planda GitHub Pages yalnızca public repo'da çalışır.
     Repo'da gizli bilgi bulunmaz (hepsi Secrets'ta).
   - Private istersen: GitHub Pro gerekir, ya da data/legal/admin için ayrı public repo açarız.
2. README/.gitignore ekleme seçeneklerini **boş bırak** (bu paket kendi dosyalarını getiriyor).
3. Bu paketteki tüm dosyaları repo'nun köküne koyup `main` branch'ine push'la.
   (Tarayıcıdan: **Add file → Upload files** ile klasörleri sürükle-bırak da olur;
   `.github` gibi noktayla başlayan klasörlerin de yüklendiğinden emin ol.)

## 2. GitHub Pages

1. Repo → **Settings → Pages**.
2. **Build and deployment → Source: GitHub Actions** seç.
3. **Actions → pages-deploy → Run workflow**. Bitince site adresi
   `https://<kullanıcı-adın>.github.io/erdek-sehir-rehberi/` olur.

## 3. iOS projesini üret (bir kez)

1. **Actions → bootstrap-ios → Run workflow**.
2. `bundle_prefix`: ör. `com.ornekad` (uygulama `com.ornekad.erdekrehberi` olur,
   widget ileride `com.ornekad.erdekrehberi.widget`).
   - Apple Developer'da bu ID başka biri tarafından alınmamış olmalı. Ad-soyad
     ya da alan adına dayalı, tamamı küçük harf bir önek seç.
3. `display_name`: ana ekranda ikonun altında görünen kısa ad (varsayılan `Erdek Rehberi`).
   App Store'daki ad yine "Erdek Şehir Rehberi" olacak.
4. Workflow `ios/` klasörünü üretip commit'ler.

## 4. İlk CI

1. **Actions → ios-ci → Run workflow** (bot commit'i otomatik tetiklemez).
2. Beklenen: "Analyze & Test (Linux)" ve "iOS build-check (imzasız, macOS)" yeşil.
3. Kırmızıysa başarısız adımın log'unu kopyalayıp bana yapıştır.
4. Build başarılıysa **Podfile.lock** artifact'ı oluşabilir; varsa indirip
   `ios/Podfile.lock` olarak commit'le.

## Apple Developer / App Store Connect / Supabase

Bu adımda gerek yok. 9. adımda Supabase, 12. adımda Apple tarafı anlatılacak.
