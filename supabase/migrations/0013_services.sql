-- Erdek Şehir Rehberi — harita katmanları (taksi, ATM, otopark, WC, şarj, akaryakıt)
-- SQL Editor → New query → tamamını yapıştır → Run. Tekrar çalıştırılabilir.

alter table public.content_docs drop constraint if exists content_docs_id_check;
alter table public.content_docs add constraint content_docs_id_check check (
  id in (
    'contacts', 'announcements', 'pharmacy', 'transport', 'places', 'history',
    'businesses', 'social', 'stories', 'appearance', 'events', 'outages', 'markets', 'trips', 'services'
  )
);
