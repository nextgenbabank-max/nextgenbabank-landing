-- Phase: Seed quyền cho trang mới "Lớp học của tôi" (my-classes.html), dùng cho
-- has_permission('my_classes','view') theo đúng pattern mọi trang học viên khác đang dùng.

insert into role_permissions (role, feature_key, can_view, can_add, can_edit, can_delete)
values ('student', 'my_classes', true, false, false, false)
on conflict (role, feature_key) do nothing;
