-- Phase: Admin panel v2 — approval gate, class chi tiết, role_permissions động

-- 1) profiles: cổng phê duyệt đăng ký
alter table profiles
  add column approval_status text not null default 'approved'
    check (approval_status in ('pending', 'approved', 'rejected')),
  add column approved_at timestamptz,
  add column approved_by uuid references profiles(id);

-- Backfill xong mới đổi default cho user MỚI đăng ký sau này (không khoá user cũ)
alter table profiles alter column approval_status set default 'pending';

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, phone, role, approval_status)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'role',
    'pending'
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- 2) classes: mở rộng thông tin lớp
alter table classes
  add column code text,
  add column phase_id uuid references phases(id) on delete set null,
  add column start_date date,
  add column end_date date,
  add column max_students int,
  add column mode text check (mode in ('offline', 'online', 'hybrid')),
  add column status text not null default 'active' check (status in ('draft', 'active', 'archived'));

-- 3) class_sessions: gán theo lớp (nullable = session chung cho tất cả, giữ hành vi cũ)
alter table class_sessions
  add column class_id uuid references classes(id) on delete cascade,
  add column mode text check (mode in ('offline', 'online', 'hybrid')),
  add column room text,
  add column order_index int,
  add column ends_at timestamptz;

-- 4) role_permissions: ma trận quyền động theo role x tính năng
create table role_permissions (
  id uuid primary key default gen_random_uuid(),
  role text not null check (role in ('student', 'mentor')),
  feature_key text not null,
  can_view boolean not null default false,
  can_add boolean not null default false,
  can_edit boolean not null default false,
  can_delete boolean not null default false,
  updated_at timestamptz not null default now(),
  unique (role, feature_key)
);

alter table role_permissions enable row level security;

create policy "Authenticated can read role_permissions"
  on role_permissions for select
  to authenticated
  using (true);

create policy "Admins can manage role_permissions"
  on role_permissions for all
  to authenticated
  using (public.is_current_user_admin())
  with check (public.is_current_user_admin());

-- Seed = đúng hành vi thật hiện tại cho cả 2 role (bật enforcement sau này là no-op
-- cho tới khi admin thật sự đổi 1 checkbox trong admin-permissions.html)
-- Lưu ý: 'documents'/can_add,can_delete ở đây gate hành vi "yêu thích/bỏ yêu thích tài liệu"
-- (document_favorites) — KHÔNG phải "tạo/xoá tài liệu trong CMS" (việc đó chỉ admin làm,
-- không có RLS insert nào cho non-admin nên không cần gate ở đây). Đặt true để khớp đúng
-- hành vi hiện tại (mọi authenticated user đang favorite/unfavorite tự do, không phân role).
insert into role_permissions (role, feature_key, can_view, can_add, can_edit, can_delete) values
  ('student', 'overview', true, false, false, false),
  ('student', 'assignments', true, true, true, false),
  ('student', 'case_studies', true, false, false, false),
  ('student', 'progress', true, false, false, false),
  ('student', 'community', true, true, false, false),
  ('student', 'schedule', true, true, false, false),
  ('student', 'documents', true, true, false, true),
  ('student', 'mentor', true, true, false, false),
  ('student', 'notifications', true, false, false, false),
  ('student', 'profile', true, false, true, false),
  ('student', 'account_settings', true, false, true, false),
  ('mentor', 'overview', true, false, false, false),
  ('mentor', 'assignments', true, false, false, false),
  ('mentor', 'case_studies', true, false, false, false),
  ('mentor', 'progress', true, false, false, false),
  ('mentor', 'community', true, true, false, false),
  ('mentor', 'schedule', true, true, false, false),
  ('mentor', 'documents', true, true, false, true),
  ('mentor', 'mentor', true, true, false, false),
  ('mentor', 'notifications', true, false, false, false),
  ('mentor', 'profile', true, false, true, false),
  ('mentor', 'account_settings', true, false, true, false);

-- 5) has_permission(): security definer, admin luôn bypass, không bao giờ bị role_permissions chặn ngược
create or replace function public.has_permission(p_feature_key text, p_action text default 'view')
returns boolean as $$
declare
  v_role text;
  v_allowed boolean;
begin
  if public.is_current_user_admin() then
    return true;
  end if;

  select case when coalesce(is_mentor, false) then 'mentor' else 'student' end
  into v_role
  from profiles where id = auth.uid();

  select case p_action
    when 'view' then can_view
    when 'add' then can_add
    when 'edit' then can_edit
    when 'delete' then can_delete
    else false
  end
  into v_allowed
  from role_permissions where role = v_role and feature_key = p_feature_key;

  return coalesce(v_allowed, false);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.has_permission(text, text) to authenticated;

-- 6) RLS restrictive bổ sung theo role_permissions — CỘNG THÊM lên policy hiện có,
-- không thay thế, không phá logic mentor-theo-lớp / ownership đang chạy.

create policy "Permission gate: submissions insert"
  on submissions as restrictive for insert
  to authenticated
  with check (public.has_permission('assignments', 'add'));

create policy "Permission gate: submissions update"
  on submissions as restrictive for update
  to authenticated
  using (public.has_permission('assignments', 'edit'))
  with check (public.has_permission('assignments', 'edit'));

create policy "Permission gate: messages insert"
  on messages as restrictive for insert
  to authenticated
  with check (public.has_permission('mentor', 'add'));

create policy "Permission gate: document_favorites insert"
  on document_favorites as restrictive for insert
  to authenticated
  with check (public.has_permission('documents', 'add'));

create policy "Permission gate: document_favorites delete"
  on document_favorites as restrictive for delete
  to authenticated
  using (public.has_permission('documents', 'delete'));

create policy "Permission gate: class_session_registrations insert"
  on class_session_registrations as restrictive for insert
  to authenticated
  with check (public.has_permission('schedule', 'add'));

create policy "Permission gate: profiles update own"
  on profiles as restrictive for update
  to authenticated
  using (
    public.is_current_user_admin()
    or public.has_permission('profile', 'edit')
    or public.has_permission('account_settings', 'edit')
  )
  with check (
    public.is_current_user_admin()
    or public.has_permission('profile', 'edit')
    or public.has_permission('account_settings', 'edit')
  );
