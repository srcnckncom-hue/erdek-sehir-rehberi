#!/usr/bin/env python3
"""data/*.json dosyalarını doğrular.

1) JSON Şeması (data/schemas/<ad>.schema.json)
2) Şemanın yakalayamadığı mantık kontrolleri:
   - nöbet listesindeki eczane kimlikleri tanımlı mı, aynı gün iki kez var mı
   - tarife başlangıcı bitişten önce mi
   - vakitler gün içinde sıralı mı, aynı tarih iki kez var mı
   - kimlikler (id) tekil mi

Kullanım: python3 scripts/validate_data.py   (gereksinim: pip install jsonschema)
Hata varsa çıkış kodu 1 olur ve hatalar Türkçe listelenir.
"""
import json
import sys
from pathlib import Path

import jsonschema

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
FILES = ["pharmacy", "prayer_times", "transport", "contacts", "announcements"]

errors: list[str] = []


def err(file: str, msg: str) -> None:
    errors.append(f"{file}.json: {msg}")


def dupes(values):
    seen, out = set(), set()
    for v in values:
        (out if v in seen else seen).add(v)
    return sorted(out)


def check_pharmacy(d):
    ids = [p["id"] for p in d["pharmacies"]]
    for x in dupes(ids):
        err("pharmacy", f"eczane kimliği birden fazla kez tanımlı: {x}")
    for x in dupes([du["date"] for du in d["duties"]]):
        err("pharmacy", f"aynı nöbet günü iki kez yazılmış: {x}")
    known = set(ids)
    for du in d["duties"]:
        for pid in du["pharmacyIds"]:
            if pid not in known:
                err("pharmacy", f"{du['date']} nöbetinde tanımsız eczane kimliği: {pid}")


def check_prayer(d):
    order = ["imsak", "gunes", "ogle", "ikindi", "aksam", "yatsi"]
    for x in dupes([day["date"] for day in d["days"]]):
        err("prayer_times", f"aynı gün iki kez yazılmış: {x}")
    for day in d["days"]:
        times = [day[k] for k in order]
        if times != sorted(times):
            err("prayer_times", f"{day['date']}: vakitler sıralı değil {times}")


def check_transport(d):
    for x in dupes([r["id"] for r in d["routes"]]):
        err("transport", f"hat kimliği birden fazla kez tanımlı: {x}")
    for r in d["routes"]:
        for t in r["timetables"]:
            if t["validFrom"] > t["validTo"]:
                err("transport", f"{r['id']} / {t['name']}: başlangıç tarihi bitişten sonra")


def check_contacts(d):
    for x in dupes([c["id"] for c in d["categories"]]):
        err("contacts", f"kategori kimliği birden fazla kez tanımlı: {x}")


def check_announcements(d):
    for x in dupes([a["id"] for a in d["items"]]):
        err("announcements", f"duyuru kimliği birden fazla kez tanımlı: {x}")


CHECKS = {
    "pharmacy": check_pharmacy,
    "prayer_times": check_prayer,
    "transport": check_transport,
    "contacts": check_contacts,
    "announcements": check_announcements,
}


def main() -> int:
    for name in FILES:
        path = DATA / f"{name}.json"
        try:
            doc = json.loads(path.read_text(encoding="utf-8"))
        except FileNotFoundError:
            err(name, "dosya bulunamadı")
            continue
        except json.JSONDecodeError as e:
            err(name, f"JSON yazım hatası, satır {e.lineno} sütun {e.colno}: {e.msg}")
            continue

        schema = json.loads((DATA / "schemas" / f"{name}.schema.json").read_text(encoding="utf-8"))
        validator = jsonschema.Draft202012Validator(
            schema, format_checker=jsonschema.FormatChecker()
        )
        schema_errors = sorted(validator.iter_errors(doc), key=lambda e: list(e.path))
        for e in schema_errors:
            where = "/".join(str(p) for p in e.path) or "(kök)"
            err(name, f"{where}: {e.message}")
        if schema_errors:
            continue

        CHECKS[name](doc["data"])
        if doc.get("isSample"):
            print(f"UYARI  {name}.json hâlâ ÖRNEK VERİ (isSample: true)")

    if errors:
        print("\nHATALAR:")
        for e in errors:
            print(f"  ✗ {e}")
        return 1
    print("\nTüm veri dosyaları geçerli ✓")
    return 0


if __name__ == "__main__":
    sys.exit(main())
