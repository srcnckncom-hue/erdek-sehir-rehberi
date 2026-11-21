-- Erdek Şehir Rehberi — reklam sistemi (9. adım)
-- Supabase panelinde: SQL Editor → New query → bu dosyanın tamamını yapıştır → Run.
-- Tekrar çalıştırılabilir (if not exists / or replace / on conflict).
--
-- Güvenlik modeli:
--   * Tüm tablolarda RLS açık. Uygulama (anon) tablolara DOĞRUDAN erişemez.
--   * Uygulama yalnızca iki fonksiyonu çağırır: get_active_ads(), record_ad_event().
--   * Admin paneli giriş yapmış kullanıcı (authenticated) olarak çalışır;
--     yazma yetkisi yalnızca public.admins tablosundaki kullanıcılarda.

-- ─── Tablolar ────────────────────────────────────────────────────────────
create table if not exists public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.ad_slots (
  id text primary key,                 -- uygulamadaki AdSlot(id: ...)
  title text not null,                 -- panelde görünen ad
  description text
);

create table if not exists public.ads (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 80),
  advertiser text check (advertiser is null or char_length(advertiser) <= 80),
  image_path text not null,            -- ad-images kovasındaki dosya yolu
  link_url text check (link_url is null or link_url ~ '^https://'),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  is_active boolean not null default true,
  priority int not null default 0,     -- büyük olan önce
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or ends_at > starts_at)
);

create table if not exists public.ad_placements (
  ad_id uuid not null references public.ads (id) on delete cascade,
  slot_id text not null references public.ad_slots (id) on delete cascade,
  primary key (ad_id, slot_id)
);

create table if not exists public.ad_stats_daily (
  ad_id uuid not null references public.ads (id) on delete cascade,
  slot_id text not null references public.ad_slots (id) on delete cascade,
  day date not null,
  impressions int not null default 0,
  clicks int not null default 0,
  primary key (ad_id, slot_id, day)
);

-- Uygulamadaki reklam alanları
insert into public.ad_slots (id, title, description) values
  ('home_feed_1', 'Ana sayfa', 'Hızlı İşlemler ile Şehir Hizmetleri arası · 1200×600'),
  ('pharmacy_bottom', 'Eczane sayfası altı', '1200×600'),
  ('prayer_bottom', 'Vakitler sayfası altı', '1200×600'),
  ('transport_bottom', 'Ulaşım sayfası altı', '1200×600'),
  ('transport_list_inline', 'Sefer listesi arası', 'Her 5 seferde bir · 1200×600'),
  ('contacts_bottom', 'Rehber sayfası altı', '1200×600')
on conflict (id) do update set title = excluded.title, description = excluded.description;

-- updated_at otomatik
create or replace function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists ads_touch on public.ads;
create trigger ads_touch before update on public.ads
  for each row execute function public.touch_updated_at();

-- ─── Yetki ───────────────────────────────────────────────────────────────
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

alter table public.admins enable row level security;
alter table public.ad_slots enable row level security;
alter table public.ads enable row level security;
alter table public.ad_placements enable row level security;
alter table public.ad_stats_daily enable row level security;

revoke all on public.admins, public.ad_slots, public.ads, public.ad_placements, public.ad_stats_daily
  from anon, authenticated;
grant select on public.admins, public.ad_slots, public.ad_stats_daily to authenticated;
grant select, insert, update, delete on public.ads, public.ad_placements to authenticated;

drop policy if exists admins_self on public.admins;
create policy admins_self on public.admins for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists slots_admin_read on public.ad_slots;
create policy slots_admin_read on public.ad_slots for select to authenticated
  using ((select public.is_admin()));

drop policy if exists ads_admin_all on public.ads;
create policy ads_admin_all on public.ads for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

drop policy if exists placements_admin_all on public.ad_placements;
create policy placements_admin_all on public.ad_placements for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

drop policy if exists stats_admin_read on public.ad_stats_daily;
create policy stats_admin_read on public.ad_stats_daily for select to authenticated
  using ((select public.is_admin()));

-- ─── Uygulamanın çağırdığı fonksiyonlar ──────────────────────────────────
-- Şu an yayında olan reklamlar (slot başına). Görsel adresi uygulamada
-- <SUPABASE_URL>/storage/v1/object/public/ad-images/<image_path> olarak kurulur.
drop function if exists public.get_active_ads();
create function public.get_active_ads()
returns table (ad_id uuid, slot_id text, title text, advertiser text,
               image_path text, link_url text, priority int, ends_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select a.id, p.slot_id, a.title, a.advertiser, a.image_path, a.link_url, a.priority, a.ends_at
  from public.ads a
  join public.ad_placements p on p.ad_id = a.id
  where a.is_active
    and a.starts_at <= now()
    and (a.ends_at is null or a.ends_at > now())
  order by p.slot_id, a.priority desc, a.created_at;
$$;

-- Gösterim / tıklama sayacı (günlük toplam, Türkiye saatiyle gün).
create or replace function public.record_ad_event(p_ad_id uuid, p_slot_id text, p_kind text)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_kind not in ('impression', 'click') then
    raise exception 'geçersiz olay: %', p_kind;
  end if;
  -- Yalnızca o slotta gerçekten yayında olan reklamlar sayılır.
  if not exists (
    select 1 from public.ads a
    join public.ad_placements p on p.ad_id = a.id and p.slot_id = p_slot_id
    where a.id = p_ad_id and a.is_active and a.starts_at <= now()
      and (a.ends_at is null or a.ends_at > now())
  ) then
    return;
  end if;
  insert into public.ad_stats_daily as s (ad_id, slot_id, day, impressions, clicks)
  values (p_ad_id, p_slot_id, (now() at time zone 'Europe/Istanbul')::date,
          case when p_kind = 'impression' then 1 else 0 end,
          case when p_kind = 'click' then 1 else 0 end)
  on conflict (ad_id, slot_id, day) do update set
    impressions = s.impressions + excluded.impressions,
    clicks = s.clicks + excluded.clicks;
end $$;

revoke all on function public.get_active_ads() from public;
revoke all on function public.record_ad_event(uuid, text, text) from public;
revoke all on function public.is_admin() from public;
grant execute on function public.get_active_ads() to anon, authenticated;
grant execute on function public.record_ad_event(uuid, text, text) to anon, authenticated;
grant execute on function public.is_admin() to authenticated;

-- ─── Görseller (Storage) ─────────────────────────────────────────────────
-- Herkes okuyabilir (uygulama indirir), yalnızca admin yükler/siler.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('ad-images', 'ad-images', true, 1048576, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists ad_images_admin_select on storage.objects;
create policy ad_images_admin_select on storage.objects for select to authenticated
  using (bucket_id = 'ad-images' and (select public.is_admin()));

drop policy if exists ad_images_admin_insert on storage.objects;
create policy ad_images_admin_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'ad-images' and (select public.is_admin()));

drop policy if exists ad_images_admin_update on storage.objects;
create policy ad_images_admin_update on storage.objects for update to authenticated
  using (bucket_id = 'ad-images' and (select public.is_admin()));

drop policy if exists ad_images_admin_delete on storage.objects;
create policy ad_images_admin_delete on storage.objects for delete to authenticated
  using (bucket_id = 'ad-images' and (select public.is_admin()));

-- ─── Kendini admin yap ───────────────────────────────────────────────────
-- 1) Authentication → Users → Add user → Create new user (e-posta + şifre,
--    "Auto Confirm User" işaretli).
-- 2) Aşağıdaki satırdaki e-postayı kendininkiyle değiştirip AYRICA çalıştır:
-- insert into public.admins (user_id) select id from auth.users where email = 'SENIN@EPOSTAN.com';
