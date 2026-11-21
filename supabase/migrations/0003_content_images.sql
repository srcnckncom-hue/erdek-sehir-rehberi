-- Erdek Şehir Rehberi — içerik fotoğrafları (gezilecek yerler vb.)
-- SQL Editor → New query → tamamını yapıştır → Run. Tekrar çalıştırılabilir.
--
-- Herkese açık "content-images" kovası: uygulama fotoğrafları
--   <SUPABASE_URL>/storage/v1/object/public/content-images/<yol>
-- adresinden okur (anahtar gerekmez). Yalnızca admin yükler/siler.
-- Dosya başına en çok 2 MB; JPG, PNG, WEBP.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('content-images', 'content-images', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists content_images_admin_select on storage.objects;
create policy content_images_admin_select on storage.objects for select to authenticated
  using (bucket_id = 'content-images' and (select public.is_admin()));

drop policy if exists content_images_admin_insert on storage.objects;
create policy content_images_admin_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'content-images' and (select public.is_admin()));

drop policy if exists content_images_admin_update on storage.objects;
create policy content_images_admin_update on storage.objects for update to authenticated
  using (bucket_id = 'content-images' and (select public.is_admin()));

drop policy if exists content_images_admin_delete on storage.objects;
create policy content_images_admin_delete on storage.objects for delete to authenticated
  using (bucket_id = 'content-images' and (select public.is_admin()));
