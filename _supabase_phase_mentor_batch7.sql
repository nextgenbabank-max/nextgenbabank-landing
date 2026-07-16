-- Phase: Mentor cleanup (Batch 7) — mentor gắn tài liệu (link Google Drive) riêng cho lớp mình phụ trách
-- Chạy trong Supabase SQL editor TRƯỚC khi dùng bản mentor-classes.html mới (tab "Tài liệu").

-- documents hiện chỉ có policy "Authenticated can read documents" (select) và "Admins can manage documents" (for all).
-- Mentor chưa có quyền insert/update/delete — thêm policy scoped theo lớp mentor phụ trách.

create policy "Mentor can insert documents for own classes"
  on documents for insert
  to authenticated
  with check (class_id in (select id from classes where mentor_id = public.current_mentor_id()));

create policy "Mentor can update own class documents"
  on documents for update
  to authenticated
  using (class_id in (select id from classes where mentor_id = public.current_mentor_id()))
  with check (class_id in (select id from classes where mentor_id = public.current_mentor_id()));

create policy "Mentor can delete own class documents"
  on documents for delete
  to authenticated
  using (class_id in (select id from classes where mentor_id = public.current_mentor_id()));
