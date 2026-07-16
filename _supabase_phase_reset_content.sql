-- Phase: XOÁ TOÀN BỘ dữ liệu nội dung/lớp học/lộ trình để thiết lập lại từ đầu.
-- GIỮ NGUYÊN: bảng `profiles` (tài khoản, họ tên, email, vai trò is_admin/is_mentor,
-- approval_status, is_active...) và `role_permissions` (ma trận phân quyền hệ thống)
-- và `achievements` (danh mục huy hiệu — chỉ là định nghĩa, không phải nội dung khoá học).
--
-- ⚠️ KHÔNG THỂ HOÀN TÁC. Chạy bước 0 trước để xem số dòng sẽ mất, rồi mới chạy bước 1.
-- ⚠️ Không xoá file trong Supabase Storage (bucket "chat-attachments", "submissions",
--    "avatars") — nếu muốn dọn luôn, vào Supabase Dashboard → Storage để xoá thủ công.

-- ============================================================
-- BƯỚC 0 — XEM TRƯỚC (read-only, chạy riêng để kiểm tra số liệu trước khi xoá)
-- ============================================================
select
  (select count(*) from classes) as so_lop_hoc,
  (select count(*) from phases) as so_lo_trinh,
  (select count(*) from modules) as so_buoi_hoc,
  (select count(*) from assignments) as so_bai_tap,
  (select count(*) from case_studies) as so_case_study,
  (select count(*) from documents) as so_tai_lieu,
  (select count(*) from submissions) as so_bai_nop,
  (select count(*) from messages) as so_tin_nhan,
  (select count(*) from mentors) as so_dong_lien_ket_mentor,
  (select count(*) from profiles) as so_tai_khoan_se_giu_nguyen;

-- ============================================================
-- BƯỚC 1 — XOÁ (chạy sau khi đã xem bước 0 và xác nhận muốn tiếp tục)
-- ============================================================
begin;

-- Gỡ liên kết mentor cá nhân trên profiles trước (giữ profiles, chỉ null hoá cột tham chiếu)
update profiles set primary_mentor_id = null where primary_mentor_id is not null;

-- Xoá theo đúng thứ tự phụ thuộc khoá ngoại: bảng con trước, bảng cha sau
delete from submission_files;
delete from submission_versions;
delete from submissions;
delete from case_study_task_progress;
delete from case_study_tasks;
delete from quiz_questions;
delete from module_progress;
delete from document_favorites;
delete from class_session_registrations;
delete from class_announcements;
delete from user_achievements;
delete from notification_reads;
delete from messages;
delete from student_notes;
delete from learning_path_steps;
delete from documents;
delete from case_studies;
delete from assignments;
delete from class_sessions;
delete from class_members;
delete from classes;
delete from modules;
delete from phases;
delete from mentors;

commit;

-- ============================================================
-- BƯỚC 2 — XÁC NHẬN SAU KHI XOÁ (read-only, chạy sau bước 1)
-- ============================================================
select
  (select count(*) from classes) as so_lop_hoc,
  (select count(*) from phases) as so_lo_trinh,
  (select count(*) from mentors) as so_dong_lien_ket_mentor,
  (select count(*) from profiles) as so_tai_khoan_van_con;
