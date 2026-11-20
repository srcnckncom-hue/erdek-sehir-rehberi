#!/usr/bin/env bash
# CI'da GitHub Secrets'tan config/env.json üretir (repo'ya girmez).
# Kullanım (workflow içinde):
#   env:
#     SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
#     ...
#   run: bash scripts/make_env.sh config/env.json
set -euo pipefail

OUT="${1:-config/env.json}"

: "${DATA_BASE_URL:?DATA_BASE_URL eksik}"
: "${SUPABASE_URL:?SUPABASE_URL eksik}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY eksik}"
: "${WEATHER_USER_AGENT:?WEATHER_USER_AGENT eksik}"

mkdir -p "$(dirname "$OUT")"
jq -n \
  --arg APP_ENV "${APP_ENV:-prod}" \
  --arg DATA_BASE_URL "$DATA_BASE_URL" \
  --arg SUPABASE_URL "$SUPABASE_URL" \
  --arg SUPABASE_ANON_KEY "$SUPABASE_ANON_KEY" \
  --arg SENTRY_DSN "${SENTRY_DSN:-}" \
  --arg WEATHER_USER_AGENT "$WEATHER_USER_AGENT" \
  '{APP_ENV: $APP_ENV, DATA_BASE_URL: $DATA_BASE_URL,
    SUPABASE_URL: $SUPABASE_URL, SUPABASE_ANON_KEY: $SUPABASE_ANON_KEY,
    SENTRY_DSN: $SENTRY_DSN, WEATHER_USER_AGENT: $WEATHER_USER_AGENT}' > "$OUT"

echo "$OUT üretildi (değerler gizli, yazdırılmıyor)."
