-- Phase: Mentor Inbox redesign (Batch 2) — mentor-inbox.html + mentor.html sync
-- Chạy trong Supabase SQL editor TRƯỚC khi dùng bản mentor-inbox.html / mentor.html mới.

-- 1) Ghi chú của mentor về từng học viên (điểm mạnh/điểm cần cải thiện/định hướng)
create table student_notes (
  id uuid primary key default gen_random_uuid(),
  mentor_id uuid not null references mentors(id) on delete cascade,
  student_id uuid not null references profiles(id) on delete cascade,
  note text not null default '',
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id),
  unique (mentor_id, student_id)
);

alter table student_notes enable row level security;

create policy "Mentor can read own student notes"
  on student_notes for select
  to authenticated
  using (mentor_id in (select id from mentors where user_id = auth.uid()));

create policy "Mentor can insert own student notes"
  on student_notes for insert
  to authenticated
  with check (mentor_id in (select id from mentors where user_id = auth.uid()));

create policy "Mentor can update own student notes"
  on student_notes for update
  to authenticated
  using (mentor_id in (select id from mentors where user_id = auth.uid()))
  with check (mentor_id in (select id from mentors where user_id = auth.uid()));

-- 2) Đính kèm file trong tin nhắn (mentor <-> học viên)
alter table messages
  add column file_url text,
  add column file_name text,
  add column file_size int;

-- 3) Cho phép mentor cập nhật read_at khi mở 1 luồng chat (đánh dấu đã đọc)
--    (insert đã có policy "Permission gate: messages insert" từ trước; đây là UPDATE mới)
create policy "Mentor can mark student messages as read"
  on messages for update
  to authenticated
  using (
    student_id in (
      select cm.student_id from class_members cm
      join classes c on c.id = cm.class_id
      join mentors m on m.id = c.mentor_id
      where m.user_id = auth.uid()
    )
  )
  with check (
    student_id in (
      select cm.student_id from class_members cm
      join classes c on c.id = cm.class_id
      join mentors m on m.id = c.mentor_id
      where m.user_id = auth.uid()
    )
  );

-- 4) LƯU Ý THỦ CÔNG (không chạy được bằng SQL): tạo Storage bucket trước.
--    Vào Supabase Dashboard > Storage > New bucket:
--      - Tên bucket: chat-attachments
--      - Public: OFF (private, giống bucket "submissions" đang có)
--    Sau khi tạo xong bucket, chạy tiếp phần policy bên dưới (SQL, chạy được bình thường).

create policy "Authenticated can upload chat attachments"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'chat-attachments');

create policy "Authenticated can read chat attachments"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'chat-attachments');
