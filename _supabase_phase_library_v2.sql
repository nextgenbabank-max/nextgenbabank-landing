-- Phase: Thư viện tài liệu tham khảo — bổ sung cho màn hình quản trị mới (admin-library.html v2)
-- Thêm: is_featured (đánh dấu nổi bật), updated_by (Người cập nhật), bucket ảnh đại diện tài liệu.

alter table library_documents
  add column if not exists is_featured boolean not null default false,
  add column if not exists updated_by uuid references auth.users(id) on delete set null;

create index if not exists idx_library_documents_featured on library_documents(is_featured) where is_featured = true;

-- Bucket lưu ảnh đại diện (thumbnail) tài liệu — public đọc, chỉ admin ghi. Cùng pattern với bucket
-- 'avatars' đã có (public bucket, upload qua window.sb.storage.from(...).upload(...)).
insert into storage.buckets (id, name, public)
values ('library-thumbnails', 'library-thumbnails', true)
on conflict (id) do nothing;

drop policy if exists "Public read library thumbnails" on storage.objects;
create policy "Public read library thumbnails" on storage.objects
  for select using (bucket_id = 'library-thumbnails');

drop policy if exists "Admin upload library thumbnails" on storage.objects;
create policy "Admin upload library thumbnails" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'library-thumbnails' and public.is_current_user_admin());

drop policy if exists "Admin update library thumbnails" on storage.objects;
create policy "Admin update library thumbnails" on storage.objects
  for update to authenticated
  using (bucket_id = 'library-thumbnails' and public.is_current_user_admin());

drop policy if exists "Admin delete library thumbnails" on storage.objects;
create policy "Admin delete library thumbnails" on storage.objects
  for delete to authenticated
  using (bucket_id = 'library-thumbnails' and public.is_current_user_admin());