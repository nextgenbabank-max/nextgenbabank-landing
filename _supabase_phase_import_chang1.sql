-- Phase: Import lộ trình "NextGen BA Banker — Chặng 1: Nền tảng BA Ngân hàng" từ file Lich-hoc-Chang-1.xlsx
-- Sinh tự động từ Excel — 12 buổi học, mỗi buổi kèm 1 Quick Task (Quiz 10 câu) + 2 Case Study;
-- buổi 5-12 có thêm 1 Project (dự án xuyên suốt "Mở tài khoản thanh toán online eKYC").
--
-- An toàn: chỉ THÊM 1 lộ trình mới + dữ liệu con của nó, không đụng tới bảng/dòng nào khác.
-- Chạy lại nhiều lần sẽ tạo thêm nhiều bản sao trùng — chỉ chạy 1 lần.

do $$
declare
  v_phase_id uuid;
  v_module_id uuid;
  v_assignment_id uuid;
begin
  insert into phases (title, order_index)
  values ('NextGen BA Banker — Chặng 1: Nền tảng BA Ngân hàng', (select coalesce(max(order_index), 0) + 1 from phases))
  returning id into v_phase_id;

  -- ===== Buổi 1 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 1, 'Buổi 1: Tổng quan nghề BA và vòng đời dự án phần mềm', '- Vai trò BA trong tổ chức: phân biệt BA với PM/PO/Dev/QA.
- Vòng đời 1 dự án phần mềm: Khởi tạo → Khảo sát → Phân tích → Thiết kế → Phát triển → Kiểm thử → Triển khai.
- Tổng quan Agile/Scrum ở mức BA cần biết.
- Tư duy phân tích: đặt câu hỏi đúng, phân biệt yêu cầu thật vs giải pháp đề xuất.

Thực hành:
- Thảo luận nhóm: so sánh trách nhiệm BA vs các vai trò khác qua 1 tình huống dự án giả định.
- Bài tập nhận diện: đâu là "yêu cầu" thật, đâu là "giải pháp" trong 1 đoạn mô tả cho trước.', '- Giúp học viên nắm được:
- Vai trò và trách nhiệm cụ thể của BA trong 1 dự án.
- Bức tranh tổng thể vòng đời dự án phần mềm.
- Tư duy phân tích cơ bản của nghề BA.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 1', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, 'Vai trò chính của BA khác PM ở điểm nào?', '["BA quản lý ngân sách/tiến độ dự án","BA phân tích nhu cầu nghiệp vụ và đặc tả yêu cầu; PM quản lý phạm vi/tiến độ/nguồn lực","BA và PM luôn là 1 vai trò trong dự án nhỏ","BA chỉ làm ở giai đoạn kiểm thử"]'::jsonb, 1, 1),
    (v_assignment_id, 'Giai đoạn nào diễn ra NGAY SAU "Khảo sát" trong vòng đời dự án?', '["Triển khai","Phân tích","Kiểm thử","Phát triển"]'::jsonb, 1, 2),
    (v_assignment_id, 'PO trong Scrum khác BA truyền thống chủ yếu ở điểm nào?', '["PO quyết định ưu tiên Product Backlog, tối đa hoá giá trị SP; BA hỗ trợ phân tích/đặc tả chi tiết","PO không họp với stakeholder","PO chỉ làm việc với Dev","Không có khác biệt"]'::jsonb, 0, 3),
    (v_assignment_id, '"Yêu cầu thật" khác "giải pháp đề xuất" thế nào?', '["Yêu cầu thật mô tả CÁCH làm","Yêu cầu thật mô tả nhu cầu/vấn đề (WHAT/WHY); giải pháp là 1 cách cụ thể để đáp ứng (HOW)","Là một khái niệm, không cần phân biệt","Chỉ tồn tại ở dự án Agile"]'::jsonb, 1, 4),
    (v_assignment_id, 'QA khác BA chủ yếu ở điểm nào?', '["QA kiểm thử SP có đúng yêu cầu đã đặc tả không; BA xác định/đặc tả yêu cầu đó","QA và BA đều lập trình","QA chỉ làm ở giai đoạn khảo sát","Không có khác biệt"]'::jsonb, 0, 5),
    (v_assignment_id, 'Trong Agile/Scrum, BA thường tham gia hoạt động nào?', '["Chỉ Sprint Retrospective","Refinement Backlog, viết User Story, làm rõ Acceptance Criteria với Dev/QA","Chỉ viết BRD 1 lần đầu dự án","Chỉ tham gia UAT"]'::jsonb, 1, 6),
    (v_assignment_id, 'Khách hàng nói: "Tôi muốn có nút xuất Excel trên màn hình báo cáo." Đây là:', '["Chắc chắn là business need","Có thể là giải pháp đề xuất cho nhu cầu sâu xa hơn — BA cần hỏi \"để làm gì\"","Không liên quan đến BA","Là 1 Business Rule"]'::jsonb, 1, 7),
    (v_assignment_id, 'Giai đoạn nào BA tham gia NHIỀU và SÂU nhất?', '["Khảo sát và Phân tích","Phát triển (coding)","Chỉ Triển khai","Không giai đoạn nào cụ thể"]'::jsonb, 0, 8),
    (v_assignment_id, 'Dev khác BA chủ yếu ở điểm nào?', '["Dev hiện thực hoá giải pháp kỹ thuật (code) dựa trên yêu cầu BA đã phân tích; BA không trực tiếp code","Dev và BA đều chỉ làm tài liệu","Không có khác biệt","Dev luôn làm việc trực tiếp với KH, BA thì không"]'::jsonb, 0, 9),
    (v_assignment_id, '"Tư duy phân tích" của BA theo buổi 1 gồm điều gì?', '["Chỉ cần vẽ sơ đồ đẹp","Đặt câu hỏi đúng (why/what) và phân biệt yêu cầu thật với giải pháp đề xuất","Chỉ cần biết code cơ bản","Chỉ ghi chép nguyên văn lời khách hàng"]'::jsonb, 1, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — Phân công sai vai trò', 'Ngân hàng triển khai dự án nâng cấp App Mobile Banking, bổ sung tính năng chuyển tiền quốc tế. Trong buổi kick-off, PM giao việc "viết tài liệu yêu cầu" cho 1 bạn Dev vì "Dev cũng hiểu nghiệp vụ".
Yêu cầu: (1) Phân tích rủi ro của cách phân công này dựa trên phân biệt vai trò BA vs Dev đã học. (2) Đề xuất BA nên tham gia từ giai đoạn nào trong vòng đời dự án và làm gì cụ thể.', 1, 14),
    (v_module_id, 'Case Study 2 — Yêu cầu mơ hồ', 'Trưởng phòng Vận hành yêu cầu: "Tôi cần báo cáo tổng hợp giao dịch hàng ngày, xuất PDF, gửi email tự động lúc 8h sáng." BA mới vào nghề ghi nhận nguyên văn và chuyển thẳng cho Dev.
Yêu cầu: (1) Chỉ ra đâu là yêu cầu thật, đâu là giải pháp đề xuất trong câu trên. (2) Liệt kê 3 câu hỏi BA nên đặt ra trước khi chốt yêu cầu.', 2, 14);

  -- ===== Buổi 2 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 2, 'Buổi 2: Stakeholder Analysis', '- Khái niệm Stakeholder, vì sao cần quản lý các bên liên quan.
- Power-Interest Matrix.
- RACI Matrix.

Thực hành:
- Case nhỏ: liệt kê stakeholder cho 1 tính năng cho trước.
- Vẽ Power-Interest Matrix cho case đó.
- Lập RACI Matrix cho 1 hoạt động trong case.', '- Giúp học viên nắm được:
- Cách xác định đầy đủ các bên liên quan của 1 dự án/chức năng.
- Cách phân loại và ưu tiên stakeholder theo mức độ ảnh hưởng/quan tâm.
- Cách phân vai trách nhiệm (RACI) cho 1 hoạt động cụ thể.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 2', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, 'Power-Interest Matrix dùng để làm gì?', '["Đo lường ngân sách dự án","Phân loại stakeholder theo mức độ quyền lực và mức độ quan tâm để xác định chiến lược quản lý phù hợp","Xác định deadline dự án","Đánh giá chất lượng code"]'::jsonb, 1, 1),
    (v_assignment_id, 'Stakeholder có Power cao - Interest cao nên được quản lý theo chiến lược nào?', '["Monitor (theo dõi tối thiểu)","Manage Closely (quản lý sát sao, tương tác thường xuyên)","Keep Informed (chỉ thông báo)","Bỏ qua"]'::jsonb, 1, 2),
    (v_assignment_id, 'Trong RACI Matrix, "A" (Accountable) nghĩa là gì?', '["Người thực hiện công việc trực tiếp","Người chịu trách nhiệm cuối cùng, phê duyệt kết quả (chỉ nên có 1 người/hoạt động)","Người được tham vấn ý kiến","Người chỉ cần được thông báo"]'::jsonb, 1, 3),
    (v_assignment_id, 'Sự khác biệt giữa R (Responsible) và A (Accountable) trong RACI là gì?', '["Không có khác biệt","R là người trực tiếp thực hiện; A là người chịu trách nhiệm cuối cùng/phê duyệt, có thể ủy quyền cho R thực hiện","R luôn cấp cao hơn A","A chỉ dùng trong dự án Agile"]'::jsonb, 1, 4),
    (v_assignment_id, 'Một stakeholder Power thấp - Interest cao (VD: nhân viên vận hành trực tiếp) nên được xử lý thế nào?', '["Bỏ qua hoàn toàn","Keep Informed — thông báo đầy đủ, thu thập phản hồi vì họ chịu tác động trực tiếp dù ít quyền quyết định","Manage Closely như stakeholder cấp cao","Không cần khảo sát ý kiến"]'::jsonb, 1, 5),
    (v_assignment_id, 'Vì sao BA cần làm Stakeholder Analysis trước khi elicitation?', '["Để tính lương cho dự án","Để xác định đúng và đủ người cần khảo sát, tránh bỏ sót yêu cầu quan trọng","Không cần thiết, elicit ai cũng được","Chỉ để làm đẹp tài liệu"]'::jsonb, 1, 6),
    (v_assignment_id, 'Trong RACI, có thể có bao nhiêu người giữ vai trò "A" (Accountable) cho 1 hoạt động?', '["Không giới hạn","Chỉ nên có 1 người duy nhất để tránh chồng chéo trách nhiệm","Tối thiểu 3 người","Bằng số lượng người \"R\""]'::jsonb, 1, 7),
    (v_assignment_id, '"C" (Consulted) trong RACI khác "I" (Informed) ở điểm nào?', '["Không khác biệt","C là được hỏi ý kiến/tham vấn 2 chiều trước khi quyết định; I chỉ được thông báo kết quả 1 chiều","I quan trọng hơn C","C chỉ áp dụng cho cấp quản lý"]'::jsonb, 1, 8),
    (v_assignment_id, 'Khi lập danh sách stakeholder cho 1 dự án ngân hàng, nhóm nào dễ bị bỏ sót nhưng SAI khi bỏ sót?', '["Ban giám đốc","Đội IT vận hành hệ thống","Bộ phận Tuân thủ (Compliance)/Pháp chế — thường bị quên nhưng ảnh hưởng lớn tới yêu cầu","Khách hàng cuối"]'::jsonb, 2, 9),
    (v_assignment_id, 'Mục đích chính của việc phân loại stakeholder trước khi elicitation là gì?', '["Tối ưu chi phí in ấn tài liệu","Ưu tiên đúng đối tượng, chọn kỹ thuật elicitation phù hợp và tránh xung đột lợi ích giữa các bên","Không có mục đích thực tế","Chỉ để làm báo cáo nội bộ"]'::jsonb, 1, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — Bỏ sót stakeholder', 'Dự án triển khai hệ thống phê duyệt khoản vay tự động. BA chỉ làm việc với phòng Tín dụng và phòng IT, không mời phòng Quản lý Rủi ro và phòng Pháp chế tham gia workshop yêu cầu. Sau UAT, phòng Pháp chế phát hiện quy trình thiếu bước đối chiếu danh sách đen (blacklist) theo quy định.
Yêu cầu: (1) Xác định sai lầm trong Stakeholder Analysis ở tình huống này. (2) Mô tả vị trí đúng của phòng Pháp chế và phòng Quản lý Rủi ro trên Power-Interest Matrix.', 1, 14),
    (v_module_id, 'Case Study 2 — RACI mơ hồ', 'Trong dự án nâng cấp App, tài liệu RACI ghi "Cả Trưởng phòng Sản phẩm và Trưởng phòng Công nghệ đều là Accountable" cho hoạt động "Phê duyệt phạm vi dự án". Kết quả 2 tuần sau, quyết định về phạm vi bị trì hoãn vì 2 bên đùn đẩy trách nhiệm.
Yêu cầu: (1) Chỉ ra lỗi trong cách lập RACI ở đây. (2) Đề xuất cách sửa RACI Matrix cho hoạt động "Phê duyệt phạm vi dự án".', 2, 14);

  -- ===== Buổi 3 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 3, 'Buổi 3: Requirements Elicitation', '- Các kỹ thuật thu thập yêu cầu: interview, workshop, document analysis, observation, survey.
- Kỹ thuật đặt câu hỏi hiệu quả: open-ended, 5 Whys, tránh câu hỏi dẫn dắt.

Thực hành:
- Case nhỏ: chọn kỹ thuật elicitation phù hợp cho từng tình huống cho trước.
- Thực hành đóng vai phỏng vấn ngắn (theo cặp) và nhận xét lẫn nhau.', '- Giúp học viên nắm được:
- Phân biệt được các kỹ thuật elicitation và khi nào dùng kỹ thuật nào.
- Cách đặt câu hỏi khai thác đúng nhu cầu thật của stakeholder.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 3', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, 'Kỹ thuật elicitation nào phù hợp nhất khi cần thu thập ý kiến nhanh từ số đông người dùng phân tán địa lý?', '["Interview 1-1","Observation","Survey (khảo sát)","Workshop"]'::jsonb, 2, 1),
    (v_assignment_id, 'Workshop khác Interview 1-1 ở điểm gì?', '["Không khác biệt","Workshop tập hợp nhiều stakeholder cùng lúc, giúp thống nhất quan điểm nhanh và phát hiện xung đột yêu cầu ngay tại chỗ","Workshop chỉ dùng cho dự án nhỏ","Interview luôn hiệu quả hơn Workshop"]'::jsonb, 1, 2),
    (v_assignment_id, 'Kỹ thuật "5 Whys" dùng để làm gì?', '["Đếm số lượng yêu cầu","Đào sâu tìm nguyên nhân gốc rễ (root cause) của 1 vấn đề/nhu cầu bằng cách hỏi \"tại sao\" liên tiếp","Ước lượng thời gian dự án","Phân loại stakeholder"]'::jsonb, 1, 3),
    (v_assignment_id, 'Document Analysis phù hợp khi nào?', '["Khi cần ý kiến trực tiếp của khách hàng mới","Khi cần hiểu quy trình/quy định hiện có qua tài liệu sẵn có trước khi phỏng vấn","Không bao giờ cần thiết","Chỉ dùng thay thế hoàn toàn cho phỏng vấn"]'::jsonb, 1, 4),
    (v_assignment_id, 'Câu hỏi "Anh/chị có đồng ý là tính năng A rất cần thiết đúng không?" là ví dụ của lỗi nào?', '["Câu hỏi mở tốt","Câu hỏi dẫn dắt (leading question) — gợi ý sẵn câu trả lời mong muốn, làm sai lệch kết quả elicit","Kỹ thuật 5 Whys","Document Analysis"]'::jsonb, 1, 5),
    (v_assignment_id, 'Observation (quan sát) đặc biệt hữu ích trong trường hợp nào?', '["Khi stakeholder ở xa không gặp được","Khi người dùng khó diễn đạt bằng lời quy trình họ thực hiện hàng ngày (tacit knowledge)","Khi chỉ cần số liệu thống kê lớn","Khi dự án không có người dùng cuối"]'::jsonb, 1, 6),
    (v_assignment_id, 'Câu hỏi mở (open-ended question) có đặc điểm gì?', '["Chỉ có 2 lựa chọn trả lời Có/Không","Không giới hạn câu trả lời trong khuôn mẫu định sẵn, khuyến khích chia sẻ chi tiết, giảm thiên lệch","Luôn dẫn dắt người trả lời theo ý BA","Chỉ dùng trong Survey"]'::jsonb, 1, 7),
    (v_assignment_id, 'Khi nào nên chọn Interview 1-1 thay vì Workshop?', '["Khi cần sự đồng thuận nhanh của nhiều phòng ban","Khi vấn đề nhạy cảm, cần không gian riêng tư để stakeholder chia sẻ thẳng thắn","Khi ngân sách phỏng vấn không giới hạn thời gian","Interview luôn tốt hơn trong mọi trường hợp"]'::jsonb, 1, 8),
    (v_assignment_id, 'Rủi ro lớn nhất khi BA chỉ dựa vào 1 kỹ thuật elicitation duy nhất cho toàn bộ dự án là gì?', '["Không có rủi ro","Bỏ sót thông tin định tính/ngữ cảnh sâu mà kỹ thuật đó không khai thác được","Tốn quá nhiều thời gian","Luôn cho kết quả tốt nhất"]'::jsonb, 1, 9),
    (v_assignment_id, 'Trong 5 Whys, khi nào nên dừng lại việc hỏi "tại sao"?', '["Sau đúng 5 lần hỏi bất kể nội dung","Khi đã chạm đến nguyên nhân gốc rễ thực sự (root cause) có thể hành động được","Ngay sau câu hỏi đầu tiên","Không bao giờ dừng"]'::jsonb, 1, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — Chọn sai kỹ thuật', 'BA cần thu thập lý do khách hàng rời bỏ dịch vụ Internet Banking (churn) từ 500 khách hàng đã ngừng sử dụng, phân bố toàn quốc. BA quyết định phỏng vấn 1-1 từng người trong 2 tuần.
Yêu cầu: (1) Đánh giá tính phù hợp của lựa chọn Interview 1-1 trong tình huống này. (2) Đề xuất kỹ thuật/kết hợp kỹ thuật elicitation phù hợp hơn kèm lý do.', 1, 14),
    (v_module_id, 'Case Study 2 — Câu hỏi dẫn dắt', 'Trong buổi phỏng vấn nhân viên giao dịch, BA hỏi: "Anh/chị thấy màn hình giao dịch hiện tại rất khó dùng và cần làm lại hoàn toàn đúng không?" Nhân viên gật đầu đồng ý dù thực tế chỉ gặp khó ở 1 bước nhỏ.
Yêu cầu: (1) Phân tích lỗi trong câu hỏi trên và hậu quả với yêu cầu thu thập được. (2) Viết lại câu hỏi theo hướng mở, kết hợp 5 Whys để đào sâu.', 2, 14);

  -- ===== Buổi 4 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 4, 'Buổi 4: Process Modeling cơ bản', '- BPMN cơ bản: swimlane, gateway, event, task.
- Khái niệm AS-IS và TO-BE.
- Happy Path và Exception Flow.

Thực hành:
- Vẽ 1 quy trình đơn giản (ví dụ: quy trình xin nghỉ phép, quy trình đặt hàng) có Happy Path + 1 Exception Flow.', '- Giúp học viên nắm được:
- Đọc hiểu 1 sơ đồ quy trình đơn giản.
- Vẽ được 1 quy trình nghiệp vụ cơ bản có swimlane, gateway.
- Phân biệt Happy Path và Exception Flow trong 1 quy trình.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 4', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, 'Trong BPMN, "Swimlane" dùng để thể hiện điều gì?', '["Thời gian thực hiện quy trình","Phân định trách nhiệm/vai trò (actor) thực hiện từng bước trong quy trình","Ngân sách của từng bước","Độ ưu tiên công việc"]'::jsonb, 1, 1),
    (v_assignment_id, '"Gateway" trong BPMN thể hiện điều gì?', '["Điểm bắt đầu quy trình","Điểm ra quyết định/rẽ nhánh trong luồng quy trình (AND/OR/XOR)","Người thực hiện công việc","Kết thúc quy trình"]'::jsonb, 1, 2),
    (v_assignment_id, 'Sơ đồ AS-IS mô tả điều gì?', '["Quy trình mong muốn trong tương lai","Quy trình nghiệp vụ hiện tại đang vận hành thực tế","Quy trình lý tưởng theo lý thuyết","Quy trình của đối thủ cạnh tranh"]'::jsonb, 1, 3),
    (v_assignment_id, 'TO-BE khác AS-IS ở điểm nào?', '["Không khác biệt","TO-BE mô tả quy trình sau khi cải tiến/thay đổi (tương lai); AS-IS mô tả quy trình hiện tại","TO-BE luôn đơn giản hơn AS-IS","AS-IS chỉ dùng cho dự án Agile"]'::jsonb, 1, 4),
    (v_assignment_id, '"Happy Path" trong 1 quy trình là gì?', '["Luồng xử lý khi có lỗi xảy ra","Luồng xử lý chính, thành công, không gặp ngoại lệ (kịch bản lý tưởng)","Luồng dành riêng cho quản trị viên","Luồng không bao giờ xảy ra thực tế"]'::jsonb, 1, 5),
    (v_assignment_id, '"Exception Flow" khác Happy Path ở điểm nào?', '["Không khác biệt","Exception Flow mô tả các trường hợp lỗi/bất thường chệch khỏi luồng chính","Exception Flow luôn xảy ra trước Happy Path","Exception Flow không cần vẽ trong BPMN"]'::jsonb, 1, 6),
    (v_assignment_id, 'Trong BPMN, ký hiệu hình thoi (diamond) thường biểu diễn thành phần nào?', '["Task/Activity","Gateway (điểm quyết định)","Event (sự kiện bắt đầu/kết thúc)","Swimlane"]'::jsonb, 1, 7),
    (v_assignment_id, 'Khi vẽ quy trình "Duyệt khoản vay", bước "Kiểm tra lịch sử tín dụng bị từ chối" nên xếp vào loại flow nào?', '["Happy Path","Exception Flow (hoặc Alternative Flow) — vì đây là nhánh rẽ khi hồ sơ không đạt điều kiện","Không cần vẽ trong sơ đồ","Gateway"]'::jsonb, 1, 8),
    (v_assignment_id, 'Vì sao BA cần vẽ AS-IS trước khi thiết kế TO-BE?', '["Không cần thiết, có thể vẽ TO-BE trực tiếp","Để hiểu rõ hiện trạng, xác định điểm nghẽn thực sự cần cải tiến, tránh thiết kế TO-BE sai hướng","Chỉ để làm đẹp tài liệu","AS-IS chỉ cần thiết cho dự án lớn"]'::jsonb, 1, 9),
    (v_assignment_id, 'Một Task trong BPMN có nhiều actor (swimlane) cùng thực hiện là dấu hiệu của vấn đề gì?', '["Đây là thiết kế tốt, không có vấn đề","Có thể là lỗi thiết kế — 1 Task nên gắn với 1 actor chịu trách nhiệm rõ ràng, cần tách nhỏ nếu có nhiều actor","Luôn cần thêm nhiều Gateway","Không liên quan đến chất lượng mô hình hoá"]'::jsonb, 1, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — Thiếu Exception Flow', 'Nhóm dự án vẽ sơ đồ quy trình "Đăng ký vay tín chấp online" chỉ có 1 luồng duy nhất: Khách hàng nộp hồ sơ → Hệ thống duyệt tự động → Giải ngân. Khi vận hành thử, phát sinh nhiều trường hợp hồ sơ bị từ chối hoặc thiếu giấy tờ nhưng quy trình không có bước xử lý.
Yêu cầu: (1) Chỉ ra thiếu sót trong sơ đồ AS-IS/TO-BE ở trên. (2) Liệt kê tối thiểu 2 Exception Flow cần bổ sung và vị trí Gateway tương ứng.', 1, 14),
    (v_module_id, 'Case Study 2 — AS-IS vẽ sai swimlane', 'Khi khảo sát quy trình "Xử lý khiếu nại khách hàng" tại quầy giao dịch, BA vẽ toàn bộ các bước vào chung 1 swimlane "Nhân viên giao dịch", dù thực tế có bước phải chuyển hồ sơ lên "Bộ phận Chăm sóc khách hàng cấp 2" xử lý.
Yêu cầu: (1) Phân tích hậu quả của việc gộp sai swimlane khi trình bày cho stakeholder. (2) Đề xuất cách phân chia swimlane đúng cho quy trình trên.', 2, 14);

  -- ===== Buổi 5 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 5, 'Buổi 5: User Story và Acceptance Criteria', '- Cấu trúc User Story chuẩn (As a... I want... So that...), tiêu chí INVEST.
- Cấu trúc Acceptance Criteria (Given-When-Then).

Thực hành:
- Viết 2-3 User Story cho 1 tính năng cho trước.
- Viết Acceptance Criteria (Given-When-Then) cho mỗi User Story đã viết.', '- Giúp học viên nắm được:
- Viết được 1 User Story đạt chuẩn INVEST.
- Viết được Acceptance Criteria rõ ràng, đo lường được cho 1 User Story.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 5', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, 'Cấu trúc chuẩn của User Story là gì?', '["\"Tôi cần... vì vậy...\"","\"As a [role], I want [feature], so that [benefit]\"","\"Nếu... thì...\"","\"Given... When... Then...\""]'::jsonb, 1, 1),
    (v_assignment_id, '"Given-When-Then" là cấu trúc dùng để viết gì?', '["User Story","Acceptance Criteria","Business Rule","RACI Matrix"]'::jsonb, 1, 2),
    (v_assignment_id, 'Trong tiêu chí INVEST, chữ "I" là viết tắt của gì?', '["Interesting","Independent (Story độc lập, không phụ thuộc chặt vào Story khác)","Immediate","Internal"]'::jsonb, 1, 3),
    (v_assignment_id, 'Chữ "N" trong INVEST là viết tắt của gì?', '["Negotiable — Story có thể thương lượng/điều chỉnh chi tiết giữa BA/PO và Dev, không phải hợp đồng cứng nhắc","Negative","Normal","Numeric"]'::jsonb, 0, 4),
    (v_assignment_id, 'Chữ "T" trong INVEST nghĩa là gì?', '["Testable — Story phải có tiêu chí rõ ràng để kiểm chứng được là đã hoàn thành hay chưa","Timeless","Technical","Trusted"]'::jsonb, 0, 5),
    (v_assignment_id, 'User Story: "As a customer, I want to reset my password, so that I can regain access to my account" — phần "so that..." thể hiện điều gì?', '["Điều kiện kỹ thuật","Giá trị/lợi ích (business value) mà tính năng mang lại cho người dùng","Người thực hiện Story","Acceptance Criteria"]'::jsonb, 1, 6),
    (v_assignment_id, 'AC "Given tài khoản đã đăng ký, When khách hàng nhập đúng OTP, Then hệ thống kích hoạt tài khoản thành công" — đây là kịch bản gì?', '["Exception Flow","Happy Path (kịch bản thành công chính)","Business Rule","Use Case"]'::jsonb, 1, 7),
    (v_assignment_id, 'Một User Story "quá lớn", khó ước lượng và khó hoàn thành trong 1 sprint được gọi là gì?', '["Task","Epic — cần được chia nhỏ (split) thành các User Story nhỏ hơn để đạt tiêu chí \"Small\"","Bug","Spike"]'::jsonb, 1, 8),
    (v_assignment_id, 'Tiêu chí "V" (Valuable) trong INVEST yêu cầu điều gì?', '["Story phải có giá trị kỹ thuật cho Dev","Story phải mang lại giá trị rõ ràng cho người dùng/khách hàng hoặc business","Story phải viết bằng tiếng Anh","Story phải có ít nhất 3 Acceptance Criteria"]'::jsonb, 1, 9),
    (v_assignment_id, 'Acceptance Criteria khác User Story ở vai trò gì?', '["Không khác biệt, là 1 khái niệm","User Story mô tả nhu cầu ở mức khái quát (who/what/why); AC đặc tả chi tiết điều kiện để xác nhận Story hoàn thành đúng","AC luôn được viết trước User Story","AC chỉ dùng khi không có User Story"]'::jsonb, 1, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — User Story vi phạm INVEST', 'Đội dự án viết User Story: "As a user, I want the system to be fast and user-friendly, so that I am happy."
Yêu cầu: (1) Chỉ ra Story này vi phạm những tiêu chí nào trong INVEST (gợi ý: Testable, Small). (2) Viết lại thành 1-2 User Story cụ thể, đạt chuẩn INVEST.', 1, 14),
    (v_module_id, 'Case Study 2 — AC thiếu trường hợp biên', 'Story "As a customer, I want to transfer money to another account, so that I can pay my bills" chỉ có 1 AC duy nhất: "Given tài khoản đủ số dư, When khách hàng nhập đúng thông tin, Then giao dịch thành công."
Yêu cầu: (1) Chỉ ra rủi ro khi AC chỉ có duy nhất Happy Path. (2) Viết thêm ít nhất 2 AC cho trường hợp ngoại lệ (số dư không đủ, nhập sai thông tin tài khoản nhận).', 2, 14);

  insert into assignments (module_id, phase_id, title, type, description, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'PROJECT XUYÊN SUỐT (Buổi 5-12) — "Mở tài khoản thanh toán online (eKYC)"', 'project', 'Bối cảnh: Ngân hàng muốn triển khai tính năng "Mở tài khoản thanh toán online" trên App Mobile Banking, cho phép khách hàng cá nhân tự đăng ký mở tài khoản mới hoàn toàn online qua xác thực eKYC (chụp CMND/CCCD + ảnh chân dung, xác thực OTP), không cần đến quầy giao dịch. Project này sẽ được xây dựng tiếp nối qua các buổi 6-12.

Nhiệm vụ Buổi 5: Viết 2-3 User Story cho tính năng này (VD: đăng ký thông tin cá nhân, xác thực OTP số điện thoại, chụp/upload ảnh CMND/CCCD, chụp ảnh chân dung xác thực khuôn mặt) kèm Acceptance Criteria (Given-When-Then) đầy đủ Happy Path + tối thiểu 1 Exception cho mỗi Story.', 10, 14);

  -- ===== Buổi 6 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 6, 'Buổi 6: Use Case', '- Cấu trúc Use Case: Actor, Precondition/Postcondition, Main Flow, Alternative Flow.
- So sánh Use Case với User Story — khi nào dùng cái nào.

Thực hành:
- Viết 1 Use Case đơn giản (1 chức năng) gồm Actor, Pre/Post-condition, Main Flow, 1 Alternative Flow.', '- Giúp học viên nắm được:
- Viết được 1 Use Case đơn giản đầy đủ cấu trúc.
- Phân biệt rõ Use Case và User Story.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 6', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, 'Thành phần nào KHÔNG thuộc cấu trúc chuẩn của 1 Use Case?', '["Actor","Precondition/Postcondition","Main Flow","Story Point (điểm ước lượng độ phức tạp)"]'::jsonb, 3, 1),
    (v_assignment_id, '"Precondition" trong Use Case nghĩa là gì?', '["Kết quả sau khi Use Case hoàn thành","Điều kiện phải đúng/thoả mãn TRƯỚC KHI Use Case bắt đầu thực hiện","Người thực hiện Use Case","Bước đầu tiên trong Main Flow"]'::jsonb, 1, 2),
    (v_assignment_id, '"Postcondition" nghĩa là gì?', '["Điều kiện trước khi bắt đầu","Trạng thái/kết quả của hệ thống SAU KHI Use Case hoàn thành (thành công hoặc thất bại)","Tên của Actor","Số bước trong Main Flow"]'::jsonb, 1, 3),
    (v_assignment_id, '"Alternative Flow" trong Use Case là gì?', '["Luồng xử lý lỗi hệ thống nghiêm trọng","Nhánh rẽ hợp lệ khác với Main Flow nhưng vẫn dẫn đến kết quả mong muốn, không phải là lỗi","Tên gọi khác của Precondition","Chỉ áp dụng khi có nhiều hơn 1 Actor"]'::jsonb, 1, 4),
    (v_assignment_id, 'Điểm khác biệt CHÍNH giữa Use Case và User Story là gì?', '["Không có khác biệt, dùng thay thế nhau","Use Case mô tả chi tiết tương tác Actor-Hệ thống theo từng bước, phù hợp hệ thống phức tạp; User Story ngắn gọn, tập trung giá trị người dùng","User Story luôn dài hơn Use Case","Use Case không có Actor"]'::jsonb, 1, 5),
    (v_assignment_id, '"Actor" trong Use Case có thể là gì?', '["Chỉ là con người","Con người, hệ thống khác, hoặc thiết bị bên ngoài tương tác với hệ thống đang xây dựng","Chỉ là hệ thống backend","Chỉ là khách hàng cuối"]'::jsonb, 1, 6),
    (v_assignment_id, 'Khi nào nên ưu tiên dùng Use Case thay vì chỉ dùng User Story?', '["Khi dự án chạy Scrum thuần tuý, sprint ngắn","Khi hệ thống có nhiều luồng tương tác phức tạp, nhiều actor, cần đặc tả chi tiết (VD: hệ thống core banking)","Không bao giờ cần Use Case","Use Case chỉ dùng cho tài liệu marketing"]'::jsonb, 1, 7),
    (v_assignment_id, '"Actor phụ" (secondary actor) trong Use Case "Rút tiền tại ATM" có thể là ai/hệ thống nào?', '["Chỉ có khách hàng","Hệ thống ngân hàng lõi (core banking) xác thực số dư — hỗ trợ hệ thống chính hoàn thành Use Case","Không có actor phụ trong Use Case này","Actor phụ luôn là con người"]'::jsonb, 1, 8),
    (v_assignment_id, 'Một Use Case tốt nên có bao nhiêu Actor chính (primary actor)?', '["Không giới hạn, càng nhiều càng tốt","Thường có 1 actor chính rõ ràng khởi tạo Use Case, để tránh mơ hồ trách nhiệm/mục tiêu","Bắt buộc phải có ít nhất 3","Không cần actor chính"]'::jsonb, 1, 9),
    (v_assignment_id, 'Trong Use Case "Đăng nhập hệ thống", bước "Hệ thống khoá tài khoản sau 5 lần nhập sai mật khẩu" nên đặt ở đâu?', '["Main Flow","Precondition","Alternative Flow hoặc Exception Flow","Actor"]'::jsonb, 2, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — Use Case thiếu Postcondition', 'Đội dự án viết Use Case "Thanh toán hoá đơn điện" chỉ có Actor, Precondition, Main Flow — không có Postcondition, dẫn đến Dev không rõ hệ thống cần cập nhật trạng thái giao dịch thế nào sau khi hoàn tất.
Yêu cầu: (1) Giải thích vì sao thiếu Postcondition gây rủi ro khi bàn giao cho Dev. (2) Viết Postcondition phù hợp cho Use Case này (cả trường hợp thành công và thất bại).', 1, 14),
    (v_module_id, 'Case Study 2 — Nhầm lẫn Use Case và User Story', 'Một BA mới báo cáo: "Em đã viết xong Use Case: ''As a user, I want to view my transaction history, so that I can track my spending.''"
Yêu cầu: (1) Chỉ ra lỗi trong phát biểu trên (đây thực chất là gì, không phải Use Case). (2) Viết lại đúng dưới dạng Use Case với đầy đủ Actor, Pre/Postcondition, Main Flow tối thiểu 3 bước.', 2, 14);

  insert into assignments (module_id, phase_id, title, type, description, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'PROJECT (Buổi 6) — Viết Use Case cho "Mở tài khoản thanh toán online"', 'project', 'Dựa trên User Story đã viết ở Buổi 5, viết Use Case đầy đủ cho "Mở tài khoản thanh toán online qua App":
- Actor chính: Khách hàng cá nhân; Actor phụ: Hệ thống eKYC (xác thực giấy tờ + khuôn mặt), Hệ thống Core Banking (khởi tạo số tài khoản)
- Precondition: Khách hàng đã cài App, chưa có tài khoản thanh toán tại ngân hàng
- Main Flow: Nhập thông tin cá nhân → Xác thực OTP số điện thoại → Chụp/upload CMND/CCCD → Chụp ảnh chân dung (liveness check) → Hệ thống đối chiếu eKYC → Xác nhận mở tài khoản → Nhận số tài khoản
- Alternative Flow: Ảnh CMND/CCCD mờ, cần chụp lại
- Exception Flow: Khách hàng dưới 18 tuổi → từ chối; OTP nhập sai quá 3 lần → khoá phiên đăng ký; eKYC không khớp khuôn mặt → chuyển xác minh thủ công
- Postcondition: Tài khoản được tạo ở trạng thái "Chờ kích hoạt" hoặc bị từ chối', 10, 14);

  -- ===== Buổi 7 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 7, 'Buổi 7: Business Rule và quản lý trạng thái', '- Khái niệm Business Rule, các loại Business Rule thường gặp.
- Khái niệm trạng thái (state) và chuyển trạng thái (state transition).

Thực hành:
- Viết 3-5 Business Rule cho 1 tình huống cho trước.
- Vẽ 1 state diagram nhỏ (ví dụ: trạng thái đơn hàng: Tạo mới → Chờ duyệt → Đã duyệt/Từ chối).', '- Giúp học viên nắm được:
- Nhận diện và viết được Business Rule cơ bản.
- Vẽ được 1 sơ đồ trạng thái đơn giản cho 1 đối tượng nghiệp vụ.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 7', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, '"Business Rule" là gì?', '["Sơ đồ giao diện màn hình","Quy định/ràng buộc nghiệp vụ chi phối cách hệ thống hoặc quy trình phải vận hành","Tên gọi khác của User Story","Chỉ áp dụng cho hệ thống ngân hàng"]'::jsonb, 1, 1),
    (v_assignment_id, 'Loại Business Rule nào sau đây là "Constraint Rule" (ràng buộc)?', '["\"Lãi suất = số dư x lãi suất năm / 365\"","\"Khách hàng dưới 18 tuổi không được mở tài khoản thanh toán online\"","\"Nếu KH là VIP thì tự động cấp hạn mức cao hơn\"","Không có loại này"]'::jsonb, 1, 2),
    (v_assignment_id, 'Loại Business Rule "Computation Rule" (tính toán) là gì?', '["Quy định về độ tuổi tối thiểu","Công thức/quy tắc tính toán ra 1 giá trị (VD: cách tính lãi suất, phí giao dịch)","Quy định về quyền truy cập","Không tồn tại trong BA"]'::jsonb, 1, 3),
    (v_assignment_id, '"State" (trạng thái) của 1 đối tượng nghiệp vụ thể hiện điều gì?', '["Giao diện hiển thị đối tượng đó","Tình trạng hiện tại của đối tượng tại 1 thời điểm trong vòng đời của nó","Tên gọi của đối tượng","Người tạo ra đối tượng"]'::jsonb, 1, 4),
    (v_assignment_id, '"State Transition" (chuyển trạng thái) là gì?', '["Xoá đối tượng khỏi hệ thống","Sự thay đổi từ trạng thái này sang trạng thái khác, thường được kích hoạt bởi 1 sự kiện/hành động cụ thể","Tên gọi khác của Business Rule","Chỉ xảy ra 1 lần duy nhất trong vòng đời đối tượng"]'::jsonb, 1, 5),
    (v_assignment_id, 'Trong sơ đồ trạng thái đơn hàng "Tạo mới → Chờ duyệt → Đã duyệt/Từ chối", sự kiện nào kích hoạt chuyển từ "Chờ duyệt" sang "Từ chối"?', '["Khách hàng huỷ đơn ngẫu nhiên","Người duyệt kiểm tra và phát hiện đơn không đạt điều kiện (vi phạm 1 Business Rule cụ thể)","Hệ thống tự động sau 24h không lý do","Không có sự kiện nào"]'::jsonb, 1, 6),
    (v_assignment_id, 'Vì sao BA cần viết rõ Business Rule thay vì để Dev tự suy đoán?', '["Không cần thiết, Dev luôn hiểu đúng nghiệp vụ","Vì Business Rule là logic nghiệp vụ quan trọng quyết định tính đúng đắn của hệ thống","Business Rule chỉ mang tính tham khảo","Business Rule luôn giống nhau giữa các ngân hàng"]'::jsonb, 1, 7),
    (v_assignment_id, 'Một trạng thái "bị kẹt" (không có đường ra) trong sơ đồ trạng thái là lỗi gì?', '["Thiết kế đúng, không có vấn đề","Lỗi thiết kế — mọi trạng thái trung gian cần có ít nhất 1 transition dẫn đến trạng thái kết thúc","Chỉ xảy ra ở hệ thống lớn","Không liên quan đến BA"]'::jsonb, 1, 8),
    (v_assignment_id, 'Business Rule "Giao dịch chuyển tiền trên 500 triệu VNĐ phải qua phê duyệt cấp 2" thuộc loại nào?', '["Computation Rule","Constraint Rule (ràng buộc điều kiện thực hiện)","Inference Rule","Không phải Business Rule"]'::jsonb, 1, 9),
    (v_assignment_id, 'Khi viết Business Rule, điều gì KHÔNG nên có trong nội dung Rule?', '["Điều kiện áp dụng rõ ràng","Mô tả chi tiết giao diện màn hình (thuộc đặc tả UI, không phải Business Rule)","Ngưỡng/giá trị cụ thể","Đối tượng nghiệp vụ áp dụng"]'::jsonb, 1, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — Business Rule mơ hồ', 'Tài liệu ghi: "Khách hàng VIP sẽ được ưu đãi đặc biệt khi giao dịch." Dev không biết "VIP" là tiêu chí gì, "ưu đãi đặc biệt" là gì cụ thể.
Yêu cầu: (1) Chỉ ra vì sao Business Rule này không đạt chuẩn (thiếu điều kiện đo lường được). (2) Viết lại thành 2 Business Rule cụ thể, có điều kiện và giá trị rõ ràng.', 1, 14),
    (v_module_id, 'Case Study 2 — Sơ đồ trạng thái thiếu nhánh', 'Sơ đồ trạng thái hồ sơ vay chỉ có: "Nộp hồ sơ → Đang xét duyệt → Đã duyệt." Không có trạng thái "Từ chối" hay "Yêu cầu bổ sung hồ sơ", trong khi thực tế 40% hồ sơ bị từ chối hoặc yêu cầu bổ sung.
Yêu cầu: (1) Phân tích rủi ro khi sơ đồ trạng thái thiếu các nhánh này. (2) Mô tả lại sơ đồ trạng thái đầy đủ hơn kèm sự kiện kích hoạt mỗi transition.', 2, 14);

  insert into assignments (module_id, phase_id, title, type, description, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'PROJECT (Buổi 7) — Business Rule + State Diagram cho "Mở tài khoản thanh toán online"', 'project', '- Business Rules: (1) Khách hàng phải từ đủ 18 tuổi mới được tự đăng ký mở tài khoản online; (2) Tài khoản mới mở qua eKYC (chưa xác thực trực tiếp) bị giới hạn hạn mức giao dịch tối đa 20 triệu VNĐ/ngày cho đến khi xác thực bổ sung tại quầy; (3) Khách hàng nhập sai OTP quá 3 lần sẽ bị khoá phiên đăng ký trong 30 phút; (4) Hồ sơ eKYC không khớp khuôn mặt sẽ tự động chuyển sang hàng đợi xác minh thủ công (manual review), không tự động từ chối.
- State Diagram của hồ sơ mở tài khoản: Khởi tạo → Chờ xác thực OTP → Chờ đối chiếu eKYC → (Đã duyệt tự động | Chờ xác minh thủ công | Từ chối) → Đã kích hoạt tài khoản

Nhiệm vụ: Học viên hoàn thiện thêm chi tiết Business Rule và vẽ state diagram đầy đủ dựa trên khung trên.', 10, 14);

  -- ===== Buổi 8 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 8, 'Buổi 8: Phân tích giao diện, dữ liệu và tài liệu BA', '- Cách đọc hiểu 1 wireframe/mockup ở góc độ BA.
- Data Dictionary cơ bản: tên trường, kiểu dữ liệu, độ dài, bắt buộc, nguồn dữ liệu, rule, giá trị mẫu.

Thực hành:
- Viết đặc tả cho 1 màn hình đơn giản (form nhập liệu) kèm bảng Data Dictionary cho các trường chính.', '- Giúp học viên nắm được:
- Đọc hiểu và góp ý được 1 wireframe đơn giản.
- Viết được đặc tả màn hình cơ bản kèm Data Dictionary.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 8', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, '"Data Dictionary" gồm những thông tin cơ bản nào?', '["Chỉ tên trường dữ liệu","Tên trường, kiểu dữ liệu, độ dài, bắt buộc hay không, nguồn dữ liệu, rule áp dụng, giá trị mẫu","Chỉ mô tả giao diện màn hình","Chỉ chứa Business Rule"]'::jsonb, 1, 1),
    (v_assignment_id, 'Khi đọc 1 wireframe ở góc độ BA, điều quan trọng nhất cần kiểm tra là gì?', '["Màu sắc có đẹp không","Wireframe có phản ánh đúng và đủ luồng nghiệp vụ, dữ liệu cần thu thập, và các trường hợp ngoại lệ hay không","Font chữ sử dụng","Không cần kiểm tra gì, đó là việc của UI/UX Designer"]'::jsonb, 1, 2),
    (v_assignment_id, 'Trường dữ liệu "Số điện thoại" nên có ràng buộc (rule) nào trong Data Dictionary?', '["Không cần ràng buộc gì","Định dạng số, độ dài cố định (VD: 10 số), bắt buộc nhập, kèm rule validate đầu số hợp lệ","Chỉ cần ghi \"kiểu chuỗi\"","Luôn để trống được"]'::jsonb, 1, 3),
    (v_assignment_id, '"Bắt buộc" (Mandatory) trong Data Dictionary nghĩa là gì?', '["Trường dữ liệu chỉ hiển thị cho admin","Trường dữ liệu người dùng PHẢI nhập, hệ thống không cho phép bỏ trống khi submit","Trường dữ liệu tự động tính toán","Trường không lưu vào database"]'::jsonb, 1, 4),
    (v_assignment_id, 'Khi đặc tả màn hình 1 form nhập liệu, ngoài các trường dữ liệu, BA cần đặc tả thêm điều gì?', '["Không cần gì thêm ngoài tên trường","Validation rule cho từng trường, thông báo lỗi, hành vi các nút chức năng, luồng khi submit thành công/thất bại","Chỉ cần màu sắc nút bấm","Chỉ cần vị trí các trường trên màn hình"]'::jsonb, 1, 5),
    (v_assignment_id, 'Trường "Ngày sinh" trong 1 form đăng ký nên có kiểu dữ liệu và rule nào?', '["Kiểu chuỗi tự do, không giới hạn","Kiểu Date, có rule kiểm tra khách hàng đủ tuổi tối thiểu theo quy định","Không cần validate","Kiểu số nguyên"]'::jsonb, 1, 6),
    (v_assignment_id, 'Vì sao BA cần đọc hiểu wireframe TRƯỚC khi Dev code, không phải sau?', '["Không có lý do đặc biệt","Để phát hiện sớm sai sót/thiếu sót giữa thiết kế UI và yêu cầu nghiệp vụ, tránh sửa lại tốn kém","Chỉ để ký duyệt tài liệu","Wireframe không liên quan đến công việc BA"]'::jsonb, 1, 7),
    (v_assignment_id, '"Nguồn dữ liệu" (data source) trong Data Dictionary dùng để làm gì?', '["Trang trí tài liệu","Xác định trường dữ liệu lấy từ đâu (người dùng nhập tay, hệ thống khác trả về, tính toán tự động)","Không có ý nghĩa thực tế","Chỉ dùng cho báo cáo"]'::jsonb, 1, 8),
    (v_assignment_id, 'Khi phát hiện wireframe thiếu trường "Số CMND/CCCD" trong khi yêu cầu bắt buộc phải thu thập, BA nên làm gì?', '["Bỏ qua, để Dev tự bổ sung khi code","Phản hồi ngay cho UX/UI Designer để bổ sung trước khi chuyển giao cho Dev","Tự ý sửa wireframe mà không thông báo","Không cần quan tâm vì đây là việc của QA"]'::jsonb, 1, 9),
    (v_assignment_id, 'Giá trị mẫu (sample value) trong Data Dictionary có tác dụng gì?', '["Không có tác dụng thực tế","Giúp Dev/QA hiểu rõ định dạng thực tế mong đợi của dữ liệu, hỗ trợ viết test case","Chỉ để trang trí tài liệu","Thay thế hoàn toàn cho Business Rule"]'::jsonb, 1, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — Wireframe thiếu validation', 'Wireframe màn hình "Đăng ký vay online" có trường "Thu nhập hàng tháng" nhưng không ghi chú giới hạn giá trị. Khi Dev code xong, hệ thống cho phép nhập số âm hoặc số quá lớn không hợp lý.
Yêu cầu: (1) Chỉ ra lỗi trong quá trình đặc tả dẫn đến tình huống này. (2) Viết Data Dictionary đầy đủ cho trường "Thu nhập hàng tháng" (kiểu dữ liệu, độ dài, rule, giá trị mẫu).', 1, 14),
    (v_module_id, 'Case Study 2 — Thiếu thông báo lỗi', 'Màn hình đăng nhập chỉ đặc tả "Nếu sai mật khẩu thì báo lỗi" mà không ghi cụ thể nội dung thông báo, dẫn đến Dev tự viết "Error 401" hiển thị trực tiếp cho người dùng cuối.
Yêu cầu: (1) Phân tích vì sao đặc tả mơ hồ này gây trải nghiệm xấu cho người dùng. (2) Viết lại đặc tả thông báo lỗi cụ thể, thân thiện cho 2 trường hợp: sai mật khẩu, tài khoản bị khoá.', 2, 14);

  insert into assignments (module_id, phase_id, title, type, description, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'PROJECT (Buổi 8) — Đặc tả UI + Data Dictionary cho "Mở tài khoản thanh toán online"', 'project', 'Các bước màn hình (dạng wizard): (1) Nhập số điện thoại + OTP, (2) Nhập thông tin cá nhân (họ tên, ngày sinh, số CMND/CCCD, địa chỉ, email), (3) Chụp/upload ảnh 2 mặt CMND/CCCD, (4) Chụp ảnh chân dung (liveness), (5) Xác nhận thông tin & hoàn tất
Data Dictionary tối thiểu: Họ tên (text, bắt buộc), Ngày sinh (date, bắt buộc, rule >=18 tuổi), Số CMND/CCCD (numeric string 9-12 ký tự, bắt buộc, unique), Số điện thoại (numeric string 10 số, bắt buộc, đã xác thực OTP), Email (text, định dạng email, không bắt buộc), Ảnh giấy tờ (file image, bắt buộc, jpg/png, tối đa 5MB)

Nhiệm vụ: Học viên hoàn thiện đặc tả chi tiết cho từng bước màn hình + Data Dictionary đầy đủ, có validation rule và thông báo lỗi cho từng trường.', 10, 14);

  -- ===== Buổi 9 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 9, 'Buổi 9: UAT và bàn giao dự án', '- Vai trò BA trong giai đoạn kiểm thử nghiệm thu (UAT).
- Quy trình nghiệm thu, bàn giao và go-live.

Thực hành:
- Thảo luận nhóm: liệt kê các đầu việc BA cần làm trong 1 đợt UAT giả định.', '- Giúp học viên nắm được:
- Hiểu vai trò và trách nhiệm của BA khi dự án bước vào UAT và go-live.
- Hiểu quy trình bàn giao 1 dự án phần mềm.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 9', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, 'UAT (User Acceptance Testing) là gì?', '["Kiểm thử đơn vị do Dev thực hiện","Giai đoạn kiểm thử nghiệm thu do người dùng/đại diện nghiệp vụ thực hiện để xác nhận hệ thống đáp ứng đúng nhu cầu thực tế","Kiểm thử hiệu năng hệ thống","Kiểm thử bảo mật"]'::jsonb, 1, 1),
    (v_assignment_id, 'Vai trò của BA trong giai đoạn UAT thường là gì?', '["Không tham gia, đây là việc của QA","Hỗ trợ xây dựng kịch bản UAT dựa trên yêu cầu/AC đã đặc tả, giải thích nghiệp vụ, tổng hợp defect nghiệp vụ","Chỉ ký duyệt tài liệu cuối cùng","Viết code sửa lỗi trực tiếp"]'::jsonb, 1, 2),
    (v_assignment_id, 'UAT khác với kiểm thử chức năng (Functional Testing) do QA thực hiện ở điểm nào?', '["Không khác biệt","UAT do người dùng nghiệp vụ thực hiện, tập trung xác nhận hệ thống đáp ứng NHU CẦU THỰC TẾ; QA testing xác nhận hệ thống ĐÚNG THEO ĐẶC TẢ kỹ thuật","UAT luôn thực hiện trước Functional Testing","UAT chỉ áp dụng cho dự án nhỏ"]'::jsonb, 1, 3),
    (v_assignment_id, 'Kịch bản UAT nên được xây dựng dựa trên tài liệu nào?', '["Chỉ dựa trên trí nhớ của BA","Dựa trên User Story/Use Case và Acceptance Criteria đã được thống nhất với stakeholder","Dựa trên code của Dev","Không cần tài liệu tham chiếu"]'::jsonb, 1, 4),
    (v_assignment_id, '"Go-live" trong vòng đời dự án nghĩa là gì?', '["Giai đoạn khảo sát ban đầu","Thời điểm hệ thống chính thức được đưa vào vận hành thực tế cho người dùng cuối","Giai đoạn viết tài liệu yêu cầu","Giai đoạn thiết kế UI"]'::jsonb, 1, 5),
    (v_assignment_id, 'Khi UAT phát hiện 1 defect, BA cần làm gì?', '["Tự sửa code","Làm rõ đây là lỗi nghiệp vụ hay hiểu sai yêu cầu, phối hợp Dev/QA xác định mức độ ưu tiên và hướng xử lý","Bỏ qua, để Dev tự quyết định","Không có trách nhiệm gì trong việc này"]'::jsonb, 1, 6),
    (v_assignment_id, 'Điều kiện nào KHÔNG nên là tiêu chí "Go/No-Go" quyết định go-live?', '["Tỷ lệ pass UAT đạt ngưỡng thống nhất","Không còn defect nghiêm trọng (Critical/Blocker) mở","Ý kiến cá nhân không chính thức của 1 thành viên bất kỳ trong nhóm","Đã có kế hoạch rollback nếu sự cố xảy ra"]'::jsonb, 2, 7),
    (v_assignment_id, 'Tài liệu nào thường cần chuẩn bị khi bàn giao (handover) dự án sau go-live?', '["Chỉ cần bàn giao miệng","Tài liệu hướng dẫn sử dụng, tài liệu vận hành, danh sách issue tồn đọng, thông tin liên hệ hỗ trợ","Không cần tài liệu gì","Chỉ cần source code"]'::jsonb, 1, 8),
    (v_assignment_id, 'Vì sao BA cần có mặt trong giai đoạn UAT dù không trực tiếp thực hiện test?', '["Không cần thiết","Để giải thích đúng ngữ cảnh nghiệp vụ khi người test thắc mắc, tránh hiểu sai giữa \"lỗi hệ thống\" và \"chưa hiểu đúng nghiệp vụ\"","Chỉ để điểm danh","Để thay QA viết test case kỹ thuật"]'::jsonb, 1, 9),
    (v_assignment_id, 'Sau khi go-live, giai đoạn nào BA cần tiếp tục theo dõi?', '["Không cần theo dõi gì thêm","Giai đoạn hypercare/ổn định sau go-live — theo dõi phản hồi người dùng thực tế, phát hiện sớm vấn đề phát sinh","Chỉ cần theo dõi trong 1 ngày duy nhất","Đây hoàn toàn là việc của bộ phận vận hành, BA không liên quan"]'::jsonb, 1, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — UAT không dựa trên AC', 'Nhóm UAT test tính năng "Chuyển tiền nhanh 24/7" chỉ dựa trên hiểu biết cá nhân, không tham chiếu Acceptance Criteria đã chốt. Kết quả bỏ sót test case "chuyển tiền ngoài giờ hành chính" — 1 AC quan trọng đã thống nhất trước đó.
Yêu cầu: (1) Phân tích rủi ro của việc UAT không bám theo AC. (2) Đề xuất quy trình BA nên áp dụng để đảm bảo kịch bản UAT bao phủ đủ AC.', 1, 14),
    (v_module_id, 'Case Study 2 — Go-live khi còn defect Critical', 'Trước ngày go-live 1 hôm, hệ thống còn 1 defect Critical (khách hàng có thể xem nhầm số dư người khác trong 1 số trường hợp hiếm). PM đề xuất vẫn go-live đúng hạn vì "tỷ lệ xảy ra thấp".
Yêu cầu: (1) Đánh giá rủi ro của quyết định go-live trong tình huống này, đặc biệt với dự án ngân hàng. (2) Đề xuất phương án BA nên khuyến nghị.', 2, 14);

  insert into assignments (module_id, phase_id, title, type, description, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'PROJECT (Buổi 9) — Lập kế hoạch UAT cho "Mở tài khoản thanh toán online"', 'project', 'Dựa trên toàn bộ User Story + AC (buổi 5), Use Case (buổi 6), Business Rule + State (buổi 7), đặc tả UI + Data Dictionary (buổi 8) đã xây dựng, học viên lập danh sách kịch bản UAT tối thiểu 8 kịch bản, bao gồm: mở tài khoản thành công (Happy Path), khách hàng dưới 18 tuổi bị từ chối, OTP sai quá 3 lần, ảnh CMND mờ phải chụp lại, eKYC không khớp khuôn mặt chuyển xác minh thủ công, hạn mức giao dịch bị giới hạn đúng theo Business Rule, các trường bắt buộc bị bỏ trống bị chặn submit, thông báo lỗi hiển thị đúng và thân thiện.', 10, 14);

  -- ===== Buổi 10 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 10, 'Buổi 10: Mini-case phần 1: Khảo sát, flow, User Story và AC', '- Áp dụng kỹ thuật khảo sát (buổi 3) vào 1 mini-case do giảng viên giao.
- Vẽ flow AS-IS đơn giản cho mini-case (buổi 4).
- Viết User Story và Acceptance Criteria cho mini-case (buổi 5).

Thực hành:
- Làm việc theo nhóm: khảo sát nhỏ (đọc đề bài + hỏi giảng viên đóng vai khách hàng) → vẽ flow → viết User Story + AC cho mini-case.', '- Giúp học viên nắm được:
- Vận dụng liên kết được các kỹ thuật đã học (buổi 1-5) vào 1 case cụ thể.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 10', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, 'Khi khảo sát 1 mini-case do giảng viên đóng vai khách hàng, kỹ thuật elicitation nào đang được áp dụng?', '["Survey","Interview (phỏng vấn trực tiếp)","Document Analysis","Observation"]'::jsonb, 1, 1),
    (v_assignment_id, 'Trước khi vẽ flow AS-IS cho 1 mini-case, bước đầu tiên BA cần làm là gì?', '["Vẽ TO-BE trước","Thu thập đủ thông tin về quy trình hiện tại qua khảo sát/elicitation","Viết User Story ngay","Viết Business Rule"]'::jsonb, 1, 2),
    (v_assignment_id, 'Khi tổng hợp thông tin khảo sát thành flow, BA cần đảm bảo điều gì trước khi chuyển sang viết User Story?', '["Flow chỉ cần đẹp về hình thức","Flow phản ánh đúng thực tế đã khảo sát, đã xác nhận lại với \"khách hàng\" trước khi dùng làm cơ sở viết User Story","Không cần xác nhận lại","User Story luôn viết trước flow"]'::jsonb, 1, 3),
    (v_assignment_id, 'User Story viết từ 1 flow AS-IS/TO-BE nên tuân theo tiêu chí nào đã học?', '["Không cần tiêu chí gì","INVEST","RACI","BPMN"]'::jsonb, 1, 4),
    (v_assignment_id, 'Nếu trong khảo sát, "khách hàng" đưa ra yêu cầu mơ hồ, BA nên áp dụng kỹ thuật nào đã học ở buổi 3?', '["Bỏ qua yêu cầu đó","5 Whys hoặc đặt câu hỏi mở để làm rõ nhu cầu thật","Tự suy đoán và viết User Story luôn","Chuyển thẳng cho Dev quyết định"]'::jsonb, 1, 5),
    (v_assignment_id, 'Trong mini-case, nếu phát hiện quy trình có nhánh ngoại lệ, BA nên thể hiện ở đâu?', '["Bỏ qua vì không quan trọng","Exception Flow trong sơ đồ flow, và AC riêng cho nhánh này trong User Story tương ứng","Chỉ ghi chú miệng, không cần vẽ","Business Rule, không liên quan đến flow"]'::jsonb, 1, 6),
    (v_assignment_id, 'Acceptance Criteria viết cho mini-case cần đảm bảo tiêu chí nào?', '["Càng dài càng tốt","Testable — có thể kiểm chứng được cụ thể theo Given-When-Then","Không cần đo lường được","Chỉ cần mô tả cảm tính"]'::jsonb, 1, 7),
    (v_assignment_id, 'Khi làm việc nhóm trong mini-case, vai trò nào nên đại diện phỏng vấn giảng viên (đóng vai khách hàng)?', '["Bất kỳ ai không cần chuẩn bị","Nên phân công rõ, có chuẩn bị câu hỏi trước (dựa trên kỹ thuật đặt câu hỏi mở/5 Whys) để khai thác hiệu quả","Không cần phỏng vấn, tự suy đoán yêu cầu","Chỉ cần hỏi 1 câu duy nhất"]'::jsonb, 1, 8),
    (v_assignment_id, 'Vì sao mini-case buổi 10 nên gắn liền với project "Mở tài khoản online" đã làm từ buổi 5 thay vì làm 1 case hoàn toàn mới?', '["Không có lý do, làm case mới sẽ tốt hơn","Giúp học viên thấy được tính liên kết, nhất quán giữa các kỹ thuật BA qua toàn bộ vòng đời của 1 tính năng thực tế","Chỉ để tiết kiệm thời gian chuẩn bị của giảng viên","Không liên quan đến mục tiêu học tập"]'::jsonb, 1, 9),
    (v_assignment_id, 'Kết quả đầu ra chính của buổi 10 trong mini-case là gì?', '["Chỉ có flow, chưa cần User Story","Flow AS-IS/TO-BE của tình huống mở rộng + bộ User Story/AC hoàn chỉnh cho tình huống đó","Chỉ có Business Rule","Chỉ có Use Case"]'::jsonb, 1, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — Nâng hạn mức sau xác thực bổ sung', 'Sau khi mở tài khoản online, nhiều khách hàng phản ánh hạn mức 20 triệu/ngày (Business Rule buổi 7) quá thấp so với nhu cầu, muốn nâng hạn mức mà không phải ra quầy nếu có thể xác thực bổ sung qua video call với nhân viên ngân hàng.
Yêu cầu: (1) Đóng vai BA, liệt kê 3-5 câu hỏi khảo sát cần hỏi "khách hàng" (giảng viên đóng vai) để làm rõ nhu cầu. (2) Mô tả flow AS-IS (hiện chưa có tính năng này, phải ra quầy) và TO-BE (có video call xác thực).', 1, 14),
    (v_module_id, 'Case Study 2 — Flow thiếu đồng bộ với Business Rule', 'Một nhóm vẽ flow TO-BE cho "Nâng hạn mức" cho phép nâng lên bất kỳ mức nào khách hàng yêu cầu ngay sau video call, không đối chiếu lại với Business Rule về ngưỡng hạn mức tối đa theo phân loại khách hàng.
Yêu cầu: (1) Chỉ ra sự thiếu nhất quán giữa flow mới và Business Rule đã có. (2) Đề xuất cách bổ sung Gateway/Business Rule vào flow để đảm bảo tính nhất quán.', 2, 14);

  insert into assignments (module_id, phase_id, title, type, description, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'PROJECT (Buổi 10) — Mini-case phần 1: Mở rộng project "Mở tài khoản online"', 'project', 'Khảo sát (đóng vai phỏng vấn giảng viên) tình huống mở rộng "Nâng hạn mức giao dịch sau xác thực bổ sung" cho tài khoản mở online → Vẽ flow AS-IS/TO-BE → Viết User Story + AC (theo INVEST + Given-When-Then) cho tính năng này, liên kết với Business Rule giới hạn hạn mức đã định nghĩa ở buổi 7.', 10, 14);

  -- ===== Buổi 11 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 11, 'Buổi 11: Mini-case phần 2: Use Case, Business Rule và UI', '- Viết Use Case cho mini-case (buổi 6).
- Viết Business Rule liên quan (buổi 7).
- Đặc tả màn hình cơ bản cho mini-case (buổi 8).

Thực hành:
- Làm việc theo nhóm: viết Use Case + Business Rule + đặc tả 1 màn hình, hoàn thiện bộ hồ sơ mini-case để chuẩn bị trình bày.', '- Giúp học viên nắm được:
- Hoàn thiện được 1 bộ sản phẩm mini-case liên kết đầy đủ các kỹ thuật đã học.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 11', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, 'Actor chính trong Use Case "Yêu cầu nâng hạn mức giao dịch" là ai?', '["Nhân viên ngân hàng","Khách hàng cá nhân đã có tài khoản mở online","Hệ thống Core Banking","Không có actor chính"]'::jsonb, 1, 1),
    (v_assignment_id, 'Actor phụ nào có thể tham gia Use Case "Nâng hạn mức" qua video call?', '["Không cần actor phụ","Nhân viên ngân hàng xác thực qua video call (con người) đóng vai actor phụ hỗ trợ xác nhận danh tính","Chỉ có hệ thống, không có con người tham gia","Actor phụ luôn là hệ thống khác"]'::jsonb, 1, 2),
    (v_assignment_id, 'Business Rule "Hạn mức mới sau xác thực bổ sung tối đa không vượt quá 200 triệu/ngày với khách hàng thường" thuộc loại Business Rule nào?', '["Computation Rule","Constraint Rule","Không phải Business Rule","Inference Rule"]'::jsonb, 1, 3),
    (v_assignment_id, 'Khi đặc tả màn hình "Yêu cầu nâng hạn mức", trường "Hạn mức mong muốn" nên có rule nào?', '["Không cần rule, khách hàng nhập tự do","Rule kiểm tra giá trị nhập không vượt ngưỡng tối đa theo Business Rule, hiển thị cảnh báo nếu vượt","Chỉ cho phép nhập số cố định duy nhất","Trường này không bắt buộc"]'::jsonb, 1, 4),
    (v_assignment_id, 'Postcondition của Use Case "Nâng hạn mức" khi xác thực video call THẤT BẠI là gì?', '["Hạn mức tự động được nâng","Yêu cầu nâng hạn mức bị từ chối hoặc chuyển sang xử lý thủ công tại quầy, hạn mức giữ nguyên như cũ","Tài khoản bị khoá vĩnh viễn","Không cần định nghĩa Postcondition cho trường hợp thất bại"]'::jsonb, 1, 5),
    (v_assignment_id, 'Trong Use Case "Nâng hạn mức", bước "Khách hàng đặt lịch video call" nên thuộc Main Flow hay Alternative Flow?', '["Alternative Flow","Main Flow — vì đây là bước bắt buộc trong luồng chính để hoàn thành mục tiêu Use Case","Exception Flow","Không cần thể hiện trong Use Case"]'::jsonb, 1, 6),
    (v_assignment_id, 'Khi tích hợp Business Rule vào đặc tả UI, điều quan trọng nhất là gì?', '["Business Rule không cần thể hiện trên UI","UI phải validate/enforce đúng theo Business Rule đã định nghĩa, đảm bảo nhất quán giữa các tầng đặc tả","Chỉ cần ghi Business Rule trong tài liệu riêng, không liên quan UI","UI luôn override Business Rule"]'::jsonb, 1, 7),
    (v_assignment_id, 'Nếu Business Rule buổi 7 (giới hạn 20 triệu/ngày cho TK mới) và Business Rule mới buổi 11 (nâng hạn mức tối đa 200 triệu/ngày) có khả năng xung đột, BA nên làm gì?', '["Bỏ qua, để Dev tự xử lý xung đột","Rà soát và làm rõ mối quan hệ giữa 2 Rule, cập nhật tài liệu Business Rule tổng hợp để tránh mâu thuẫn","Xoá 1 trong 2 Rule ngẫu nhiên","Không cần quan tâm vì đây là 2 tính năng khác nhau"]'::jsonb, 1, 8),
    (v_assignment_id, 'Đặc tả UI cho bước "Xác thực qua video call" cần làm rõ điều gì cho Dev?', '["Chỉ cần màu sắc nút \"Bắt đầu video call\"","Trạng thái các bước, xử lý khi mất kết nối/timeout, dữ liệu cần lưu lại sau xác thực","Không cần đặc tả gì, đây là việc của bên thứ 3 cung cấp SDK video call","Chỉ cần ghi \"tích hợp video call\""]'::jsonb, 1, 9),
    (v_assignment_id, 'Mục tiêu chính của buổi 11 trong mini-case là gì?', '["Chỉ học lý thuyết Use Case","Hoàn thiện bộ Use Case + Business Rule + đặc tả UI cho tính năng mở rộng, đảm bảo nhất quán với tài liệu đã có từ buổi 5-9","Không liên quan đến project đã làm trước đó","Chỉ để chuẩn bị thi"]'::jsonb, 1, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — Use Case thiếu actor phụ', 'Nhóm viết Use Case "Nâng hạn mức" chỉ có Actor "Khách hàng" và hệ thống, quên không đưa "Nhân viên ngân hàng xác thực video call" vào như actor phụ, dẫn đến Dev không rõ cần xây dựng module nào cho nhân viên thao tác.
Yêu cầu: (1) Chỉ ra hậu quả của việc thiếu actor phụ này với đội Dev. (2) Viết lại Main Flow có đầy đủ tương tác của actor phụ "Nhân viên ngân hàng".', 1, 14),
    (v_module_id, 'Case Study 2 — Business Rule và UI không khớp', 'Business Rule quy định hạn mức tối đa 200 triệu/ngày, nhưng UI wireframe cho phép khách hàng nhập hạn mức mong muốn không giới hạn, chỉ có dòng chữ nhỏ ghi chú "vui lòng nhập trong hạn mức cho phép".
Yêu cầu: (1) Phân tích rủi ro khi UI không enforce Business Rule bằng validation thực sự. (2) Viết lại đặc tả UI với validation rule rõ ràng, có thông báo lỗi khi vượt ngưỡng.', 2, 14);

  insert into assignments (module_id, phase_id, title, type, description, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'PROJECT (Buổi 11) — Mini-case phần 2: Use Case + Business Rule + UI cho "Nâng hạn mức"', 'project', 'Viết Use Case đầy đủ (Actor, Pre/Postcondition, Main/Alternative/Exception Flow) cho tính năng "Nâng hạn mức giao dịch qua video call xác thực"; hoàn thiện Business Rule liên quan (ngưỡng hạn mức tối đa, điều kiện xác thực); đặc tả màn hình "Yêu cầu nâng hạn mức" kèm validation. Tổng hợp cùng bộ tài liệu buổi 5-10 để chuẩn bị trình bày buổi 12.', 10, 14);

  -- ===== Buổi 12 =====
  insert into modules (phase_id, order_index, title, description, objectives, is_visible)
  values (v_phase_id, 12, 'Buổi 12: Chữa bài và feedback theo nhóm', '- Mỗi nhóm trình bày mini-case đã hoàn thiện.
- Giảng viên và các nhóm khác góp ý.

Thực hành:
- Trình bày 10-15 phút/nhóm + Q&A.
- Ghi nhận góp ý cá nhân/nhóm.', '- Giúp học viên nắm được:
- Nhận được feedback cụ thể để cải thiện kỹ năng trước khi bước vào Chặng 2.
- Tổng kết lại toàn bộ kiến thức Chặng 1.', true)
  returning id into v_module_id;

  insert into assignments (module_id, phase_id, title, type, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'Quiz Buổi 12', 'quiz', 10, 7)
  returning id into v_assignment_id;

  insert into quiz_questions (assignment_id, question_text, options, correct_index, order_index) values
    (v_assignment_id, 'Trình tự đúng của vòng đời dự án phần mềm đã học ở buổi 1 là gì?', '["Phân tích → Khởi tạo → Khảo sát → Thiết kế","Khởi tạo → Khảo sát → Phân tích → Thiết kế → Phát triển → Kiểm thử → Triển khai","Triển khai → Khảo sát → Phân tích","Không có trình tự cố định"]'::jsonb, 1, 1),
    (v_assignment_id, 'Khi trình bày 1 bộ deliverable BA hoàn chỉnh, thứ tự trình bày logic nhất nên bắt đầu từ đâu?', '["UAT trước, sau đó mới đến yêu cầu","Bối cảnh/nhu cầu nghiệp vụ → User Story/Use Case → Business Rule → UI/Data → kế hoạch UAT","Ngẫu nhiên, không cần thứ tự","Chỉ cần trình bày UI vì trực quan nhất"]'::jsonb, 1, 2),
    (v_assignment_id, 'Khi nhận feedback từ giảng viên/nhóm khác, thái độ đúng của 1 BA là gì?', '["Bảo vệ quan điểm bằng mọi giá, không tiếp thu","Lắng nghe, đặt câu hỏi làm rõ nếu chưa hiểu góp ý, ghi nhận điểm cần cải thiện một cách cầu thị","Phớt lờ vì đã hoàn thành bài tập","Chỉ tiếp thu góp ý từ giảng viên, bỏ qua góp ý từ nhóm khác"]'::jsonb, 1, 3),
    (v_assignment_id, 'Một bộ RACI Matrix tốt cho hoạt động trình bày dự án nhóm nên đảm bảo điều gì?', '["Không cần RACI cho hoạt động này","Chỉ có 1 người \"Accountable\" rõ ràng, phân rõ ai \"Responsible\" cho phần nào","Tất cả thành viên đều là Accountable","Không ai cần chịu trách nhiệm cụ thể"]'::jsonb, 1, 4),
    (v_assignment_id, 'Điểm khác biệt cốt lõi giữa Verify và Validate liên quan chất lượng deliverable là gì?', '["Không có khác biệt","Verify kiểm tra chất lượng đặc tả (đúng chuẩn, rõ ràng, đầy đủ); Validate kiểm tra deliverable có thực sự đáp ứng đúng nhu cầu nghiệp vụ","Cả hai đều do Dev thực hiện","Verify chỉ áp dụng cho UI"]'::jsonb, 1, 5),
    (v_assignment_id, 'Khi tổng hợp bộ hồ sơ project "Mở tài khoản online" từ buổi 5-11, tài liệu nào là căn cứ chính để xây dựng kịch bản UAT?', '["Chỉ riêng đặc tả UI","User Story/Use Case và Acceptance Criteria đã chốt xuyên suốt các buổi","Chỉ riêng Business Rule","Không cần căn cứ vào tài liệu nào"]'::jsonb, 1, 6),
    (v_assignment_id, 'Nếu nhóm khác chỉ ra 1 Business Rule của nhóm bạn mâu thuẫn với 1 User Story khác, BA nên phản ứng thế nào?', '["Phủ nhận ngay lập tức","Ghi nhận, đối chiếu lại giữa 2 tài liệu, xác nhận đâu là phiên bản đúng và cập nhật tài liệu để đảm bảo nhất quán (traceability)","Bỏ qua vì không quan trọng","Xoá bỏ 1 trong 2 tài liệu ngay tại chỗ mà không phân tích"]'::jsonb, 1, 7),
    (v_assignment_id, 'Kỹ năng "đặt câu hỏi đúng" học từ buổi 1 và 3 quan trọng thế nào khi nhận Q&A sau khi trình bày?', '["Không liên quan","Giúp BA hiểu đúng bản chất câu hỏi/góp ý từ người nghe trước khi trả lời, tránh trả lời sai trọng tâm","Chỉ áp dụng khi đi khảo sát khách hàng","Không cần áp dụng trong buổi trình bày"]'::jsonb, 1, 8),
    (v_assignment_id, 'Mục tiêu học tập cốt lõi của Mini-case xuyên suốt buổi 5-12 là gì?', '["Chỉ để có điểm danh đầy đủ","Giúp học viên vận dụng liên kết toàn bộ kỹ thuật BA đã học vào 1 tính năng thực tế nhất quán từ đầu đến cuối, mô phỏng công việc thật","Không có mục tiêu cụ thể","Chỉ để luyện kỹ năng thuyết trình"]'::jsonb, 1, 9),
    (v_assignment_id, 'Sau buổi 12, học viên nên mang theo điều gì quan trọng nhất sang Chặng 2?', '["Không cần mang gì, kiến thức Chặng 1 không liên quan Chặng 2","Tư duy liên kết các kỹ thuật BA thành 1 quy trình nhất quán, cùng feedback cụ thể đã nhận để khắc phục điểm yếu","Chỉ cần nhớ định nghĩa các thuật ngữ","Chỉ cần file trình bày PowerPoint"]'::jsonb, 1, 10);

  insert into case_studies (module_id, title, description, order_index, due_offset_days) values
    (v_module_id, 'Case Study 1 — Thiếu traceability khi trình bày', 'Khi trình bày, nhóm A không giải thích được vì sao Use Case "Nâng hạn mức" (buổi 11) lại cần đến Business Rule về hạn mức (buổi 7) — 2 phần được làm tách rời, không liên kết rõ trong bài trình bày.
Yêu cầu: (1) Phân tích vì sao thiếu traceability (liên kết ngược) giữa các deliverable là một lỗi nghiêm trọng trong nghề BA. (2) Đề xuất cách nhóm A nên trình bày lại để thể hiện rõ mối liên kết giữa Business Rule và Use Case.', 1, 14),
    (v_module_id, 'Case Study 2 — Phản hồi tiêu cực với feedback', 'Khi giảng viên chỉ ra Acceptance Criteria của nhóm B thiếu trường hợp ngoại lệ, đại diện nhóm phản bác: "Tụi em nghĩ vậy là đủ rồi, thời gian có hạn nên không viết hết được."
Yêu cầu: (1) Nhận xét về cách phản hồi của nhóm B dưới góc độ thái độ nghề nghiệp của 1 BA. (2) Đề xuất cách phản hồi phù hợp hơn khi nhận góp ý về thiếu sót trong sản phẩm.', 2, 14);

  insert into assignments (module_id, phase_id, title, type, description, max_score, due_offset_days)
  values (v_module_id, v_phase_id, 'PROJECT (Buổi 12) — Trình bày tổng kết project "Mở tài khoản thanh toán online (eKYC)"', 'project', 'Mỗi nhóm trình bày TOÀN BỘ bộ hồ sơ BA hoàn chỉnh xây dựng xuyên suốt buổi 5-11: User Story + AC → Use Case → Business Rule + State Diagram → Đặc tả UI + Data Dictionary → UAT Plan → phần mở rộng "Nâng hạn mức giao dịch". Trình bày 10-15 phút/nhóm, nhấn mạnh tính liên kết (traceability) giữa các phần, nhận Q&A và feedback từ giảng viên + nhóm khác.', 10, 14);

end $$;