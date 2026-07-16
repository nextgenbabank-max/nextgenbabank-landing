-- Phase: Trạng thái bài tập đầy đủ (draft/submitted/graded/needs_revision) + lịch sử phiên bản
-- nộp bài (không ghi đè/xoá lịch sử nộp bài và lịch sử chấm điểm).
-- KHÔNG đổi hành vi cột submissions.graded hiện có — mentor-grading.html (bản cũ trước khi
-- sửa), dashboard.html, notifications.js vẫn đọc đúng nhờ trigger đồng bộ 1 chiều status->graded.

-- 1) submissions: thêm cột mới, không đụng cột cũ
alter table submissions
  add column if not exists status text not null default 'submitted'
    check (status in ('draft', 'submitted', 'graded', 'needs_revision')),
  add column if not exists note_to_mentor text,
  add column if not exists current_version_number int not null default 1,
  add column if not exists revision_due_at timestamptz,
  add column if not exists revision_reason text,
  add column if not exists feedback_summary text,
  add column if not exists feedback_strengths text,
  add column if not exists feedback_improve text,
  add column if not exists feedback_criteria jsonb,
  add column if not exists graded_by uuid references mentors(id);

-- Backfill: dữ liệu cũ suy status từ graded boolean đang có
update submissions set status = 'graded' where graded = true and status = 'submitted';

-- 2) Trigger đồng bộ 1 chiều status -> graded, để mọi trang đọc `graded` boolean vẫn đúng
create or replace function public.sync_submission_graded_flag()
returns trigger as $$
begin
  if new.status = 'graded' then
    new.graded := true;
    if new.graded_at is null then new.graded_at := now(); end if;
  else
    new.graded := false;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists submissions_sync_graded on submissions;
create trigger submissions_sync_graded
  before insert or update on submissions
  for each row execute procedure public.sync_submission_graded_flag();

-- 3) Lịch sử phiên bản nộp bài — append-only, chỉ RPC security definer bên dưới mới ghi được
--    (không có policy insert cho client trực tiếp -> bắt buộc đi qua RPC, tránh sai lệch version_number)
create table if not exists submission_versions (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references submissions(id) on delete cascade,
  version_number int not null,
  action text not null check (action in ('draft_saved', 'submitted', 'graded', 'revision_requested')),
  answer_text text,
  quiz_answers jsonb,
  note_to_mentor text,
  score numeric,
  max_score numeric,
  feedback_summary text,
  feedback_strengths text,
  feedback_improve text,
  feedback_criteria jsonb,
  revision_due_at timestamptz,
  revision_reason text,
  created_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  unique (submission_id, version_number)
);

alter table submission_versions enable row level security;

drop policy if exists "Students can view own submission version history" on submission_versions;
create policy "Students can view own submission version history"
  on submission_versions for select to authenticated
  using (submission_id in (select id from submissions where user_id = auth.uid()));

drop policy if exists "Mentor can view version history of own assignments" on submission_versions;
create policy "Mentor can view version history of own assignments"
  on submission_versions for select to authenticated
  using (
    submission_id in (
      select s.id from submissions s
      join assignments a on a.id = s.assignment_id
      join mentors m on m.id = a.mentor_id
      where m.user_id = auth.uid()
    )
  );

drop policy if exists "Admin manage all submission_versions" on submission_versions;
create policy "Admin manage all submission_versions"
  on submission_versions for all to authenticated
  using (public.is_current_user_admin())
  with check (public.is_current_user_admin());

-- 4) File/link đính kèm mỗi phiên bản — thay path Storage cố định (upsert đè) bằng path
--    theo version (userId/assignmentId/v{n}/{timestamp}-{filename}, không upsert), không mất bản cũ
create table if not exists submission_files (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references submission_versions(id) on delete cascade,
  file_path text,
  drive_link text,
  file_name text,
  file_size int,
  file_type text,
  created_at timestamptz not null default now(),
  constraint submission_files_source check (file_path is not null or drive_link is not null)
);

alter table submission_files enable row level security;

drop policy if exists "Students can view own submission files" on submission_files;
create policy "Students can view own submission files"
  on submission_files for select to authenticated
  using (version_id in (
    select sv.id from submission_versions sv
    join submissions s on s.id = sv.submission_id
    where s.user_id = auth.uid()
  ));

drop policy if exists "Mentor can view submission files of own assignments" on submission_files;
create policy "Mentor can view submission files of own assignments"
  on submission_files for select to authenticated
  using (version_id in (
    select sv.id from submission_versions sv
    join submissions s on s.id = sv.submission_id
    join assignments a on a.id = s.assignment_id
    join mentors m on m.id = a.mentor_id
    where m.user_id = auth.uid()
  ));

drop policy if exists "Admin manage all submission_files" on submission_files;
create policy "Admin manage all submission_files"
  on submission_files for all to authenticated
  using (public.is_current_user_admin())
  with check (public.is_current_user_admin());

-- 5) RPC: học viên lưu nháp / nộp bài / nộp lại — 1 điểm ghi duy nhất, đảm bảo version_number
--    tăng đúng, chặn nộp khi đã graded (trừ khi mentor request revision trước)
create or replace function public.submit_assignment_version(
  p_assignment_id uuid,
  p_action text,
  p_answer_text text default null,
  p_note_to_mentor text default null,
  p_files jsonb default '[]'::jsonb
)
returns uuid as $$
declare
  v_submission_id uuid;
  v_type text;
  v_current_status text;
  v_next_version int;
  v_version_id uuid;
  v_item jsonb;
begin
  if p_action not in ('draft_saved', 'submitted') then
    raise exception 'Invalid action';
  end if;

  select type into v_type from assignments where id = p_assignment_id;
  if v_type is null then raise exception 'Assignment not found'; end if;

  select id, status into v_submission_id, v_current_status
    from submissions where assignment_id = p_assignment_id and user_id = auth.uid();

  if v_submission_id is null then
    insert into submissions (assignment_id, user_id, type, status, current_version_number, note_to_mentor, answer_text, submitted_at)
    values (
      p_assignment_id, auth.uid(), v_type,
      case when p_action = 'draft_saved' then 'draft' else 'submitted' end,
      1, p_note_to_mentor, p_answer_text,
      case when p_action = 'submitted' then now() else null end
    )
    returning id into v_submission_id;
    v_next_version := 1;
  else
    if v_current_status = 'graded' then
      raise exception 'Bài đã được chấm, không thể nộp lại trừ khi mentor yêu cầu chỉnh sửa';
    end if;
    select coalesce(max(version_number), 0) + 1 into v_next_version
      from submission_versions where submission_id = v_submission_id;
    update submissions set
      status = case when p_action = 'draft_saved' then 'draft' else 'submitted' end,
      note_to_mentor = p_note_to_mentor,
      answer_text = p_answer_text,
      current_version_number = v_next_version,
      submitted_at = case when p_action = 'submitted' then now() else submitted_at end
    where id = v_submission_id;
  end if;

  insert into submission_versions (submission_id, version_number, action, answer_text, note_to_mentor, created_by)
  values (v_submission_id, v_next_version, p_action, p_answer_text, p_note_to_mentor, auth.uid())
  returning id into v_version_id;

  for v_item in select * from jsonb_array_elements(p_files) loop
    insert into submission_files (version_id, file_path, drive_link, file_name, file_size, file_type)
    values (
      v_version_id,
      v_item->>'file_path', v_item->>'drive_link', v_item->>'file_name',
      nullif(v_item->>'file_size', '')::int, v_item->>'file_type'
    );
  end loop;

  return v_submission_id;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.submit_assignment_version(uuid, text, text, text, jsonb) to authenticated;

-- 6) RPC: mentor chấm điểm chi tiết (thay UPDATE submissions trực tiếp trong mentor-grading.html)
create or replace function public.grade_submission(
  p_submission_id uuid,
  p_score numeric,
  p_max_score numeric,
  p_summary text default null,
  p_strengths text default null,
  p_improve text default null,
  p_criteria jsonb default null
)
returns void as $$
declare
  v_mentor_id uuid;
  v_next_version int;
begin
  select m.id into v_mentor_id
    from submissions s
    join assignments a on a.id = s.assignment_id
    join mentors m on m.id = a.mentor_id
    where s.id = p_submission_id and m.user_id = auth.uid();

  if v_mentor_id is null and not public.is_current_user_admin() then
    raise exception 'Not authorized';
  end if;

  update submissions set
    status = 'graded',
    score = p_score,
    max_score = p_max_score,
    feedback = coalesce(p_summary, feedback),
    feedback_summary = p_summary,
    feedback_strengths = p_strengths,
    feedback_improve = p_improve,
    feedback_criteria = p_criteria,
    graded_by = v_mentor_id,
    graded_at = now()
  where id = p_submission_id;

  select coalesce(max(version_number), 0) + 1 into v_next_version
    from submission_versions where submission_id = p_submission_id;

  insert into submission_versions (
    submission_id, version_number, action, score, max_score,
    feedback_summary, feedback_strengths, feedback_improve, feedback_criteria, created_by
  ) values (
    p_submission_id, v_next_version, 'graded', p_score, p_max_score,
    p_summary, p_strengths, p_improve, p_criteria, auth.uid()
  );
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.grade_submission(uuid, numeric, numeric, text, text, text, jsonb) to authenticated;

-- 7) RPC: mentor yêu cầu học viên chỉnh sửa (mở lại quyền nộp bài dù đã nộp trước đó)
create or replace function public.request_submission_revision(
  p_submission_id uuid,
  p_reason text,
  p_due_at timestamptz default null
)
returns void as $$
declare
  v_mentor_id uuid;
  v_next_version int;
begin
  select m.id into v_mentor_id
    from submissions s
    join assignments a on a.id = s.assignment_id
    join mentors m on m.id = a.mentor_id
    where s.id = p_submission_id and m.user_id = auth.uid();

  if v_mentor_id is null and not public.is_current_user_admin() then
    raise exception 'Not authorized';
  end if;

  update submissions set
    status = 'needs_revision',
    revision_reason = p_reason,
    revision_due_at = p_due_at
  where id = p_submission_id;

  select coalesce(max(version_number), 0) + 1 into v_next_version
    from submission_versions where submission_id = p_submission_id;

  insert into submission_versions (
    submission_id, version_number, action, revision_reason, revision_due_at, created_by
  ) values (
    p_submission_id, v_next_version, 'revision_requested', p_reason, p_due_at, auth.uid()
  );
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.request_submission_revision(uuid, text, timestamptz) to authenticated;
