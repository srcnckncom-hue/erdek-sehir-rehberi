-- Erdek Şehir Rehberi — panelden düzenlenen içerikler (9c)
-- SQL Editor → New query → tamamını yapıştır → Run. Tekrar çalıştırılabilir.
--
-- Her satır, data/<id>.json ile AYNI biçimde bir belge tutar:
--   {schemaVersion:1, isSample, updatedAt, source, data:{...}}
-- Uygulama get_content(id) ile okur; satır yoksa GitHub Pages'teki
-- dosyaya, o da yoksa uygulamayla gelen kopyaya düşer.
-- Namaz vakitleri burada DEĞİL (haftalık otomatik görev, GitHub Pages).

create table if not exists public.content_docs (
  id text primary key check (id in ('contacts', 'announcements', 'pharmacy', 'transport', 'places', 'history')),
  doc jsonb not null check (
    (doc ->> 'schemaVersion') = '1'
    and jsonb_typeof(doc -> 'data') = 'object'
    and jsonb_typeof(doc -> 'isSample') = 'boolean'
  ),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null
);

create or replace function public.content_docs_touch() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end $$;

drop trigger if exists content_docs_touch on public.content_docs;
create trigger content_docs_touch before insert or update on public.content_docs
  for each row execute function public.content_docs_touch();

alter table public.content_docs enable row level security;
revoke all on public.content_docs from anon, authenticated;
grant select, insert, update, delete on public.content_docs to authenticated;

drop policy if exists content_admin_all on public.content_docs;
create policy content_admin_all on public.content_docs for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- Uygulama yalnızca bunu çağırır (tabloya doğrudan erişim yok).
create or replace function public.get_content(p_id text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select doc from public.content_docs where id = p_id;
$$;

revoke all on function public.get_content(text) from public;
grant execute on function public.get_content(text) to anon, authenticated;
