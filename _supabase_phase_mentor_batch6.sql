-- Phase: Mentor cleanup (Batch 6) — học viên xem được lộ trình cá nhân hoá do mentor tạo
-- Chạy trong Supabase SQL editor TRƯỚC khi dùng bản mentor.html mới (mục "Lộ trình cá nhân hoá từ Mentor").

-- learning_path_steps hiện chỉ có policy cho mentor (batch3). Học viên chưa đọc được lộ trình của chính mình.
create policy "Student can read own path steps"
  on learning_path_steps for select
  to authenticated
  using (student_id = auth.uid());
