-- Erdek Şehir Rehberi — ana sayfa hikâyeleri
-- SQL Editor → New query → tamamını yapıştır → Run. Tekrar çalıştırılabilir.
-- content_docs tablosuna "stories" belge kimliği izni (panel → Hikâyeler).
-- Fotoğraflar content-images kovasının stories/ klasörüne yüklenir.

alter table public.content_docs drop constraint if exists content_docs_id_check;
alter table public.content_docs add constraint content_docs_id_check check (
  id in (
    'contacts', 'announcements', 'pharmacy', 'transport', 'places', 'history',
    'businesses', 'social', 'stories'
  )
);
