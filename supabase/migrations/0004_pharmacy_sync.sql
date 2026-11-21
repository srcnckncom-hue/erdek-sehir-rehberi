-- Erdek Şehir Rehberi — nöbetçi eczane otomatik güncelleme (pharmacy-sync)
-- SQL Editor → New query → tamamını yapıştır → Run. Tekrar çalıştırılabilir.
--
-- GitHub Actions'taki scripts/fetch_pharmacy_duty.py her gün Balıkesir Eczacı
-- Odası nöbet listesini okur ve eczane belgesini (content_docs 'pharmacy')
-- sync_pharmacy_duty() ile kaydeder. Secret key KULLANILMAZ: fonksiyon yalnızca
-- doğru otomasyon anahtarıyla (PHARMACY_SYNC_TOKEN) çalışır ve YALNIZCA
-- 'pharmacy' belgesini yazabilir. Anahtarın kendisi veritabanında tutulmaz,
-- yalnızca SHA-256 özeti.
--
-- ANAHTAR OLUŞTURMA (bir kez; yenilemek için tekrar çalıştır):
--   select public.create_automation_token('pharmacy-sync');
--   → çıkan uzun metni GitHub → Settings → Secrets and variables → Actions →
--     New repository secret → Name: PHARMACY_SYNC_TOKEN olarak kaydet.
--   Bu metni sohbete / başka yere YAPIŞTIRMA.

create table if not exists public.automation_tokens (
  name text primary key,
  token_hash text not null,
  created_at timestamptz not null default now()
);

-- Kimse doğrudan okuyamaz/yazamaz (politika yok); yalnızca aşağıdaki fonksiyonlar.
alter table public.automation_tokens enable row level security;
revoke all on public.automation_tokens from anon, authenticated;

-- Yeni anahtar üretir, özetini saklar, anahtarı BİR KEZ döndürür.
-- Yalnızca SQL Editor'den (postgres) çalıştırılır.
create or replace function public.create_automation_token(p_name text) returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_token text := encode(gen_random_uuid()::text::bytea, 'hex') || encode(gen_random_uuid()::text::bytea, 'hex');
begin
  insert into public.automation_tokens (name, token_hash)
  values (p_name, encode(sha256(convert_to(v_token, 'UTF8')), 'hex'))
  on conflict (name) do update set token_hash = excluded.token_hash, created_at = now();
  return v_token;
end $$;

revoke all on function public.create_automation_token(text) from public, anon, authenticated;

-- Otomasyonun çağırdığı tek fonksiyon: anahtar doğruysa eczane belgesini yazar.
create or replace function public.sync_pharmacy_duty(p_token text, p_doc jsonb) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_token is null or not exists (
    select 1 from public.automation_tokens
    where name = 'pharmacy-sync'
      and token_hash = encode(sha256(convert_to(p_token, 'UTF8')), 'hex')
  ) then
    raise exception 'yetkisiz' using errcode = '42501';
  end if;

  if jsonb_typeof(p_doc -> 'data' -> 'pharmacies') <> 'array'
     or jsonb_typeof(p_doc -> 'data' -> 'duties') <> 'array'
     or jsonb_array_length(p_doc -> 'data' -> 'pharmacies') = 0 then
    raise exception 'geçersiz eczane belgesi' using errcode = '22023';
  end if;

  insert into public.content_docs (id, doc) values ('pharmacy', p_doc)
  on conflict (id) do update set doc = excluded.doc;
end $$;

revoke all on function public.sync_pharmacy_duty(text, jsonb) from public;
grant execute on function public.sync_pharmacy_duty(text, jsonb) to anon, authenticated;
