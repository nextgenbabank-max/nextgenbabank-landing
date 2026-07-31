-- Fix: học phí theo chặng của API/Data & System Integration for BA và Banking Project Practice
-- tăng lên 1.999.000 VNĐ/chặng (giữ nguyên quy tắc ưu đãi 50% => giá gốc 3.998.000 VNĐ/chặng).
-- Học phí trọn khóa (sale_price/original_price) không đổi.

update courses
set stage_sale_price = 1999000,
    stage_original_price = 3998000,
    updated_at = now()
where course_code in ('API_DATA_INTEGRATION', 'BANKING_PROJECT_PRACTICE');
