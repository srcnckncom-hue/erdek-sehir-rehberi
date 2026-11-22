-- Erdek Şehir Rehberi — etkinlik takvimi
-- SQL Editor → New query → tamamını yapıştır → Run. Tekrar çalıştırılabilir.
-- content_docs tablosuna "events" belge kimliği izni (panel → Etkinlikler).
-- Fotoğraflar content-images kovasının events/ klasörüne yüklenir.

alter table public.content_docs drop constraint if exists content_docs_id_check;
alter table public.content_docs add constraint content_docs_id_check check (
  id in (
    'contacts', 'announcements', 'pharmacy', 'transport', 'places', 'history',
    'businesses', 'social', 'stories', 'appearance', 'events'
  )
);
