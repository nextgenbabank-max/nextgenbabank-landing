-- Phase: Gắn tài liệu và case study vào 1 lớp cụ thể (nullable — null = dùng chung mọi lớp)
-- Mirror đúng pattern assignments.class_id đã có sẵn. RLS giữ nguyên using(true),
-- lọc theo lớp tiếp tục làm ở client-side JS (đúng convention hiện tại của dự án).

alter table documents
  add column if not exists class_id uuid references classes(id) on delete set null;

alter table case_studies
  add column if not exists class_id uuid references classes(id) on delete set null;
