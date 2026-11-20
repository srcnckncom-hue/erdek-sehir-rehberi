# Erdek Şehir Rehberi

Balıkesir / Erdek için bağımsız şehir rehberi iOS uygulaması (Flutter).
Resmi bir kurumla bağlantısı yoktur.

Kurulum ve tarayıcıdan yapılacak adımlar: [docs/SETUP.md](docs/SETUP.md)

## Klasörler

| Yol | İçerik |
|---|---|
| `lib/` | Flutter uygulaması (`core/theme`, `core/widgets`, `features/*/{data,domain,presentation}`) |
| `packages/erdek_ui/` | Uygulama ve admin panelinin ortak tasarım sistemi (3. adım) |
| `admin/` | Reklam yönetim paneli, Flutter Web (9. adım) |
| `ios/` | iOS projesi + `ErdekWidget/` (WidgetKit) |
| `data/` | GitHub Pages'te yayınlanan JSON veriler |
| `supabase/migrations/` | Reklam sistemi şeması ve RLS |
| `fastlane/` | İmzalama, TestFlight, App Store metadata |
| `scripts/` | CI yardımcı scriptleri |
| `test/goldens/` | Golden testler / ekran görüntüleri |
| `design/` | Referans tasarım görselleri (kodda kullanılmaz) |
| `docs/` | Kurulum notları, yasal sayfalar |

## Workflow'lar

| Dosya | Ne zaman | Runner |
|---|---|---|
| `ios-ci.yml` | Her push/PR | Linux (test) + macOS (imzasız build) |
| `bootstrap-ios.yml` | Bir kez, elle | Linux |
| `pages-deploy.yml` | data/, docs/legal, admin/ değişince | Linux |

## Veri kaynakları ve atıflar

- Hava durumu: MET Norway (api.met.no), CC BY 4.0
- Namaz vakitleri: Diyanet İşleri Başkanlığı Awqat Salah API (cron ile)
- Nöbetçi eczane, ulaşım, telefonlar, duyurular: elle derlenen JSON (`data/`)
