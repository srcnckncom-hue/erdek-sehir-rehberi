#!/usr/bin/env python3
"""Erdek'in bugünkü nöbetçi eczanesini Balıkesir Eczacı Odası sitesinden okur
ve panelin kullandığı eczane belgesine (Supabase content_docs 'pharmacy') ekler.

Kaynak: https://www.balikesireczaciodasi.org.tr/nobetci-eczaneler
  Sayfadaki formla (POST tarih1=YYYY-MM-DD, ilce=1356 [ERDEK]) istenen günün
  nöbetçisi alınır. Oda listeyi genelde bir sonraki ayın sonuna kadar
  önceden yayınlar. Günde bir kez çalışır (pharmacy-sync.yml), bugünden
  itibaren DAYS_AHEAD günü sorar (istekler arasında bekleyerek).

Ne yapar:
  1) Her gün için "DD.MM.YYYY / ERDEK" kartlarından ad / adres / telefon /
     konumu okur. Boş günler atlanır (o güne elle girilmiş kayıt korunur).
  2) Hiçbir günde Erdek kartı yoksa HİÇBİR ŞEY YAZMADAN hata verir.
  3) Supabase'teki belgeyi okur (get_content); eczane listede yoksa ekler
     (telefon ya da adla eşleştirir), bulunan günlerin nöbet kaydını yazar,
     60 günden eski nöbetleri atar. Belge ÖRNEK veriyse örnekleri temizler.
  4) Şemayla doğrular ve sync_pharmacy_duty RPC'si ile kaydeder. Bu RPC yalnızca
     PHARMACY_SYNC_TOKEN ile çalışır (0004_pharmacy_sync.sql); secret key
     KULLANILMAZ.

Ortam değişkenleri: SUPABASE_URL, SUPABASE_ANON_KEY, PHARMACY_SYNC_TOKEN
Kullanım:
  python3 scripts/fetch_pharmacy_duty.py            # çek + kaydet
  python3 scripts/fetch_pharmacy_duty.py --dry-run  # çek + birleştir, yazma
  python3 scripts/fetch_pharmacy_duty.py --self-test
"""
from __future__ import annotations

import copy
import datetime as dt
import html
import json
import os
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = ROOT / "data" / "schemas" / "pharmacy.schema.json"
FIXTURE = ROOT / "scripts" / "fixtures" / "eczaci_odasi_ornek.html"
TZ = ZoneInfo("Europe/Istanbul")

SOURCE_URL = "https://www.balikesireczaciodasi.org.tr/nobetci-eczaneler"
DISTRICT = "ERDEK"
DISTRICT_ID = "1356"  # sayfadaki ilçe seçicide ERDEK
DAYS_AHEAD = int(os.environ.get("PHARMACY_DAYS_AHEAD", "45"))
REQUEST_GAP_SECONDS = 1.5  # siteyi yormamak için
KEEP_DAYS = 60
SOURCE_LABEL = "Balıkesir Eczacı Odası nöbet listesi (otomatik, günlük) + panel"
USER_AGENT = (
    "ErdekSehirRehberi-pharmacy-sync/1.0 "
    "(+https://github.com/srcnckncom-hue/erdek-sehir-rehberi)"
)


def log(msg: str) -> None:
    print(msg, flush=True)


# ─── Türkçe metin yardımcıları ───────────────────────────────────────────

def tr_lower(s: str) -> str:
    return s.replace("I", "ı").replace("İ", "i").lower()


def tr_title(s: str) -> str:
    """'ÖNKAL ECZANESİ' → 'Önkal Eczanesi'"""
    words = []
    for w in tr_lower(s).split():
        first = w[0]
        first = "İ" if first == "i" else first.upper()
        words.append(first + w[1:])
    return " ".join(words)


def fold(s: str) -> str:
    """Karşılaştırma için: küçük harf, aksansız, yalnız harf/rakam."""
    s = tr_lower(s).replace("ı", "i")
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


def slug(name: str) -> str:
    words = [w for w in fold(name).split() if w not in ("eczanesi", "eczane")]
    return "-".join(words) or "eczane"


def normalize_phone(raw: str) -> str | None:
    digits = re.sub(r"\D", "", raw)
    if digits.startswith("90") and len(digits) == 12:
        digits = digits[2:]
    if digits.startswith("0"):
        digits = digits[1:]
    return f"+90{digits}" if len(digits) == 10 else None


def clean(fragment: str) -> str:
    text = re.sub(r"<[^>]+>", " ", fragment)
    text = html.unescape(text).replace("\xa0", " ")
    return re.sub(r"\s+", " ", text).strip()


# ─── Sayfayı okuma ──────────────────────────────────────────────────────

def parse_day(page: str, day: dt.date) -> list[dict]:
    """Form sonucundaki "DD.MM.YYYY / ERDEK" kartlarını okur. Kartın tarihi
    istenen günden farklıysa ya da ilçe ERDEK değilse alınmaz."""
    want = day.strftime("%d.%m.%Y")
    items = []
    for block in re.split(r'class="[^"]*\bnobet-kart\b', page)[1:]:
        h4 = re.search(r"<h4[^>]*>(.*?)</h4>", block, re.S)
        if not h4:
            continue
        head = h4.group(1)
        dm = re.search(r"(\d{2}\.\d{2}\.\d{4})\s*/\s*([^<]+)", head)
        name_m = re.search(r"<strong>(.*?)</strong>", head, re.S)
        if not dm or not name_m or dm.group(1) != want or fold(dm.group(2)) != fold(DISTRICT):
            continue
        note_m = re.search(r"<small[^>]*>(.*?)</small>", head, re.S)
        address_m = re.search(r"fa-home[^>]*></i>(.*?)<br", block, re.S)
        phone_m = re.search(r'href="tel:([^"]+)"', block)
        geo_m = re.search(r"maps\?q=(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)", block)
        items.append({
            "name": clean(name_m.group(1)),
            "note": clean(note_m.group(1)) if note_m else None,
            "address": clean(address_m.group(1)) if address_m else "",
            "phone": phone_m.group(1).strip() if phone_m else "",
            "lat": float(geo_m.group(1)) if geo_m else None,
            "lng": float(geo_m.group(2)) if geo_m else None,
        })
    return items


# ─── Belgeye ekleme ─────────────────────────────────────────────────────

def empty_doc() -> dict:
    return {"schemaVersion": 1, "isSample": False, "updatedAt": "", "source": SOURCE_LABEL,
            "data": {"pharmacies": [], "duties": []}}


def merge(doc: dict | None, found_by_day: dict[dt.date, list[dict]], now: dt.datetime) -> dict:
    """Bulunan günlerin nöbetini yazar (boş günlere dokunmaz). Mevcut (panelden
    girilmiş) eczane bilgisini değiştirmez; yalnızca eksik konumu tamamlar."""
    out = copy.deepcopy(doc) if doc else empty_doc()
    if out.get("isSample"):
        # Panel örnek veriden başlamış: örnekleri gerçek veriye karıştırma.
        out = empty_doc()
    data = out.setdefault("data", {})
    pharmacies: list[dict] = data.setdefault("pharmacies", [])
    duties: list[dict] = data.setdefault("duties", [])

    def pharmacy_id(item: dict) -> str:
        phone = normalize_phone(item["phone"])
        match = None
        for p in pharmacies:
            if phone and p.get("phone") == phone:
                match = p
                break
        if match is None:
            for p in pharmacies:
                if slug(p.get("name", "")) == slug(item["name"]):
                    match = p
                    break
        if match is None:
            if not phone or not item["address"]:
                raise ValueError(f"{item['name']}: telefon ya da adres okunamadı.")
            base = slug(item["name"])
            new_id, n = base, 2
            taken = {p["id"] for p in pharmacies}
            while new_id in taken:
                new_id = f"{base}-{n}"
                n += 1
            match = {"id": new_id, "name": tr_title(item["name"]), "address": item["address"], "phone": phone}
            pharmacies.append(match)
            log(f"  + yeni eczane: {match['name']} ({new_id})")
        if "lat" not in match and item["lat"] is not None:
            match["lat"], match["lng"] = item["lat"], item["lng"]
        return match["id"]

    by_date = {d["date"]: d for d in duties}
    for day, items in sorted(found_by_day.items()):
        if items:
            ids = list(dict.fromkeys(pharmacy_id(i) for i in items))
            by_date[day.isoformat()] = {"date": day.isoformat(), "pharmacyIds": ids}
    today = now.astimezone(TZ).date()
    cutoff = (today - dt.timedelta(days=KEEP_DAYS)).isoformat()
    data["duties"] = sorted((d for d in by_date.values() if d["date"] >= cutoff), key=lambda d: d["date"])

    out["isSample"] = False
    out["source"] = SOURCE_LABEL
    out["updatedAt"] = now.astimezone(TZ).isoformat(timespec="seconds")
    return out


def validate(doc: dict) -> None:
    import jsonschema  # CI'da pip install jsonschema

    jsonschema.validate(doc, json.loads(SCHEMA.read_text(encoding="utf-8")))
    known = {p["id"] for p in doc["data"]["pharmacies"]}
    for d in doc["data"]["duties"]:
        for pid in d["pharmacyIds"]:
            if pid not in known:
                raise ValueError(f"{d['date']}: tanımsız eczane kimliği {pid}")


# ─── Ağ ─────────────────────────────────────────────────────────────────

def http(url: str, *, body: dict | None = None, data: bytes | None = None,
         headers: dict | None = None) -> bytes:
    """body: JSON gövde; data: hazır gövde (form). İkisi de yoksa GET."""
    payload = json.dumps(body).encode() if body is not None else data
    last = None
    for attempt in range(1, 4):
        req = urllib.request.Request(
            url,
            data=payload,
            headers={"User-Agent": USER_AGENT, **(headers or {})},
            method="POST" if payload is not None else "GET",
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return resp.read()
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace")[:300]
            if 400 <= e.code < 500 and e.code != 429:
                raise SystemExit(f"HTTP {e.code}: {detail}")
            last = f"HTTP {e.code}: {detail}"
        except (urllib.error.URLError, TimeoutError) as e:
            last = str(e)
        log(f"  {last} (deneme {attempt}/3)")
        time.sleep(10 * attempt)
    raise SystemExit(f"Ulaşılamadı: {url} — {last}")


def supabase(path: str, body: dict) -> object:
    base = os.environ["SUPABASE_URL"].rstrip("/")
    key = os.environ["SUPABASE_ANON_KEY"]
    raw = http(f"{base}/rest/v1/rpc/{path}", body=body, headers={
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
    })
    return json.loads(raw) if raw.strip() else None


# ─── Giriş noktaları ────────────────────────────────────────────────────

def fetch_day(day: dt.date) -> list[dict]:
    body = urllib.parse.urlencode({
        "tarih1": day.isoformat(), "ilce": DISTRICT_ID, "gnr": " NÖBETLERİ GÖSTER ",
    }).encode()
    page = http(SOURCE_URL, data=body, headers={
        "Accept": "text/html", "Content-Type": "application/x-www-form-urlencoded",
    }).decode("utf-8", "replace")
    return parse_day(page, day)


def run(dry_run: bool) -> None:
    today = dt.datetime.now(TZ).date()
    log(f"Kaynak: {SOURCE_URL} · {today} + {DAYS_AHEAD} gün")
    found_by_day: dict[dt.date, list[dict]] = {}
    for i in range(DAYS_AHEAD + 1):
        day = today + dt.timedelta(days=i)
        items = fetch_day(day)
        found_by_day[day] = items
        names = ", ".join(tr_title(x["name"]) + (f" [{x['note']}]" if x["note"] else "") for x in items)
        log(f"  {day}: {names or '—'}")
        time.sleep(REQUEST_GAP_SECONDS)
    filled = [d for d, v in found_by_day.items() if v]
    if not filled:
        raise SystemExit("Hiçbir günde Erdek nöbetçisi okunamadı (site değişmiş olabilir). Hiçbir şey yazılmadı.")
    if not found_by_day[today]:
        log(f"::warning::Bugün ({today}) için Erdek kaydı yok.")

    doc = supabase("get_content", {"p_id": "pharmacy"})
    merged = merge(doc if isinstance(doc, dict) else None, found_by_day, dt.datetime.now(TZ))
    validate(merged)
    if dry_run:
        log(json.dumps(merged, ensure_ascii=False, indent=2)[:4000])
        log("--dry-run: yazılmadı.")
        return
    supabase("sync_pharmacy_duty", {"p_token": os.environ["PHARMACY_SYNC_TOKEN"], "p_doc": merged})
    log(f"::notice::{len(filled)} günün nöbeti kaydedildi ({min(filled)} – {max(filled)}).")


def self_test() -> None:
    page = FIXTURE.read_text(encoding="utf-8")
    day = dt.date(2026, 11, 22)
    found = parse_day(page, day)
    assert [f["name"] for f in found] == ["DOĞA ECZANESİ"], found
    assert found[0]["address"] == "Yalı Mh.Bandırma Cd.No:4/A", found[0]
    assert normalize_phone(found[0]["phone"]) == "+902668455252"
    assert (found[0]["lat"], found[0]["lng"]) == (40.398316, 27.792333)
    assert parse_day(page, dt.date(2026, 11, 23)) == []  # başka günün kartı alınmaz
    assert tr_title("DOĞA ECZANESİ") == "Doğa Eczanesi"
    assert tr_title("İSKELE ECZANESİ") == "İskele Eczanesi"
    assert tr_title("SIHHAT ECZANESİ") == "Sıhhat Eczanesi"
    assert slug("ÖNKAL ECZANESİ") == "onkal"

    now = dt.datetime(2026, 11, 22, 9, 0, tzinfo=TZ)
    # 1) Belge yok → yeni belge; boş gün yazılmaz
    doc = merge(None, {day: found, dt.date(2026, 11, 23): []}, now)
    validate(doc)
    assert doc["data"]["pharmacies"][0]["id"] == "doga"
    assert doc["data"]["duties"] == [{"date": "2026-11-22", "pharmacyIds": ["doga"]}]
    # 2) Panelden girilmiş aynı eczane (telefonla eşleşir) → adı/adresi korunur;
    #    boş güne (23) elle girilmiş kayıt korunur; 60 günden eski atılır
    manual = {"schemaVersion": 1, "isSample": False, "updatedAt": "2026-11-20T10:00:00+03:00",
              "data": {"pharmacies": [{"id": "e1", "name": "Doğa (elle)", "address": "Elle adres",
                                       "phone": "+902668455252"},
                                      {"id": "e2", "name": "Başka", "address": "a", "phone": "+902660000001"}],
                       "duties": [{"date": "2026-09-01", "pharmacyIds": ["e1"]},
                                  {"date": "2026-11-22", "pharmacyIds": ["e2"]},
                                  {"date": "2026-11-23", "pharmacyIds": ["e2"]}]}}
    doc = merge(manual, {day: found, dt.date(2026, 11, 23): []}, now)
    validate(doc)
    p = doc["data"]["pharmacies"]
    assert len(p) == 2 and p[0]["name"] == "Doğa (elle)" and p[0]["lat"] == 40.398316, p
    assert doc["data"]["duties"] == [
        {"date": "2026-11-22", "pharmacyIds": ["e1"]},
        {"date": "2026-11-23", "pharmacyIds": ["e2"]},
    ], doc["data"]["duties"]
    assert manual["data"]["pharmacies"][0].get("lat") is None  # girdi değişmedi
    # 3) Örnek veri → temizlenir
    sample = {"schemaVersion": 1, "isSample": True, "updatedAt": "x",
              "data": {"pharmacies": [{"id": "ornek-1", "name": "ÖRNEK", "address": "a", "phone": "+900000000000"}],
                       "duties": [{"date": "2026-11-24", "pharmacyIds": ["ornek-1"]}]}}
    doc = merge(sample, {day: found}, now)
    validate(doc)
    assert [x["id"] for x in doc["data"]["pharmacies"]] == ["doga"] and doc["isSample"] is False
    log("self-test: TAMAM")


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        self_test()
    else:
        run(dry_run="--dry-run" in sys.argv)
