-- Erdek Şehir Rehberi — İşletmeler ve sosyal medya hesapları
-- SQL Editor → New query → tamamını yapıştır → Run. Tekrar çalıştırılabilir.
--
-- content_docs tablosuna iki yeni belge kimliği izni verir:
--   businesses : işletme kategorileri + işletmeler (panel → İşletmeler)
--   social     : Instagram / Facebook / X adresleri (panel → Sosyal Medya)
-- Uygulama bunları da get_content(id) ile okur; ek bir yetki gerekmez.

alter table public.content_docs drop constraint if exists content_docs_id_check;
alter table public.content_docs add constraint content_docs_id_check check (
  id in (
    'contacts', 'announcements', 'pharmacy', 'transport', 'places', 'history',
    'businesses', 'social'
  )
);
