#!/usr/bin/env bash
# GitHub Pages için statik siteyi derler. Kullanım: bash scripts/build_pages.sh _site
set -euo pipefail

OUT="${1:-_site}"
REPO_NAME="${GITHUB_REPOSITORY#*/}"
REPO_NAME="${REPO_NAME:-erdek-sehir-rehberi}"

rm -rf "$OUT"
mkdir -p "$OUT"
touch "$OUT/.nojekyll"

# 1) Uzaktan JSON verileri
if [ -d data ]; then
  mkdir -p "$OUT/data"
  # README gibi dosyaları değil, yalnızca JSON'ları yayınla
  (cd data && find . -name '*.json' -print0 | xargs -0 -I{} cp --parents {} "../$OUT/data/")
fi

# 2) Yasal sayfalar (HTML)
if [ -d docs/legal ]; then
  mkdir -p "$OUT/legal"
  cp -r docs/legal/. "$OUT/legal/"
fi

# 3) Admin paneli (Flutter Web) — 9. adımda eklenecek
if [ -f admin/pubspec.yaml ]; then
  (
    cd admin
    flutter pub get
    flutter build web --release --base-href "/${REPO_NAME}/admin/"
  )
  mkdir -p "$OUT/admin"
  cp -r admin/build/web/. "$OUT/admin/"
fi

# 4) Basit kök sayfa
cat > "$OUT/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Erdek Şehir Rehberi</title>
  <style>
    body { font-family: -apple-system, system-ui, sans-serif; max-width: 640px;
           margin: 48px auto; padding: 0 20px; line-height: 1.6; color: #1b2a33; }
    a { color: #0a6b8f; }
  </style>
</head>
<body>
  <h1>Erdek Şehir Rehberi</h1>
  <p>Erdek için bağımsız şehir rehberi uygulaması. Resmi bir kurumla bağlantısı yoktur.</p>
  <ul>
    <li><a href="legal/gizlilik.html">Gizlilik Politikası</a></li>
    <li><a href="legal/kullanim-kosullari.html">Kullanım Koşulları</a></li>
  </ul>
</body>
</html>
HTML

echo "Site hazır: $OUT"
find "$OUT" -maxdepth 3 -type f | sort
