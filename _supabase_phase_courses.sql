-- Phase: Chức năng "Xem khóa học" (course catalog + đăng ký tư vấn + nhận đề cương)
-- Bảng mới dùng tiền tố course_* / consultation_* để không đụng bảng `registrations` đã có
-- (form đăng ký quan tâm chung ở trang chủ — khác phạm vi, không đổi).

-- ============================================================
-- 1) courses
-- ============================================================
create table if not exists courses (
  id uuid primary key default gen_random_uuid(),
  course_code text not null unique,
  slug text not null unique,
  name text not null,
  short_description text not null,
  number_of_stages int,
  number_of_sessions int,
  original_price numeric not null,
  sale_price numeric not null,
  discount_percent int not null default 50,
  stage_original_price numeric,
  stage_sale_price numeric,
  allow_stage_payment boolean not null default false,
  class_size int,
  learning_format text,
  tools text,
  messenger_url text,
  zalo_url text,
  syllabus_file_url text,
  status text not null default 'PUBLISHED' check (status in ('DRAFT', 'PUBLISHED', 'CLOSED')),
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_courses_status on courses(status);
create index if not exists idx_courses_slug on courses(slug);

-- ============================================================
-- 2) course_syllabus_requests
-- ============================================================
create table if not exists course_syllabus_requests (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses(id) on delete cascade,
  course_slug text not null,
  full_name text,
  email text not null,
  phone_zalo text,
  consent boolean not null,
  source_page text,
  source_url text,
  status text not null default 'NEW' check (status in ('NEW', 'CONTACTED', 'DONE')),
  created_at timestamptz not null default now()
);

create index if not exists idx_syllabus_requests_course on course_syllabus_requests(course_id);
create index if not exists idx_syllabus_requests_email_course_time on course_syllabus_requests(email, course_id, created_at desc);

-- ============================================================
-- 3) consultation_events
-- ============================================================
create table if not exists consultation_events (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references courses(id) on delete set null,
  selected_channel text not null check (selected_channel in ('messenger', 'zalo')),
  source_page text,
  source_url text,
  device_type text,
  created_at timestamptz not null default now()
);

create index if not exists idx_consultation_events_course on consultation_events(course_id);

-- ============================================================
-- 4) RLS
-- ============================================================
alter table courses enable row level security;
alter table course_syllabus_requests enable row level security;
alter table consultation_events enable row level security;

-- Courses: ai cũng xem được khóa đã PUBLISHED; chỉ admin ghi.
drop policy if exists "Public read published courses" on courses;
create policy "Public read published courses" on courses
  for select to anon, authenticated
  using (status = 'PUBLISHED' or public.is_current_user_admin());

drop policy if exists "Admin write courses" on courses;
create policy "Admin write courses" on courses
  for all to authenticated
  using (public.is_current_user_admin())
  with check (public.is_current_user_admin());

-- Syllabus requests: chứa PII (email/phone) — KHÔNG cấp insert trực tiếp cho anon,
-- mọi lượt ghi phải qua RPC submit_syllabus_request() (security definer, có chống trùng).
-- Chỉ admin được đọc để theo dõi và gửi thủ công.
drop policy if exists "Admin read syllabus requests" on course_syllabus_requests;
create policy "Admin read syllabus requests" on course_syllabus_requests
  for select to authenticated using (public.is_current_user_admin());

drop policy if exists "Admin update syllabus requests" on course_syllabus_requests;
create policy "Admin update syllabus requests" on course_syllabus_requests
  for update to authenticated
  using (public.is_current_user_admin())
  with check (public.is_current_user_admin());

-- Consultation events: không có PII, cho phép ghi trực tiếp từ client (giống bảng `registrations`),
-- không cho đọc để tránh lộ hành vi người dùng khác.
drop policy if exists "Public insert consultation events" on consultation_events;
create policy "Public insert consultation events" on consultation_events
  for insert to anon, authenticated with check (true);

drop policy if exists "Admin read consultation events" on consultation_events;
create policy "Admin read consultation events" on consultation_events
  for select to authenticated using (public.is_current_user_admin());

-- ============================================================
-- 5) updated_at auto-touch (dùng chung nếu chưa có hàm chung nào áp cho courses)
-- ============================================================
create or replace function public.courses_touch_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trg_courses_touch_updated_at on courses;
create trigger trg_courses_touch_updated_at
  before update on courses
  for each row execute function public.courses_touch_updated_at();

-- ============================================================
-- 6) RPC: submit_syllabus_request — ghi yêu cầu nhận đề cương, chống trùng 30 phút
-- ============================================================
create or replace function public.submit_syllabus_request(
  p_course_id uuid,
  p_full_name text,
  p_email text,
  p_phone text,
  p_consent boolean,
  p_source_page text,
  p_source_url text
) returns jsonb as $$
declare
  v_course courses;
  v_dup_exists boolean;
  v_new_id uuid;
begin
  if p_consent is distinct from true then
    return jsonb_build_object('success', false, 'error_code', 'CONSENT_REQUIRED',
      'message', 'Vui lòng đồng ý nhận đề cương và thông tin liên quan đến khóa học.');
  end if;

  if p_email is null or p_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    return jsonb_build_object('success', false, 'error_code', 'INVALID_EMAIL',
      'message', 'Email chưa đúng định dạng. Vui lòng kiểm tra lại.');
  end if;

  select * into v_course from courses where id = p_course_id and status = 'PUBLISHED';
  if v_course is null then
    return jsonb_build_object('success', false, 'error_code', 'COURSE_NOT_FOUND',
      'message', 'Không tìm thấy khóa học tương ứng.');
  end if;

  -- Chống trùng: cùng email + khóa học gửi lại trong 30 phút gần nhất
  select exists (
    select 1 from course_syllabus_requests r
    where r.course_id = p_course_id
      and lower(r.email) = lower(p_email)
      and r.created_at > now() - interval '30 minutes'
  ) into v_dup_exists;

  if v_dup_exists then
    return jsonb_build_object('success', true, 'duplicate', true,
      'message', 'Yêu cầu của bạn đã được ghi nhận trước đó, đội ngũ sẽ liên hệ sớm.');
  end if;

  insert into course_syllabus_requests (
    course_id, course_slug, full_name, email, phone_zalo, consent, source_page, source_url
  ) values (
    p_course_id, v_course.slug, nullif(trim(p_full_name), ''), trim(p_email), nullif(trim(p_phone), ''),
    p_consent, p_source_page, p_source_url
  ) returning id into v_new_id;

  return jsonb_build_object('success', true, 'duplicate', false, 'request_id', v_new_id);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.submit_syllabus_request(uuid, text, text, text, boolean, text, text) to anon, authenticated;

-- ============================================================
-- 7) Seed 5 khóa học (giá theo đợt ưu đãi 50%, xem đặc tả §4)
-- ============================================================
insert into courses (
  course_code, slug, name, short_description, number_of_stages, number_of_sessions,
  original_price, sale_price, discount_percent, stage_original_price, stage_sale_price,
  allow_stage_payment, class_size, learning_format, tools, messenger_url, zalo_url,
  status, display_order
) values
(
  'BA_FOUNDATION', 'ba-foundation', 'BA Foundation',
  'Xây dựng nền tảng Business Analysis Banking có hệ thống.',
  2, 12, 9198000, 4599000, 50, null, null, false,
  20, 'Offline / Online', 'Word, Excel, PPT, BPMN Tools',
  'https://m.me/nextgenbabanker', 'https://zalo.me/0815171251', 'PUBLISHED', 1
),
(
  'BANKING_DOMAIN', 'banking-domain', 'Banking Domain for BA',
  'Làm chủ nghiệp vụ ngân hàng dưới góc nhìn Business Analyst.',
  6, 20, 14398000, 7199000, 50, 2598000, 1299000, true,
  16, 'Offline / Online', 'Word, BPMN, Draw.io, SQL cơ bản',
  'https://m.me/nextgenbabanker', 'https://zalo.me/0815171251', 'PUBLISHED', 2
),
(
  'API_DATA_INTEGRATION', 'api-data-integration', 'API, Data & System Integration for BA',
  'Hiểu kỹ thuật đủ sâu để làm việc hiệu quả với đội IT.',
  3, 8, 7198000, 3599000, 50, 2598000, 1299000, true,
  20, 'Offline / Online', 'Postman, Swagger, Draw.io, SQL Editor',
  'https://m.me/nextgenbabanker', 'https://zalo.me/0815171251', 'PUBLISHED', 3
),
(
  'BANKING_PROJECT_PRACTICE', 'banking-project-practice', 'Banking Project Practice',
  'Thực hành dự án BA Banking từ phân tích đến triển khai.',
  3, 8, 7198000, 3599000, 50, 2598000, 1299000, true,
  16, 'Offline / Online', 'Word, Excel, Draw.io, Figma, Postman',
  'https://m.me/nextgenbabanker', 'https://zalo.me/0815171251', 'PUBLISHED', 4
),
(
  'AI_FOR_BA', 'ai-for-business-analyst', 'AI for Business Analyst',
  'Ứng dụng AI để nâng cao hiệu suất và chất lượng công việc BA.',
  null, 12, 7998000, 3999000, 50, null, null, false,
  16, 'Online', 'Claude Projects / Custom GPT (no-code)',
  'https://m.me/nextgenbabanker', 'https://zalo.me/0815171251', 'PUBLISHED', 5
)
on conflict (course_code) do nothing;
