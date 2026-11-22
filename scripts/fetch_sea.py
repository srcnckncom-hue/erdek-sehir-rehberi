#!/usr/bin/env python3
"""Erdek açıkları deniz bilgisi → data/sea.json

Kaynak: E.U. Copernicus Marine Service (ücretsiz, ticari kullanıma izinli;
kaynak gösterilmesi şart). Hesap bilgileri GitHub secrets'ta:
  COPERNICUSMARINE_SERVICE_USERNAME / COPERNICUSMARINE_SERVICE_PASSWORD

  * Deniz suyu sıcaklığı: Karadeniz modelinin Marmara Denizi alt alanı
    (500 m çözünürlük), günlük ortalama, yüzey katmanı.
  * Dalga yüksekliği: Copernicus küresel dalga modeli (1/12°), 3 saatlik;
    Erdek günü (UTC+3) içindeki en yüksek ve ortalama belirgin dalga yüksekliği.

Kullanım:
  python3 scripts/fetch_sea.py            # data/sea.json yazar
  python3 scripts/fetch_sea.py --dry-run  # yalnızca ekrana yazar
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import os
import sys

TARGET_LAT, TARGET_LON = 40.40, 27.78  # Erdek Körfezi (iskele açığı)
TZ = dt.timezone(dt.timedelta(hours=3))  # Türkiye, yıl boyu UTC+3

TEMP_DATASET = "cmems_mod_blk_phy-tem_anfc_mrm-500m_P1D-m"
TEMP_VAR = "thetao"
WAVE_DATASET = "cmems_mod_glo_wav_anfc_0.083deg_PT3H-i"
WAVE_VAR = "VHM0"

OUT = os.path.join(os.path.dirname(__file__), "..", "data", "sea.json")
SOURCE = "E.U. Copernicus Marine Service Information"


def nearest_series(ds, var: str, box: float):
    """Hedefe en yakın, verisi olan (kara olmayan) hücrenin zaman serisi."""
    import numpy as np

    da = ds[var]
    if "depth" in da.dims:
        da = da.isel(depth=0)
    da = da.transpose("time", "latitude", "longitude")
    arr = np.asarray(da.values, dtype=float)  # tek seferde indir
    lats = np.asarray(da["latitude"].values, dtype=float)
    lons = np.asarray(da["longitude"].values, dtype=float)
    has_data = ~np.all(np.isnan(arr), axis=0)
    if not has_data.any():
        raise RuntimeError(f"{var}: ±{box}° içinde deniz hücresi yok")
    lat_grid, lon_grid = np.meshgrid(lats, lons, indexing="ij")
    dist = np.hypot(lat_grid - TARGET_LAT, (lon_grid - TARGET_LON) * math.cos(math.radians(TARGET_LAT)))
    dist[~has_data] = np.inf
    i, j = np.unravel_index(np.argmin(dist), dist.shape)
    print(f"{var}: en yakın hücre {lats[i]:.3f}N {lons[j]:.3f}E", file=sys.stderr)
    return da["time"].values, arr[:, i, j]


def to_local_date(t) -> str:
    import numpy as np

    ts = (t - np.datetime64("1970-01-01T00:00:00")) / np.timedelta64(1, "s")
    return dt.datetime.fromtimestamp(float(ts), tz=dt.timezone.utc).astimezone(TZ).date().isoformat()


def fetch(var: str, dataset: str, start: dt.datetime, end: dt.datetime, box: float, depth: bool):
    import copernicusmarine

    kwargs = dict(
        dataset_id=dataset,
        variables=[var],
        minimum_latitude=TARGET_LAT - box,
        maximum_latitude=TARGET_LAT + box,
        minimum_longitude=TARGET_LON - box,
        maximum_longitude=TARGET_LON + box,
        start_datetime=start.strftime("%Y-%m-%dT%H:%M:%S"),
        end_datetime=end.strftime("%Y-%m-%dT%H:%M:%S"),
    )
    if depth:
        kwargs.update(minimum_depth=0, maximum_depth=3)
    ds = copernicusmarine.open_dataset(**kwargs)
    return nearest_series(ds, var, box)


def build(today: dt.date) -> dict:
    import numpy as np

    start = dt.datetime.combine(today - dt.timedelta(days=1), dt.time(0, 0))
    end = dt.datetime.combine(today + dt.timedelta(days=7), dt.time(0, 0))
    days: dict[str, dict] = {}
    errors = []

    try:
        times, values = fetch(TEMP_VAR, TEMP_DATASET, start, end, box=0.15, depth=True)
        for t, v in zip(times, values):
            if np.isnan(v):
                continue
            # Günlük ortalama: zaman damgası günün ortası (UTC) → tarih.
            date = str(np.datetime_as_string(t, unit="D"))
            days.setdefault(date, {})["waterTempC"] = round(float(v), 1)
    except Exception as e:  # noqa: BLE001
        errors.append(f"sıcaklık: {e}")

    try:
        times, values = fetch(WAVE_VAR, WAVE_DATASET, start, end, box=0.35, depth=False)
        per_day: dict[str, list[float]] = {}
        for t, v in zip(times, values):
            if np.isnan(v):
                continue
            per_day.setdefault(to_local_date(t), []).append(float(v))
        for date, hs in per_day.items():
            d = days.setdefault(date, {})
            d["waveHeightM"] = round(sum(hs) / len(hs), 1)
            d["waveMaxM"] = round(max(hs), 1)
    except Exception as e:  # noqa: BLE001
        errors.append(f"dalga: {e}")

    if not days:
        raise RuntimeError("Hiç veri alınamadı: " + "; ".join(errors))
    for e in errors:
        print(f"UYARI {e}", file=sys.stderr)

    first = today.isoformat()
    rows = [{"date": k, **v} for k, v in sorted(days.items()) if k >= first][:7]
    return {
        "schemaVersion": 1,
        "isSample": False,
        "updatedAt": dt.datetime.now(TZ).replace(microsecond=0).isoformat(),
        "source": SOURCE,
        "data": {"location": "Erdek Körfezi", "days": rows},
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    doc = build(dt.datetime.now(TZ).date())
    text = json.dumps(doc, ensure_ascii=False, indent=2) + "\n"
    if args.dry_run:
        print(text)
        return 0
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"{len(doc['data']['days'])} gün yazıldı → data/sea.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
