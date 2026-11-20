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

## prayer_times.json — Namaz vakitleri

**Elle düzenleme.** 6. adımda kurulacak haftalık otomatik görev bu dosyayı
Diyanet'in resmi servisinden günceller. Şimdiki içerik örnek saatlerdir.
