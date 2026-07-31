# Thư viện tài liệu tham khảo

Tính năng thư viện tài liệu công khai (xem trực tuyến qua Google Drive), tái sử dụng kiến trúc
sẵn có của repo: static HTML/CSS/JS + Cloudflare Pages Functions + Supabase Postgres. Không thêm
framework/ORM/DB mới.

## 1. Cài đặt database

Chạy file `_supabase_phase_library.sql` (ở thư mục gốc repo) trong Supabase SQL editor. File này:

- Tạo 6 bảng mới, tất cả có tiền tố `library_*` để **không đụng** vào bảng `documents` /
  `document_favorites` đã tồn tại (dùng cho tính năng "Tài liệu của tôi" khác phạm vi):
  `library_categories`, `library_documents`, `library_document_view_sessions`,
  `library_document_drive_open_logs`, `library_document_download_click_logs`,
  `library_document_favorites`.
- Bật RLS: danh mục/tài liệu đã `PUBLISHED` đọc công khai (anon + authenticated); ghi chỉ admin
  (`public.is_current_user_admin()` — hàm đã có sẵn trong repo); các bảng log/phiên xem chỉ
  service_role được ghi (client không bao giờ ghi trực tiếp, tránh giả mạo lượt xem/lượt mở).
- Tạo các hàm RPC atomic (`library_start_view_session`, `library_heartbeat_view_session`,
  `library_end_view_session`, `library_log_drive_open`, `library_log_download_click`) — mỗi hàm
  chạy trong 1 transaction Postgres duy nhất để tăng đếm chính xác, không trùng.
- Seed sẵn 13 danh mục mẫu theo đúng danh sách yêu cầu (không tiền tố số, không icon folder ở tầng dữ liệu).

## 2. Biến môi trường (Cloudflare Pages)

Các Function mới dùng chung 3 biến đã có sẵn trong project Cloudflare Pages (không cần thêm biến
bắt buộc mới):

| Biến | Bắt buộc | Mô tả |
|---|---|---|
| `SUPABASE_URL` | Có (đã có sẵn) | URL project Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Có (đã có sẵn) | Dùng để gọi RPC atomic + đọc/ghi bảng log, bỏ qua RLS |
| `SUPABASE_ANON_KEY` | Có (đã có sẵn) | Dùng để xác thực access_token của người dùng qua `/auth/v1/user` |
| `IP_HASH_SALT` | Tuỳ chọn (mới) | Salt cho việc băm IP/User-Agent trước khi lưu (`ip_hash`, `user_agent_hash`). Nếu bỏ trống, dùng salt mặc định `nextgen-ba` — **nên đặt riêng cho production** để tăng tính riêng tư. |

## 3. Các trang mới

| Trang | Đường dẫn | Ghi chú |
|---|---|---|
| Danh mục tài liệu | `app/tai-lieu.html` | Công khai, không cần đăng nhập |
| Danh sách theo danh mục | `app/tai-lieu-danh-muc.html?slug=<categorySlug>` | Query-param thay vì path segment, theo đúng convention hiện có của repo (không có server-side routing cho static HTML, xem `assignment-detail.html?id=...`) |
| Chi tiết + xem tài liệu | `app/tai-lieu-chi-tiet.html?c=<categorySlug>&d=<documentSlug>` | Nhúng Google Drive Preview qua iframe, theo dõi lượt xem |
| Quản trị thư viện | `app/admin-library.html` | Quản lý danh mục + tài liệu + dashboard số liệu |

## 4. API mới (Cloudflare Pages Functions)

Chỉ 6 endpoint POST cần server-side (để atomic-increment bằng service role); các API GET danh
mục/tài liệu dùng thẳng `window.sb.from(...)` (Supabase client, được bảo vệ bằng RLS công khai) —
đúng convention hiện có của repo (không có endpoint GET nào khác trong `functions/api/`).

- `POST /api/documents/:documentId/view-sessions`
- `POST /api/document-view-sessions/:sessionId/loaded`
- `POST /api/document-view-sessions/:sessionId/heartbeat`
- `POST /api/document-view-sessions/:sessionId/end`
- `POST /api/documents/:documentId/open-drive`
- `POST /api/documents/:documentId/download-click`

Favorite (`library_document_favorites`) dùng trực tiếp Supabase client từ frontend, được bảo vệ
bằng RLS (`user_id = auth.uid()`) — cùng pattern với `document_favorites` đã có sẵn, không cần
thêm Function riêng.

## 5. Test

```
node tests/library-logic.test.js
```

Test thuần Node (không cần framework, đúng với việc repo không có `package.json`/test runner),
gồm 2 nhóm:

1. Parse/chuẩn hoá Google Drive URL (`libraryExtractDriveFileId`, `libraryNormalizeDriveUrl`, ...).
2. Mô phỏng logic chống trùng lượt xem trong 30 phút — **mô phỏng lại đúng quy tắc** của hàm
   Postgres `library_heartbeat_view_session()`, không thay thế integration test thật với Supabase.
   Nếu sửa logic dedup trong SQL, cần cập nhật `simulateHeartbeat()` trong file test tương ứng.

## 6. Giới hạn kỹ thuật đã biết

- **Không thể phát hiện lỗi "file đã xoá / chưa share đúng quyền" một cách chắc chắn** từ trang chi
  tiết: do same-origin policy, parent frame không đọc được nội dung bên trong iframe Google Drive
  (kể cả khi Drive trả về trang lỗi, `iframe.onload` vẫn fire vì response vẫn là 200). Giải pháp áp
  dụng: timeout 15 giây nếu `onload` không fire → hiển thị error state + nút "Tải lại". Ở màn hình
  admin, có kiểm tra heuristic khi nhập link (thử tải `https://drive.google.com/thumbnail?id=...`)
  để cảnh báo sớm nếu file có vẻ chưa share đúng quyền — đây là tín hiệu tham khảo, không phải xác
  nhận tuyệt đối.
- Nav link "Thư viện tài liệu" mới được nối vào sidebar/topbar của tất cả trang `admin-*.html` +
  `learning-path-designer.html`, và vào `documents.html` (phía học viên). Các trang học viên khác
  (`dashboard.html`, `my-classes.html`, `assignments.html`, `mentor.html`...) **chưa được nối** —
  có thể bổ sung nhanh nếu cần, chỉ là lặp lại 1 dòng `<a>` giống mẫu trong `documents.html`.