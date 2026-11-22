-- Erdek Şehir Rehberi — panelden gönderilen bildirimlerin kaydı
-- SQL Editor → New query → tamamını yapıştır → Run. Tekrar çalıştırılabilir.
--
-- Kayıtları yalnızca send-push Edge Function yazar (service role).
-- Panel son gönderimleri listeler; günlük sınır da buradan sayılır.

create table if not exists public.push_log (
  id bigint generated always as identity primary key,
  title text not null check (char_length(title) between 1 and 80),
  body text not null check (char_length(body) between 1 and 240),
  topic text not null default 'duyurular',
  sent_by uuid references auth.users (id) on delete set null,
  sent_by_email text,
  ok boolean not null,
  result text,
  sent_at timestamptz not null default now()
);

alter table public.push_log enable row level security;

revoke all on public.push_log from anon, authenticated;
grant select on public.push_log to authenticated;

drop policy if exists push_log_admin_select on public.push_log;
create policy push_log_admin_select on public.push_log for select to authenticated
  using ((select public.is_admin()));
