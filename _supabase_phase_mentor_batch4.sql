-- Phase: Mentor Batch 4 — Giao bài tập theo lớp học cụ thể
-- Chạy trong Supabase SQL editor TRƯỚC khi dùng bản mentor-assignments.html mới
-- (có chọn "Lớp học" khi tạo bài tập) và các trang học viên đã lọc theo lớp.

-- Thêm cột class_id (NULL = áp dụng cho cả phase như hành vi cũ, có giá trị = chỉ lớp đó làm)
alter table assignments
  add column class_id uuid references classes(id) on delete set null;

-- Không cần thêm RLS mới cho INSERT/UPDATE: policy "Mentor can insert/update own assignments"
-- (batch 3) đã áp dụng cho toàn bộ dòng assignments của mentor, bao gồm cột class_id mới này.
