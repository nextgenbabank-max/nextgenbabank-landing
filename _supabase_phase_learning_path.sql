-- Phase: Thiết kế lộ trình học — modules mở rộng, case_studies gắn module, due_offset_days,
-- assignments type 'project', hardening class_sessions.module_id, RPC nhân bản lộ trình.

-- 1) modules: mở rộng thông tin buổi học
alter table modules
  add column objectives text,
  add column duration_minutes int,
  add column is_visible boolean not null default true;

-- 2) case_studies: gắn vào 1 buổi học cụ thể + hạn nộp tương đối
alter table case_studies
  add column module_id uuid references modules(id) on delete set null,
  add column due_offset_days int;

-- 3) documents: gắn vào 1 buổi học cụ thể (ngoài phase_id đã có)
alter table documents
  add column module_id uuid references modules(id) on delete set null;

-- 4) assignments: hạn nộp tương đối + loại 'project'
alter table assignments
  add column due_offset_days int;

alter table assignments drop constraint if exists assignments_type_check;
alter table assignments add constraint assignments_type_check
  check (type in ('quiz', 'essay', 'file', 'project'));

-- 5) class_sessions: hardening liên kết buổi học <-> session thật (FK thay vì chỉ khớp order_index lỏng lẻo)
alter table class_sessions
  add column module_id uuid references modules(id) on delete set null;

update class_sessions cs
set module_id = m.id
from classes c
join modules m on m.phase_id = c.phase_id and m.order_index = cs.order_index
where cs.class_id = c.id
  and cs.module_id is null
  and cs.order_index is not null;

-- 6) RLS: modules chỉ hiện cho học viên/mentor khi is_visible=true (admin luôn thấy hết)
create policy "Non-admins see only visible modules"
  on modules as restrictive for select
  to authenticated
  using (public.is_current_user_admin() or is_visible = true);

-- 7) RPC: nhân bản 1 lộ trình (phase) kèm modules + assignments + case_studies + quiz_questions
create or replace function public.duplicate_phase(p_phase_id uuid)
returns uuid as $$
declare
  v_new_phase_id uuid;
  v_old_phase record;
  v_max_order int;
  r_module record;
  v_new_module_id uuid;
  r_assignment record;
  v_new_assignment_id uuid;
  r_case_study record;
  v_new_case_study_id uuid;
  r_task record;
  r_question record;
begin
  if not public.is_current_user_admin() then
    raise exception 'Not authorized';
  end if;

  select * into v_old_phase from phases where id = p_phase_id;
  if v_old_phase is null then
    raise exception 'Phase not found';
  end if;

  select coalesce(max(order_index), 0) + 1 into v_max_order from phases;

  insert into phases (title, description, order_index)
  values (v_old_phase.title || ' (bản sao)', v_old_phase.description, v_max_order)
  returning id into v_new_phase_id;

  create temporary table module_id_map (old_id uuid primary key, new_id uuid) on commit drop;

  for r_module in select * from modules where phase_id = p_phase_id order by order_index loop
    insert into modules (title, order_index, description, phase_id, objectives, duration_minutes, is_visible)
    values (r_module.title, r_module.order_index, r_module.description, v_new_phase_id, r_module.objectives, r_module.duration_minutes, r_module.is_visible)
    returning id into v_new_module_id;
    insert into module_id_map (old_id, new_id) values (r_module.id, v_new_module_id);
  end loop;

  for r_assignment in
    select a.* from assignments a
    join module_id_map mm on mm.old_id = a.module_id
  loop
    insert into assignments (module_id, title, type, description, max_score, due_date, doc_type, phase_id, mentor_id, due_offset_days)
    values (
      (select new_id from module_id_map where old_id = r_assignment.module_id),
      r_assignment.title, r_assignment.type, r_assignment.description, r_assignment.max_score,
      r_assignment.due_date, r_assignment.doc_type, v_new_phase_id, r_assignment.mentor_id, r_assignment.due_offset_days
    )
    returning id into v_new_assignment_id;

    if r_assignment.type = 'quiz' then
      for r_question in select * from quiz_questions where assignment_id = r_assignment.id order by order_index loop
        insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index)
        values (v_new_assignment_id, r_question.question_text, r_question.options, r_question.correct_index, r_question.order_index);
      end loop;
    end if;
  end loop;

  for r_case_study in
    select cs.* from case_studies cs
    join module_id_map mm on mm.old_id = cs.module_id
  loop
    insert into case_studies (title, domain, description, mentor_id, due_date, order_index, module_id, due_offset_days)
    values (
      r_case_study.title, r_case_study.domain, r_case_study.description, r_case_study.mentor_id,
      r_case_study.due_date, r_case_study.order_index,
      (select new_id from module_id_map where old_id = r_case_study.module_id),
      r_case_study.due_offset_days
    )
    returning id into v_new_case_study_id;

    for r_task in select * from case_study_tasks where case_study_id = r_case_study.id order by order_index loop
      insert into case_study_tasks (case_study_id, title, order_index)
      values (v_new_case_study_id, r_task.title, r_task.order_index);
    end loop;
  end loop;

  return v_new_phase_id;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.duplicate_phase(uuid) to authenticated;
