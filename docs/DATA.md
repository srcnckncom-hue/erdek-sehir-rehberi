# Veri dosyaları nasıl güncellenir?

Uygulamadaki eczane, ulaşım, telefon ve duyuru bilgileri `data/` klasöründeki
JSON dosyalarından gelir. Dosyayı düzenleyip **commit + push** yaptığında:

1. **data-validate** dosyayı kontrol eder (yazım hatası, eksik alan, tanımsız eczane vb.).
2. **pages-deploy** yayınlar. Birkaç dakika içinde uygulamalar yeni veriyi görür.
   Yeni uygulama sürümü gerekmez.

Hata varsa Actions'ta kırmızı X çıkar ve log'da Türkçe açıklama yazar. Bu durumda
hatalı veri **yayınlanmaz**, uygulama eski bilgiyle çalışmaya devam eder.

> Dosyaları Windows'ta **Not Defteri** ya da **VS Code** ile açabilirsin.
> Kaydederken kodlama **UTF-8** olmalı (Türkçe karakterler için).

## Ortak kurallar

- Her dosyanın başında `"isSample": true` var. Gerçek veriyi girdiğinde **`false`** yap.
  `true` kaldıkça uygulamada "ÖRNEK VERİ" uyarısı görünür.
- `"updatedAt"` alanına güncellediğin anı yaz: `"2026-12-01T10:00:00+03:00"`
- Tarih biçimi: `"2026-12-01"` · Saat biçimi: `"08:30"` (24 saat, başında sıfır)
- Telefon: boşluksuz, `+90` ile 10 hane → `"+902665551234"`. Kısa numaralar olduğu gibi: `"112"`
- Son öğeden sonra virgül **olmaz**.

## pharmacy.json — Nöbetçi eczane

> **Otomatik:** `pharmacy-sync` görevi her gün Balıkesir Eczacı Odası nöbet
> listesinden Erdek'i okur (bugün + 45 gün) ve paneldeki eczane belgesine yazar
> (`scripts/fetch_pharmacy_duty.py`, `supabase/migrations/0004_pharmacy_sync.sql`).
> Yeni eczaneyi kendisi ekler; panelden düzeltilen ad/adres korunur. Listede
> olmayan günlere elle girilen nöbet de korunur. Bu dosya yalnızca yedek kopyadır.

```json
"pharmacies": [
  { "id": "merkez", "name": "Merkez Eczanesi", "address": "...", "phone": "+902660000000",
    "lat": 40.3990, "lng": 27.7930 }
],
"duties": [
  { "date": "2026-12-01", "pharmacyIds": ["merkez"] }
]
```

- `id`: kısa, Türkçe karaktersiz, boşluksuz bir ad. Nöbet listesinde bununla anılır.
- `lat` / `lng` opsiyonel. "Yol tarifi" butonu bununla çalışır. Google Maps'te eczaneye
  sağ tıklayınca çıkan ilk sayı `lat`, ikincisi `lng`.
- Nöbet günü **08:30'da başlar, ertesi gün 08:30'da biter**. Uygulama gece 00:00–08:30
  arasında bir önceki günün kaydını gösterir; sen yalnızca takvim gününü yaz.
- Aylık listeyi Eczacı Odası'ndan alıp her gün için bir satır ekle.
  Eski günleri silmen gerekmez.

## transport.json — Feribot ve otobüs

Her hat (`routes`) birden fazla tarife dönemi (`timetables`) içerebilir: yaz / kış.

```json
{ "name": "Kış tarifesi", "validFrom": "2026-10-01", "validTo": "2027-05-31",
  "departures": [
    { "time": "09:00" },
    { "time": "16:00", "days": [1,2,3,4,5,6], "note": "Pazar yok" }
  ] }
```

- `days` yazılmazsa sefer **her gün** vardır. 1 = Pazartesi … 7 = Pazar.
- `mode`: feribot için `"ferry"`, otobüs/minibüs için `"bus"`.
- `direction`: Erdek'ten kalkış `"outbound"`, Erdek'e dönüş `"inbound"`. Ana sayfadaki
  "Sıradaki Feribot/Otobüs" kartları yalnızca `outbound` hatları kullanır.
- `arrival` (opsiyonel): varış saati, ör. `{ "time": "11:00", "arrival": "13:00", "note": "Balıklı üzerinden" }`.
- `isSample: true` olan hatta "ÖRNEK VERİ" uyarısı çıkar; gerçek saatleri girince sil.
- Gestaş feribot tarifesi tek bir geminin tur güzergâhıdır; her ada için iki yön
  (Erdek → Ada, Ada → Erdek) ayrı hat olarak yazılır.

## contacts.json — Önemli telefonlar

Kategoriler (`categories`) ve içindeki kişiler (`contacts`): `name`, `phone`, isteğe bağlı `note`.

## announcements.json — Duyurular

```json
{ "id": "su-2026-12-03", "category": "kesinti", "title": "Su kesintisi",
  "body": "Yalı Mahallesi'nde 09:00–14:00 arası.",
  "publishedAt": "2026-12-02T18:00:00+03:00",
  "startsAt": "2026-12-03T09:00:00+03:00", "endsAt": "2026-12-03T14:00:00+03:00" }
```

- `category`: `kesinti`, `pazar`, `etkinlik` veya `genel`.
- `endsAt` geçince duyuru listeden kendiliğinden kalkar. Kalıcı duyuruda yazma.
- `id` her duyuruda farklı olmalı.

## places.json — Gezilecek yerler

```json
{ "id": "zeytinliada", "title": "Zeytinliada", "area": "erdek", "category": "manzara",
  "summary": "Listede görünen 1–2 cümlelik özet.",
  "paragraphs": ["Ayrıntı sayfasındaki 1. paragraf.", "2. paragraf."],
  "tips": ["Kısa pratik bilgi"],
  "address": "isteğe bağlı", "latitude": 40.39, "longitude": 27.79,
  "photos": [{ "url": "https://…/storage/v1/object/public/content-images/places/….jpg",
               "credit": "Fotoğraf sahibi (isteğe bağlı)" }] }
```

- `area`: `erdek` veya `kapidag`.
- `category`: `plaj`, `tarihi`, `doga`, `koy`, `manzara` veya `diger`.
- `tips`, `address`, `latitude`/`longitude` isteğe bağlı. Konum ya da adres varsa "Yol tarifi" düğmesi çıkar. Koordinat yazılacaksa ikisi birlikte yazılır.
- Liste dosyadaki sırayla gösterilir.
- `photos` isteğe bağlı (en çok 10). Panelden yüklenir (Supabase Storage `content-images` kovası, dosya başına en çok 2 MB, JPG/PNG/WEBP). İlki kapak fotoğrafıdır, listede de görünür. `credit` varsa "Fotoğraf: …" olarak yazılır. YALNIZCA kullanım hakkı bize ait / izinli fotoğraflar yüklenir.

## history.json — Erdek tarihi

`intro` (isteğe bağlı giriş metni) ve `sections`: her dönemde `id`, `title`, isteğe bağlı `period` ("MÖ 7. yüzyıl" gibi) ve `paragraphs`. Dönemler dosyadaki sırayla zaman çizelgesi olarak gösterilir.

## prayer_times.json — Namaz vakitleri

**Elle düzenleme.** 6. adımda kurulacak haftalık otomatik görev bu dosyayı
Diyanet'in resmi servisinden günceller. Şimdiki içerik örnek saatlerdir.
