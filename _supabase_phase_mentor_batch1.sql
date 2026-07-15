-- Phase: Mentor self-service Batch 1 — mentor-dashboard.html + mentor-classes.html
-- Chạy file này trong Supabase SQL editor TRƯỚC khi dùng 2 trang mentor-dashboard.html /
-- mentor-classes.html với tài khoản mentor thật. Không đụng tới policy admin hiện có —
-- các policy dưới đây là PERMISSIVE (cộng thêm quyền), không thay thế policy nào.

-- 0) Đảm bảo RLS đang bật (no-op nếu đã bật sẵn)
alter table classes enable row level security;
alter table class_members enable row level security;
alter table class_sessions enable row level security;
alter table mentors enable row level security;
alter table assignments enable row level security;
alter table submissions enable row level security;
alter table module_progress enable row level security;

-- 1) Mentor đọc được chính hồ sơ mentor của mình (để resolve mentors.id từ auth.uid())
create policy "Mentor can read own mentor row"
  on mentors for select
  to authenticated
  using (user_id = auth.uid());

-- 2) Mentor đọc được các lớp mình phụ trách
create policy "Mentor can read own classes"
  on classes for select
  to authenticated
  using (
    mentor_id in (select id from mentors where user_id = auth.uid())
  );

-- 3) Mentor đọc được danh sách học viên (class_members) của lớp mình phụ trách
create policy "Mentor can read own class members"
  on class_members for select
  to authenticated
  using (
    class_id in (
      select c.id from classes c
      join mentors m on m.id = c.mentor_id
      where m.user_id = auth.uid()
    )
  );

-- 4) Mentor đọc + SỬA buổi học (giờ/phòng/hình thức/link Meet) của lớp mình phụ trách
create policy "Mentor can read own class sessions"
  on class_sessions for select
  to authenticated
  using (
    class_id in (
      select c.id from classes c
      join mentors m on m.id = c.mentor_id
      where m.user_id = auth.uid()
    )
  );

create policy "Mentor can update own class sessions"
  on class_sessions for update
  to authenticated
  using (
    class_id in (
      select c.id from classes c
      join mentors m on m.id = c.mentor_id
      where m.user_id = auth.uid()
    )
  )
  with check (
    class_id in (
      select c.id from classes c
      join mentors m on m.id = c.mentor_id
      where m.user_id = auth.uid()
    )
  );

-- 5) Mentor đọc bài tập do mình phụ trách (đếm "bài chờ chấm" trên dashboard)
create policy "Mentor can read own assignments"
  on assignments for select
  to authenticated
  using (
    mentor_id in (select id from mentors where user_id = auth.uid())
  );

-- 6) Mentor đọc bài nộp của học viên ứng với bài tập mình phụ trách
--    (feed "Bài tập cần chấm" trên dashboard + tính % tiến độ học viên trong mentor-classes.html)
create policy "Mentor can read submissions for own assignments"
  on submissions for select
  to authenticated
  using (
    assignment_id in (
      select a.id from assignments a
      join mentors m on m.id = a.mentor_id
      where m.user_id = auth.uid()
    )
  );

-- 7) Mentor đọc tiến độ module_progress của học viên thuộc lớp mình phụ trách
--    (dùng để tính % tiến độ tổng thể hiển thị trong roster ở mentor-classes.html)
create policy "Mentor can read module_progress of own students"
  on module_progress for select
  to authenticated
  using (
    user_id in (
      select cm.student_id from class_members cm
      join classes c on c.id = cm.class_id
      join mentors m on m.id = c.mentor_id
      where m.user_id = auth.uid()
    )
  );
