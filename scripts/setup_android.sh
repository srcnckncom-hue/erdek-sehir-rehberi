#!/usr/bin/env bash
# Android derlemesi için eksik Gradle dosyalarını kurulu Flutter sürümüyle üretir.
# Repoda yalnızca bize özel dosyalar var (Kotlin kodu, manifest, ikonlar, erdek.gradle);
# gerisi (Gradle sarmalayıcı, settings/build.gradle.kts) burada oluşturulur ve
# repodaki dosyaların ÜZERİNE YAZILMAZ.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp="$(mktemp -d)"
flutter create --platforms=android --org com.erdek.sehirrehberi --project-name erdek_rehberi "$tmp/gen" >/dev/null
cp -rn "$tmp/gen/android/." android/
rm -rf "$tmp"

# Şablonun ürettiği varsayılan MainActivity (farklı paket) bizimkiyle çakışmasın.
rm -rf android/app/src/main/kotlin/com/erdek/sehirrehberi/erdek_rehberi

grep -q 'erdek.gradle' android/app/build.gradle.kts || printf '\napply(from = "erdek.gradle")\n' >> android/app/build.gradle.kts
echo "Android projesi hazır."
