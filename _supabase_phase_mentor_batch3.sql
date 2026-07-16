-- Phase: Mentor self-service Batch 3 — Chấm bài, Quản lý bài tập, Học viên, Lộ trình học tập
-- Chạy trong Supabase SQL editor TRƯỚC khi dùng mentor-grading.html / mentor-assignments.html /
-- mentor-students.html / mentor-learning-path.html với tài khoản mentor thật.

-- 1) Bảng lộ trình học tập cá nhân hoá do mentor tạo cho từng học viên
create table learning_path_steps (
  id uuid primary key default gen_random_uuid(),
  mentor_id uuid not null references mentors(id) on delete cascade,
  student_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  description text,
  due_date date,
  status text not null default 'pending' check (status in ('pending', 'in_progress', 'done')),
  order_index int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table learning_path_steps enable row level security;

create policy "Mentor can read own students' path steps"
  on learning_path_steps for select
  to authenticated
  using (mentor_id in (select id from mentors where user_id = auth.uid()));

create policy "Mentor can insert own students' path steps"
  on learning_path_steps for insert
  to authenticated
  with check (mentor_id in (select id from mentors where user_id = auth.uid()));

create policy "Mentor can update own students' path steps"
  on learning_path_steps for update
  to authenticated
  using (mentor_id in (select id from mentors where user_id = auth.uid()))
  with check (mentor_id in (select id from mentors where user_id = auth.uid()));

create policy "Mentor can delete own students' path steps"
  on learning_path_steps for delete
  to authenticated
  using (mentor_id in (select id from mentors where user_id = auth.uid()));

-- 2) Mentor tự quản lý bài tập (assignments) do mình phụ trách
alter table assignments enable row level security;

create policy "Mentor can insert own assignments"
  on assignments for insert
  to authenticated
  with check (mentor_id in (select id from mentors where user_id = auth.uid()));

create policy "Mentor can update own assignments"
  on assignments for update
  to authenticated
  using (mentor_id in (select id from mentors where user_id = auth.uid()))
  with check (mentor_id in (select id from mentors where user_id = auth.uid()));

create policy "Mentor can delete own assignments"
  on assignments for delete
  to authenticated
  using (mentor_id in (select id from mentors where user_id = auth.uid()));

-- 3) Mentor quản lý câu hỏi quiz cho bài tập loại quiz do mình phụ trách
alter table quiz_questions enable row level security;

create policy "Mentor can read quiz questions of own assignments"
  on quiz_questions for select
  to authenticated
  using (
    assignment_id in (
      select a.id from assignments a
      join mentors m on m.id = a.mentor_id
      where m.user_id = auth.uid()
    )
  );

create policy "Mentor can insert quiz questions of own assignments"
  on quiz_questions for insert
  to authenticated
  with check (
    assignment_id in (
      select a.id from assignments a
      join mentors m on m.id = a.mentor_id
      where m.user_id = auth.uid()
    )
  );

create policy "Mentor can delete quiz questions of own assignments"
  on quiz_questions for delete
  to authenticated
  using (
    assignment_id in (
      select a.id from assignments a
      join mentors m on m.id = a.mentor_id
      where m.user_id = auth.uid()
    )
  );

-- 4) QUAN TRỌNG: mở khoá cho mentor được UPDATE bảng submissions (lưu điểm/feedback khi chấm bài).
--    Bảng role_permissions đang có policy RESTRICTIVE "Permission gate: submissions update"
--    yêu cầu has_permission('assignments','edit') = true. Seed cũ đặt can_edit=false cho
--    role='mentor' (vì cột này ban đầu chỉ dành cho học viên tự sửa bài nộp của mình).
--    Bật can_edit=true cho mentor để mentor chấm được bài — không ảnh hưởng tới học viên
--    (mỗi role có 1 dòng role_permissions riêng).
update role_permissions set can_edit = true, updated_at = now()
  where role = 'mentor' and feature_key = 'assignments';

-- 5) Mentor đọc được toàn bộ học viên thuộc lớp mình phụ trách (trang "Học viên" tổng hợp)
--    (đã có policy tương tự cho class_members ở batch 1; thêm policy đọc profiles nếu cần)
create policy "Mentor can read profiles of own students"
  on profiles for select
  to authenticated
  using (
    id in (
      select cm.student_id from class_members cm
      join classes c on c.id = cm.class_id
      join mentors m on m.id = c.mentor_id
      where m.user_id = auth.uid()
    )
  );
