-- Erdek Şehir Rehberi — su / elektrik / doğal gaz kesintileri
-- SQL Editor → New query → tamamını yapıştır → Run. Tekrar çalıştırılabilir.
-- content_docs tablosuna "outages" belge kimliği izni (panel → Kesintiler).

alter table public.content_docs drop constraint if exists content_docs_id_check;
alter table public.content_docs add constraint content_docs_id_check check (
  id in (
    'contacts', 'announcements', 'pharmacy', 'transport', 'places', 'history',
    'businesses', 'social', 'stories', 'appearance', 'events', 'outages'
  )
);
