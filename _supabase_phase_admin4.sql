-- Phase: Admin classes v2 — thông báo lớp (class_announcements)

create table class_announcements (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  message text not null,
  created_at timestamptz not null default now(),
  created_by uuid references profiles(id)
);

alter table class_announcements enable row level security;

create policy "Admins can manage class_announcements"
  on class_announcements for all
  to authenticated
  using (public.is_current_user_admin())
  with check (public.is_current_user_admin());

create policy "Students can view own class announcements"
  on class_announcements for select
  to authenticated
  using (
    exists (
      select 1 from class_members cm
      where cm.class_id = class_announcements.class_id and cm.student_id = auth.uid()
    )
  );

create policy "Mentors can view own class announcements"
  on class_announcements for select
  to authenticated
  using (
    exists (
      select 1 from classes c
      where c.id = class_announcements.class_id and c.mentor_id = public.current_mentor_id()
    )
  );
