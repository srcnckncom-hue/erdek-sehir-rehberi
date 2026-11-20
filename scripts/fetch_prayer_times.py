#!/usr/bin/env python3
"""Erdek namaz vakitlerini çekip data/prayer_times.json dosyasına yazar.

Uygulama vakit servisini DOĞRUDAN çağırmaz; bu script haftada bir
GitHub Actions'ta (prayer-sync.yml) çalışır ve sonucu GitHub Pages'te yayınlar.

Kaynaklar (PRAYER_SOURCE ortam değişkeni):
  imsakiyem  (varsayılan) ezanvakti.imsakiyem.com — Diyanet verisini yeniden
             yayınlayan ücretsiz, anahtarsız servis. Resmi DEĞİL.
  diyanet    awqatsalah.diyanet.gov.tr resmi API — TODO: hesap açılınca
             AWQAT_USERNAME / AWQAT_PASSWORD secrets ile etkinleştirilecek.

Kapsam: bu ayın 1'inden gelecek ayın son gününe kadar (imsakiye için).

Kullanım: python3 scripts/fetch_prayer_times.py
"""
import datetime as dt
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "data" / "prayer_times.json"
TZ = ZoneInfo("Europe/Istanbul")
KEYS = ["imsak", "gunes", "ogle", "ikindi", "aksam", "yatsi"]

DISTRICT_ID = os.environ.get("PRAYER_DISTRICT_ID", "17881")  # Erdek (Diyanet kimliği)
SOURCE = os.environ.get("PRAYER_SOURCE", "imsakiyem")
USER_AGENT = (
    "ErdekSehirRehberi-prayer-sync/1.0 "
    "(+https://github.com/srcnckncom-hue/erdek-sehir-rehberi)"
)

SOURCE_LABELS = {
    "imsakiyem": "Diyanet İşleri Başkanlığı (ezanvakti.imsakiyem.com üzerinden)",
    "diyanet": "Diyanet İşleri Başkanlığı (Awqat Salah API)",
}


def log(msg: str) -> None:
    print(msg, flush=True)


def window(today: dt.date) -> tuple[dt.date, dt.date]:
    start = today.replace(day=1)
    next_month = (start + dt.timedelta(days=32)).replace(day=1)
    end = (next_month + dt.timedelta(days=32)).replace(day=1) - dt.timedelta(days=1)
    return start, end


def http_get_json(url: str) -> dict:
    last_error = None
    for attempt in range(1, 5):
        req = urllib.request.Request(
            url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"}
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            last_error = e
            wait = 90 if e.code == 429 else 5 * attempt
            log(f"  HTTP {e.code} (deneme {attempt}/4), {wait} sn bekleniyor…")
            time.sleep(wait)
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
            last_error = e
            log(f"  Hata: {e} (deneme {attempt}/4)")
            time.sleep(5 * attempt)
    raise SystemExit(f"Vakit servisine ulaşılamadı: {last_error}")


def fetch_imsakiyem(start: dt.date, end: dt.date) -> list[dict]:
    query = urllib.parse.urlencode(
        {"startDate": start.isoformat(), "endDate": end.isoformat(), "limit": 100}
    )
    url = f"https://ezanvakti.imsakiyem.com/api/prayer-times/{DISTRICT_ID}/range?{query}"
    log(f"İstek: {url}")
    body = http_get_json(url)
    if not body.get("success"):
        raise SystemExit(f"Servis hata döndürdü: {body.get('message')}")

    days = []
    for item in body.get("data", []):
        times = item["times"]
        day = {"date": item["date"][:10]}  # "2026-11-21T00:00:00.000Z" → "2026-11-21"
        for key in KEYS:
            day[key] = times[key]
        hijri = (item.get("hijri_date") or {}).get("full_date")
        if hijri:
            day["hijri"] = hijri
        days.append(day)
    return sorted(days, key=lambda d: d["date"])


def fetch_diyanet(start: dt.date, end: dt.date) -> list[dict]:
    # TODO(diyanet): Hesap onaylanınca:
    #   POST https://awqatsalah.diyanet.gov.tr/Auth/Login  {email, password}
    #   POST /api/PrayerTime/DateRange  (yer bazında ayda 10 istek sınırı)
    #   Yanıtı yukarıdaki biçime (date + 6 vakit + hijri) dönüştür.
    raise SystemExit(
        "Diyanet kaynağı henüz etkin değil. AWQAT_USERNAME/AWQAT_PASSWORD "
        "secrets eklenince bu fonksiyon tamamlanacak. Şimdilik PRAYER_SOURCE=imsakiyem."
    )


def check(days: list[dict], start: dt.date, end: dt.date, today: dt.date) -> None:
    if not days:
        raise SystemExit("Servis hiç gün döndürmedi.")
    dates = [dt.date.fromisoformat(d["date"]) for d in days]
    for a, b in zip(dates, dates[1:]):
        if (b - a).days != 1:
            raise SystemExit(f"Günler ardışık değil: {a} → {b}")
    if dates[0] > today or dates[-1] < today + dt.timedelta(days=14):
        raise SystemExit(
            f"Kapsam yetersiz: {dates[0]} – {dates[-1]} (bugün + 14 gün gerekiyor)"
        )
    for d in days:
        values = [d[k] for k in KEYS]
        if values != sorted(values):
            raise SystemExit(f"{d['date']}: vakitler sıralı değil {values}")
    expected = (end - start).days + 1
    if len(days) < expected:
        log(f"UYARI: {expected} gün beklendi, {len(days)} geldi (gelecek ay henüz yayınlanmamış olabilir).")


def main() -> int:
    today = dt.datetime.now(TZ).date()
    start, end = window(today)
    log(f"Kaynak: {SOURCE} · İlçe: {DISTRICT_ID} · Aralık: {start} – {end}")

    if SOURCE == "imsakiyem":
        days = fetch_imsakiyem(start, end)
    elif SOURCE == "diyanet":
        days = fetch_diyanet(start, end)
    else:
        raise SystemExit(f"Bilinmeyen kaynak: {SOURCE}")

    check(days, start, end, today)

    new_data = {"location": "Erdek, Balıkesir", "days": days}
    if OUT.exists():
        old = json.loads(OUT.read_text(encoding="utf-8"))
        if old.get("data") == new_data and not old.get("isSample"):
            log("Vakitler değişmemiş; dosyaya dokunulmadı.")
            return 0

    doc = {
        "schemaVersion": 1,
        "isSample": False,
        "updatedAt": dt.datetime.now(TZ).replace(microsecond=0).isoformat(),
        "source": SOURCE_LABELS[SOURCE],
        "data": new_data,
    }
    OUT.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    log(f"Yazıldı: {OUT.relative_to(ROOT)} ({len(days)} gün, {days[0]['date']} – {days[-1]['date']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
