-- Phase: Thư viện tài liệu tham khảo (public reference document library)
-- Bảng mới dùng tiền tố library_* để KHÔNG đụng vào bảng `documents` / `document_favorites`
-- đã tồn tại (dùng cho tính năng "Tài liệu của tôi" theo lớp/module — khác phạm vi).

-- ============================================================
-- 1) library_categories
-- ============================================================
create table if not exists library_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  display_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 2) library_documents
-- ============================================================
create table if not exists library_documents (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references library_categories(id) on delete cascade,
  title text not null,
  slug text not null,
  description text,
  file_type text not null default 'pdf',
  drive_url text not null,
  drive_file_id text not null,
  thumbnail_url text,
  total_pages int,
  file_size_bytes bigint,
  author_name text,
  difficulty_level text check (difficulty_level in ('beginner', 'intermediate', 'advanced')),
  version text,
  published_at timestamptz,
  is_viewable boolean not null default true,
  is_drive_open_enabled boolean not null default true,
  is_download_link_enabled boolean not null default false,
  requires_login boolean not null default false,
  view_count bigint not null default 0,
  drive_open_count bigint not null default 0,
  download_click_count bigint not null default 0,
  favorite_count bigint not null default 0,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (category_id, slug)
);

create index if not exists idx_library_documents_category on library_documents(category_id);
create index if not exists idx_library_documents_status on library_documents(status);
create index if not exists idx_library_documents_slug on library_documents(slug);

-- ============================================================
-- 3) library_document_view_sessions
-- ============================================================
create table if not exists library_document_view_sessions (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references library_documents(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  anonymous_id text,
  session_id text not null unique default gen_random_uuid()::text,
  started_at timestamptz not null default now(),
  last_heartbeat_at timestamptz,
  ended_at timestamptz,
  active_duration_seconds int not null default 0,
  viewer_loaded_successfully boolean not null default false,
  is_valid_view boolean not null default false,
  view_counted_at timestamptz,
  device_type text,
  browser text,
  operating_system text,
  ip_hash text,
  user_agent_hash text,
  referrer text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_library_view_sessions_doc on library_document_view_sessions(document_id);
create index if not exists idx_library_view_sessions_identity on library_document_view_sessions(document_id, user_id, anonymous_id, started_at desc);

-- ============================================================
-- 4) library_document_drive_open_logs
-- ============================================================
create table if not exists library_document_drive_open_logs (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references library_documents(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  anonymous_id text,
  view_session_id uuid references library_document_view_sessions(id) on delete set null,
  opened_url text not null,
  source_page text,
  opened_at timestamptz not null default now(),
  device_type text,
  browser text,
  operating_system text,
  ip_hash text,
  user_agent_hash text,
  created_at timestamptz not null default now()
);

create index if not exists idx_library_drive_open_logs_doc on library_document_drive_open_logs(document_id);

-- ============================================================
-- 5) library_document_download_click_logs
-- ============================================================
create table if not exists library_document_download_click_logs (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references library_documents(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  anonymous_id text,
  view_session_id uuid references library_document_view_sessions(id) on delete set null,
  clicked_url text not null,
  clicked_at timestamptz not null default now(),
  device_type text,
  browser text,
  operating_system text,
  ip_hash text,
  user_agent_hash text,
  created_at timestamptz not null default now()
);

create index if not exists idx_library_download_click_logs_doc on library_document_download_click_logs(document_id);

-- ============================================================
-- 6) library_document_favorites
-- ============================================================
create table if not exists library_document_favorites (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references library_documents(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (document_id, user_id)
);

-- ============================================================
-- 7) RLS
-- ============================================================
alter table library_categories enable row level security;
alter table library_documents enable row level security;
alter table library_document_view_sessions enable row level security;
alter table library_document_drive_open_logs enable row level security;
alter table library_document_download_click_logs enable row level security;
alter table library_document_favorites enable row level security;

-- Categories: ai cũng xem được category đang active; chỉ admin ghi
drop policy if exists "Public read active categories" on library_categories;
create policy "Public read active categories" on library_categories
  for select to anon, authenticated using (is_active = true or public.is_current_user_admin());

drop policy if exists "Admin write categories" on library_categories;
create policy "Admin write categories" on library_categories
  for all to authenticated
  using (public.is_current_user_admin())
  with check (public.is_current_user_admin());

-- Documents: ai cũng xem được document đã PUBLISHED (requires_login được chặn ở tầng UI/API khi mở nội dung thật);
-- admin xem/ghi tất cả trạng thái.
drop policy if exists "Public read published documents" on library_documents;
create policy "Public read published documents" on library_documents
  for select to anon, authenticated
  using (status = 'PUBLISHED' or public.is_current_user_admin());

drop policy if exists "Admin write documents" on library_documents;
create policy "Admin write documents" on library_documents
  for all to authenticated
  using (public.is_current_user_admin())
  with check (public.is_current_user_admin());

-- Tracking tables: chỉ ghi/đọc qua service_role (Cloudflare Functions dùng SERVICE_ROLE_KEY).
-- Không cho phép anon/authenticated đụng trực tiếp để tránh giả mạo lượt xem/lượt mở.
drop policy if exists "Admin read view sessions" on library_document_view_sessions;
create policy "Admin read view sessions" on library_document_view_sessions
  for select to authenticated using (public.is_current_user_admin());

drop policy if exists "Admin read drive open logs" on library_document_drive_open_logs;
create policy "Admin read drive open logs" on library_document_drive_open_logs
  for select to authenticated using (public.is_current_user_admin());

drop policy if exists "Admin read download click logs" on library_document_download_click_logs;
create policy "Admin read download click logs" on library_document_download_click_logs
  for select to authenticated using (public.is_current_user_admin());

-- Favorites: người dùng tự quản lý yêu thích của mình (giống pattern document_favorites đang có)
drop policy if exists "Users manage own library favorites" on library_document_favorites;
create policy "Users manage own library favorites" on library_document_favorites
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ============================================================
-- 8) updated_at auto-touch
-- ============================================================
create or replace function public.library_touch_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_library_categories_touch on library_categories;
create trigger trg_library_categories_touch before update on library_categories
  for each row execute function public.library_touch_updated_at();

drop trigger if exists trg_library_documents_touch on library_documents;
create trigger trg_library_documents_touch before update on library_documents
  for each row execute function public.library_touch_updated_at();

drop trigger if exists trg_library_view_sessions_touch on library_document_view_sessions;
create trigger trg_library_view_sessions_touch before update on library_document_view_sessions
  for each row execute function public.library_touch_updated_at();

-- ============================================================
-- 9) favorite_count atomic sync
-- ============================================================
create or replace function public.library_sync_favorite_count()
returns trigger as $$
begin
  if (tg_op = 'INSERT') then
    update library_documents set favorite_count = favorite_count + 1 where id = new.document_id;
    return new;
  elsif (tg_op = 'DELETE') then
    update library_documents set favorite_count = greatest(favorite_count - 1, 0) where id = old.document_id;
    return old;
  end if;
  return null;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trg_library_favorite_count on library_document_favorites;
create trigger trg_library_favorite_count
  after insert or delete on library_document_favorites
  for each row execute function public.library_sync_favorite_count();

-- ============================================================
-- 10) RPC: view-session lifecycle (atomic, gọi bởi Cloudflare Functions bằng service role)
-- ============================================================

-- 10.1 Tạo phiên xem mới
create or replace function public.library_start_view_session(
  p_document_id uuid,
  p_user_id uuid,
  p_anonymous_id text,
  p_device_type text,
  p_browser text,
  p_operating_system text,
  p_ip_hash text,
  p_user_agent_hash text,
  p_referrer text
) returns uuid as $$
declare
  v_id uuid;
begin
  insert into library_document_view_sessions (
    document_id, user_id, anonymous_id, device_type, browser, operating_system,
    ip_hash, user_agent_hash, referrer, started_at, last_heartbeat_at
  ) values (
    p_document_id, p_user_id, p_anonymous_id, p_device_type, p_browser, p_operating_system,
    p_ip_hash, p_user_agent_hash, p_referrer, now(), now()
  ) returning id into v_id;
  return v_id;
end;
$$ language plpgsql security definer set search_path = public;

-- 10.2 Đánh dấu iframe Google Drive đã load thành công
create or replace function public.library_mark_view_loaded(p_session_id uuid)
returns void as $$
begin
  update library_document_view_sessions
  set viewer_loaded_successfully = true, last_heartbeat_at = now()
  where id = p_session_id;
end;
$$ language plpgsql security definer set search_path = public;

-- 10.3 Heartbeat: cộng dồn thời gian active, và tính lượt xem hợp lệ đúng 1 lần
-- p_active_delta_seconds: số giây active kể từ heartbeat trước (frontend tự tính, không tính khi tab ẩn)
create or replace function public.library_heartbeat_view_session(
  p_session_id uuid,
  p_active_delta_seconds int
) returns table (active_duration_seconds int, is_valid_view boolean, just_counted boolean) as $$
declare
  v_session library_document_view_sessions;
  v_dup_exists boolean;
  v_just_counted boolean := false;
begin
  select * into v_session from library_document_view_sessions where id = p_session_id for update;
  if v_session is null then
    raise exception 'Session not found';
  end if;

  update library_document_view_sessions
  set active_duration_seconds = active_duration_seconds + greatest(coalesce(p_active_delta_seconds, 0), 0),
      last_heartbeat_at = now()
  where id = p_session_id
  returning * into v_session;

  if (not v_session.is_valid_view)
     and v_session.viewer_loaded_successfully
     and v_session.active_duration_seconds >= 10 then

    -- Chống trùng: cùng document + (user_id hoặc anonymous_id) đã có 1 view hợp lệ trong 30 phút gần nhất
    select exists (
      select 1 from library_document_view_sessions s
      where s.document_id = v_session.document_id
        and s.id <> v_session.id
        and s.is_valid_view = true
        and s.view_counted_at > now() - interval '30 minutes'
        and (
          (v_session.user_id is not null and s.user_id = v_session.user_id)
          or (v_session.user_id is null and v_session.anonymous_id is not null and s.anonymous_id = v_session.anonymous_id)
        )
    ) into v_dup_exists;

    if not v_dup_exists then
      update library_document_view_sessions
      set is_valid_view = true, view_counted_at = now()
      where id = v_session.id
      returning * into v_session;

      update library_documents set view_count = view_count + 1 where id = v_session.document_id;
      v_just_counted := true;
    else
      -- Trong cửa sổ 30 phút rồi: đánh dấu is_valid_view để không thử đếm lại, nhưng KHÔNG tăng view_count
      update library_document_view_sessions
      set is_valid_view = true, view_counted_at = now()
      where id = v_session.id
      returning * into v_session;
    end if;
  end if;

  return query select v_session.active_duration_seconds, v_session.is_valid_view, v_just_counted;
end;
$$ language plpgsql security definer set search_path = public;

-- 10.4 Kết thúc phiên xem
create or replace function public.library_end_view_session(
  p_session_id uuid,
  p_active_delta_seconds int
) returns void as $$
begin
  perform public.library_heartbeat_view_session(p_session_id, p_active_delta_seconds);
  update library_document_view_sessions set ended_at = now() where id = p_session_id;
end;
$$ language plpgsql security definer set search_path = public;

-- 10.5 Log mở Google Drive + tăng đếm atomic, trả về document để lấy drive_url
create or replace function public.library_log_drive_open(
  p_document_id uuid,
  p_user_id uuid,
  p_anonymous_id text,
  p_view_session_id uuid,
  p_source_page text,
  p_device_type text,
  p_browser text,
  p_operating_system text,
  p_ip_hash text,
  p_user_agent_hash text
) returns text as $$
declare
  v_drive_url text;
begin
  select drive_url into v_drive_url from library_documents where id = p_document_id and status = 'PUBLISHED';
  if v_drive_url is null then
    raise exception 'Document not found or not published';
  end if;

  insert into library_document_drive_open_logs (
    document_id, user_id, anonymous_id, view_session_id, opened_url, source_page,
    device_type, browser, operating_system, ip_hash, user_agent_hash
  ) values (
    p_document_id, p_user_id, p_anonymous_id, p_view_session_id, v_drive_url, p_source_page,
    p_device_type, p_browser, p_operating_system, p_ip_hash, p_user_agent_hash
  );

  update library_documents set drive_open_count = drive_open_count + 1 where id = p_document_id;

  return v_drive_url;
end;
$$ language plpgsql security definer set search_path = public;

-- 10.6 Log click tải + tăng đếm atomic, trả về document để lấy drive_url
create or replace function public.library_log_download_click(
  p_document_id uuid,
  p_user_id uuid,
  p_anonymous_id text,
  p_view_session_id uuid,
  p_device_type text,
  p_browser text,
  p_operating_system text,
  p_ip_hash text,
  p_user_agent_hash text
) returns text as $$
declare
  v_drive_url text;
begin
  select drive_url into v_drive_url from library_documents where id = p_document_id and status = 'PUBLISHED';
  if v_drive_url is null then
    raise exception 'Document not found or not published';
  end if;

  insert into library_document_download_click_logs (
    document_id, user_id, anonymous_id, view_session_id, clicked_url,
    device_type, browser, operating_system, ip_hash, user_agent_hash
  ) values (
    p_document_id, p_user_id, p_anonymous_id, p_view_session_id, v_drive_url,
    p_device_type, p_browser, p_operating_system, p_ip_hash, p_user_agent_hash
  );

  update library_documents set download_click_count = download_click_count + 1 where id = p_document_id;

  return v_drive_url;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.library_start_view_session(uuid, uuid, text, text, text, text, text, text, text) to service_role;
grant execute on function public.library_mark_view_loaded(uuid) to service_role;
grant execute on function public.library_heartbeat_view_session(uuid, int) to service_role;
grant execute on function public.library_end_view_session(uuid, int) to service_role;
grant execute on function public.library_log_drive_open(uuid, uuid, text, uuid, text, text, text, text, text, text) to service_role;
grant execute on function public.library_log_download_click(uuid, uuid, text, uuid, text, text, text, text, text) to service_role;

-- ============================================================
-- 11) Seed: 13 danh mục mẫu
-- ============================================================
insert into library_categories (name, slug, description, display_order, is_active) values
  ('Tín dụng', 'tin-dung', 'Quy trình thẩm định, phê duyệt và quản lý khoản vay.', 1, true),
  ('Thanh toán và thẻ', 'thanh-toan-va-the', 'Nghiệp vụ thanh toán nội địa, quốc tế và phát hành thẻ.', 2, true),
  ('Ngân quỹ và kho bạc', 'ngan-quy-va-kho-bac', 'Quản lý thanh khoản, ngân quỹ và nghiệp vụ kho bạc.', 3, true),
  ('Tài trợ thương mại', 'tai-tro-thuong-mai', 'Tài trợ xuất nhập khẩu, L/C, bảo lãnh thương mại.', 4, true),
  ('Core Banking', 'core-banking', 'Kiến trúc và nghiệp vụ hệ thống ngân hàng lõi.', 5, true),
  ('Kế toán và báo cáo tài chính', 'ke-toan-va-bao-cao-tai-chinh', 'Chuẩn mực kế toán ngân hàng và báo cáo tài chính.', 6, true),
  ('Quản lý khách hàng CRM', 'quan-ly-khach-hang-crm', 'Quy trình và công cụ quản lý quan hệ khách hàng.', 7, true),
  ('KYC, AML, Compliance', 'kyc-aml-compliance', 'Định danh khách hàng, phòng chống rửa tiền, tuân thủ.', 8, true),
  ('Quản trị rủi ro', 'quan-tri-rui-ro', 'Khung quản trị rủi ro tín dụng, thị trường, vận hành.', 9, true),
  ('Vận hành ngân hàng', 'van-hanh-ngan-hang', 'Quy trình vận hành, xử lý giao dịch back-office.', 10, true),
  ('Ngân hàng số và Open Banking', 'ngan-hang-so-va-open-banking', 'Chuyển đổi số, API Open Banking, eKYC.', 11, true),
  ('Dữ liệu và báo cáo', 'du-lieu-va-bao-cao', 'Quản trị dữ liệu, data warehouse, báo cáo quản trị.', 12, true),
  ('Nghiệp vụ nội bộ', 'nghiep-vu-noi-bo', 'Quy trình nội bộ, quản lý nhân sự và vận hành chung.', 13, true)
on conflict (slug) do nothing;