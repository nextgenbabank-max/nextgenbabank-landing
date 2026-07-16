-- Phase: Trạng thái buổi học (đã hủy/đã đổi lịch) + công bố (is_published) + updated_at
-- để phát hiện "lịch học thay đổi"/"Meet link cập nhật" cho hệ thống thông báo.
-- Mọi default giữ nguyên hành vi hiện tại (status='scheduled', is_published=true — không
-- buổi nào cũ bị mất nút "Vào Meet" sau migration).

alter table class_sessions
  add column if not exists status text not null default 'scheduled'
    check (status in ('scheduled', 'cancelled', 'rescheduled')),
  add column if not exists is_published boolean not null default true,
  add column if not exists updated_at timestamptz not null default now();

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists class_sessions_set_updated_at on class_sessions;
create trigger class_sessions_set_updated_at
  before update on class_sessions
  for each row execute procedure public.set_updated_at();
