# Panelden bildirim gönderme — kurulum (bir kez)

Panel → **Bildirim Gönder** (ve Duyurular'daki ✈ düğmesi), uygulamada
"Önemli duyurular"ı açan herkese anlık bildirim gönderir. Gönderimi
Supabase'teki `send-push` fonksiyonu yapar; Firebase anahtarı yalnızca
Supabase'in gizli ayarlarında (Secrets) durur.

> ⚠️ Firebase anahtar dosyasını (.json) ve içeriğini **hiçbir yere yapıştırmayın**
> (sohbet, e-posta, GitHub). Yalnızca 3. adımdaki Supabase alanına.

## 1. Kayıt tablosu
Supabase → **SQL Editor** → **New query** → `supabase/migrations/0006_push_log.sql`
dosyasının tamamını yapıştır → **Run**.

## 2. Firebase servis hesabı anahtarı
Firebase konsolu → proje **erdek-sehir-rehberi** → sol üst ⚙ → **Project settings**
→ **Service accounts** sekmesi → **Generate new private key** → **Generate key**.
Bilgisayara bir `.json` dosyası iner.

## 3. Anahtarı Supabase'e gizli ayar olarak ekle
Supabase → sol menü **Edge Functions** → **Secrets** →
- Name: `FIREBASE_SERVICE_ACCOUNT`
- Value: indirilen `.json` dosyasını Not Defteri ile aç → **Ctrl+A**, **Ctrl+C** → buraya **Ctrl+V**
→ **Save**. Sonra `.json` dosyasını güvenli bir yere taşı ya da sil.

## 4. Fonksiyonu yükle
Supabase → **Edge Functions** → **Deploy a new function** → **Via Editor**
- Function name: `send-push`
- Editördeki örnek kodu sil, `supabase/functions/send-push/index.ts` dosyasının
  tamamını yapıştır → **Deploy function**.
- "Verify JWT" (JWT doğrulama) **açık** kalmalı.

## 5. Dene
Panel → **Bildirim Gönder** → başlık + metin → **Gönder** → onay.
Telefonda Ayarlar → **Önemli duyurular** açık olmalı.

### Sorun çıkarsa
- "send-push fonksiyonu kurulmamış" → 4. adım.
- "FIREBASE_SERVICE_ACCOUNT tanımlı değil" → 3. adım (ad birebir aynı olmalı).
- "Firebase reddetti: ... API has not been used" → Firebase'de Cloud Messaging API (V1)
  kapalı: Project settings → Cloud Messaging → "Firebase Cloud Messaging API (V1)" → Enable.
- Günlük sınır: 24 saatte en fazla 10 bildirim (kullanıcılar bildirimleri kapatmasın diye).
