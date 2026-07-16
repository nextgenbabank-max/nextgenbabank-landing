-- Phase: Mentor Batch 5 — Quản lý câu hỏi (Quiz / Case Study / Project wizard)
-- Chạy trong Supabase SQL editor TRƯỚC khi dùng bản mentor-assignments.html mới
-- ("Quản lý câu hỏi" — màn hình tạo câu hỏi 3 bước).

alter table assignments
  add column objective text,
  add column deliverables text,
  add column student_notes text,
  add column reference_url text,
  add column quiz_time_limit_minutes int,
  add column quiz_shuffle_answers boolean not null default false,
  add column quiz_show_score_after_submit boolean not null default true;

-- Không cần policy RLS mới: các policy "Mentor can insert/update own assignments"
-- (batch 3) áp dụng cho toàn bộ dòng, bao gồm các cột mới này.
