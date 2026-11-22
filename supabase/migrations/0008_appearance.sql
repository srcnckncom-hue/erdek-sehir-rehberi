-- Erdek Şehir Rehberi — görünüm ayarları (ana sayfa arka plan fotoğrafı)
-- SQL Editor → New query → tamamını yapıştır → Run. Tekrar çalıştırılabilir.
-- content_docs tablosuna "appearance" belge kimliği izni (panel → Görünüm).
-- Fotoğraflar content-images kovasının appearance/ klasörüne yüklenir.

alter table public.content_docs drop constraint if exists content_docs_id_check;
alter table public.content_docs add constraint content_docs_id_check check (
  id in (
    'contacts', 'announcements', 'pharmacy', 'transport', 'places', 'history',
    'businesses', 'social', 'stories', 'appearance'
  )
);
