-- Fix: API/Data và Banking Project Practice thực tế chỉ có 2 chặng (không phải 3).
-- Gộp chặng 1+2 cũ thành chặng 1 mới (5 buổi), giữ chặng 3 cũ làm chặng 2 mới (3 buổi).
-- Tổng số buổi (8) không đổi.

update courses set number_of_stages = 2, updated_at = now()
where course_code in ('API_DATA_INTEGRATION', 'BANKING_PROJECT_PRACTICE');
