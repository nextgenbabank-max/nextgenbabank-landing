-- Phase: Quản lý người dùng — kích hoạt/ngưng hoạt động tài khoản

alter table profiles
  add column if not exists is_active boolean not null default true;
