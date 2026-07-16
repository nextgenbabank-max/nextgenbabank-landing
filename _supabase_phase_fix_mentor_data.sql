-- Phase: Sửa dữ liệu mentor — liên kết Vân Lê (tài khoản thật) vào bảng mentors,
-- dọn 2 dòng mentor mẫu cũ (Mentor Trung, Mentor Thảo), thêm RPC để tự phục vụ việc này về sau.

-- 1) Tạo (nếu chưa có) dòng mentors cho Vân Lê và liên kết với tài khoản đăng nhập thật của cô ấy
do $$
declare
  v_email text := 'lethivanbm@gmail.com';
  v_uid uuid;
  v_mentor_id uuid;
  v_fake_ids uuid[];
begin
  select id into v_uid from auth.users where email = v_email;
  if v_uid is null then
    raise notice 'Không tìm thấy tài khoản đăng nhập với email %, bỏ qua.', v_email;
    return;
  end if;

  select id into v_mentor_id from mentors where user_id = v_uid;
  if v_mentor_id is null then
    insert into mentors (full_name, role_title, avatar_initials, avatar_color, user_id)
    values ('Vân Lê', 'Giảng viên', 'VL', '#22A06B', v_uid)
    returning id into v_mentor_id;
  end if;

  update profiles set is_mentor = true where id = v_uid;

  -- 2) Gom các dòng mentors "ảo" (không phải Vân Lê, không gắn tài khoản thật nào)
  select array_agg(id) into v_fake_ids from mentors where id <> v_mentor_id and user_id is null;

  if v_fake_ids is not null then
    update classes set mentor_id = v_mentor_id where mentor_id = any(v_fake_ids);
    update assignments set mentor_id = v_mentor_id where mentor_id = any(v_fake_ids);
    update profiles set primary_mentor_id = v_mentor_id where primary_mentor_id = any(v_fake_ids);
    delete from mentors where id = any(v_fake_ids);
  end if;
end $$;

-- 3) RPC tự phục vụ: kích hoạt hồ sơ giảng viên (tạo dòng mentors + liên kết) cho 1 tài khoản
--    đã có is_mentor=true nhưng chưa có dòng mentors tương ứng — dùng từ trang Quản lý người dùng,
--    thay thế phần UI liên kết mentor trước đây chỉ có ở admin.html (đã gỡ khỏi điều hướng).
create or replace function public.admin_ensure_mentor_row(p_profile_id uuid, p_avatar_initials text default null)
returns uuid as $$
declare
  v_mentor_id uuid;
  v_full_name text;
  v_email text;
begin
  if not public.is_current_user_admin() then
    raise exception 'Not authorized';
  end if;

  select id into v_mentor_id from mentors where user_id = p_profile_id;
  if v_mentor_id is not null then
    return v_mentor_id;
  end if;

  select full_name, email into v_full_name, v_email from profiles where id = p_profile_id;

  insert into mentors (full_name, role_title, avatar_initials, avatar_color, user_id)
  values (coalesce(v_full_name, v_email, 'Giảng viên'), 'Giảng viên', coalesce(p_avatar_initials, '?'), '#5B9BFA', p_profile_id)
  returning id into v_mentor_id;

  update profiles set is_mentor = true where id = p_profile_id;

  return v_mentor_id;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.admin_ensure_mentor_row(uuid, text) to authenticated;
