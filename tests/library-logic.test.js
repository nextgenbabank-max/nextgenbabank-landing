// Test thuần Node.js (không phụ thuộc framework nào — repo này không có package.json/npm test runner)
// cho các hàm nghiệp vụ thuần của tính năng "Thư viện tài liệu tham khảo".
//
// Chạy: node tests/library-logic.test.js
//
// Phạm vi:
// 1) Parse/validate Google Drive URL (app/shared/library.js) — chạy trực tiếp bằng cách nạp file qua vm,
//    vì các hàm này thuần JS, không phụ thuộc DOM/window.
// 2) Logic chống trùng lượt xem trong 30 phút — mô phỏng lại đúng quy tắc của hàm Postgres
//    library_heartbeat_view_session() trong _supabase_phase_library.sql, vì bài test này chạy offline
//    (không có Postgres thật), nên đây là kiểm thử logic tương đương, KHÔNG thay thế integration test
//    thật với Supabase.

var fs = require('fs');
var path = require('path');
var vm = require('vm');
var assert = require('assert');

var failures = 0;
var passed = 0;

function test(name, fn) {
  try {
    fn();
    passed++;
    console.log('  ok - ' + name);
  } catch (e) {
    failures++;
    console.log('  FAIL - ' + name);
    console.log('    ' + e.message);
  }
}

// ---------- Nạp app/shared/library.js vào 1 sandbox tối thiểu ----------
var libSource = fs.readFileSync(path.join(__dirname, '..', 'app', 'shared', 'library.js'), 'utf8');
var sandbox = {
  URL: URL,
  localStorage: { getItem: function () { return null; }, setItem: function () {} },
  document: { addEventListener: function () {}, hidden: false },
  window: { addEventListener: function () {} },
  navigator: {},
  console: console,
  Date: Date,
  Math: Math
};
vm.createContext(sandbox);
vm.runInContext(libSource, sandbox);

console.log('1) libraryExtractDriveFileId / libraryNormalizeDriveUrl / libraryIsAllowedDriveUrl');

test('nhận diện dạng /file/d/FILE_ID/view', function () {
  var id = sandbox.libraryExtractDriveFileId('https://drive.google.com/file/d/1AbCdEfGhIjKlMnOp/view?usp=sharing');
  assert.strictEqual(id, '1AbCdEfGhIjKlMnOp');
});

test('nhận diện dạng /open?id=FILE_ID', function () {
  var id = sandbox.libraryExtractDriveFileId('https://drive.google.com/open?id=1AbCdEfGhIjKlMnOp');
  assert.strictEqual(id, '1AbCdEfGhIjKlMnOp');
});

test('nhận diện dạng docs.google.com/document/d/FILE_ID/edit', function () {
  var id = sandbox.libraryExtractDriveFileId('https://docs.google.com/document/d/1AbCdEfGhIjKlMnOp/edit');
  assert.strictEqual(id, '1AbCdEfGhIjKlMnOp');
});

test('từ chối domain lạ (không phải drive/docs.google.com)', function () {
  var id = sandbox.libraryExtractDriveFileId('https://evil-mirror.com/file/d/1AbCdEfGhIjKlMnOp/view');
  assert.strictEqual(id, null);
});

test('từ chối URL không hợp lệ / rỗng', function () {
  assert.strictEqual(sandbox.libraryExtractDriveFileId(''), null);
  assert.strictEqual(sandbox.libraryExtractDriveFileId('không-phải-url'), null);
  assert.strictEqual(sandbox.libraryExtractDriveFileId(null), null);
});

test('libraryIsAllowedDriveUrl phản ánh đúng kết quả extract', function () {
  assert.strictEqual(sandbox.libraryIsAllowedDriveUrl('https://drive.google.com/file/d/1AbCdEfGhIjKlMnOp/view'), true);
  assert.strictEqual(sandbox.libraryIsAllowedDriveUrl('https://example.com/nope'), false);
});

test('libraryNormalizeDriveUrl trả về preview + view URL chuẩn hoá', function () {
  var norm = sandbox.libraryNormalizeDriveUrl('https://drive.google.com/file/d/1AbCdEfGhIjKlMnOp/view?usp=sharing');
  assert.strictEqual(norm.fileId, '1AbCdEfGhIjKlMnOp');
  assert.strictEqual(norm.previewUrl, 'https://drive.google.com/file/d/1AbCdEfGhIjKlMnOp/preview');
  assert.strictEqual(norm.driveUrl, 'https://drive.google.com/file/d/1AbCdEfGhIjKlMnOp/view');
});

test('libraryFormatFileSize quy đổi đơn vị đúng', function () {
  assert.strictEqual(sandbox.libraryFormatFileSize(500), '500 B');
  assert.strictEqual(sandbox.libraryFormatFileSize(1536), '1.5 KB');
  assert.strictEqual(sandbox.libraryFormatFileSize(5 * 1024 * 1024), '5.0 MB');
});

console.log('2) Logic chống trùng lượt xem trong 30 phút (mô phỏng library_heartbeat_view_session)');

// Mô phỏng lại đúng quy tắc trong _supabase_phase_library.sql:
// - Chỉ tính view hợp lệ khi: viewer_loaded_successfully && active_duration_seconds >= 10 && chưa is_valid_view
// - Trước khi tăng view_count, kiểm tra có session khác cùng identity (user_id hoặc anonymous_id) đã
//   is_valid_view=true với view_counted_at trong 30 phút gần nhất hay chưa — nếu có thì KHÔNG tăng view_count.
function simulateHeartbeat(existingSessions, session, nowMs) {
  if (session.is_valid_view || !session.viewer_loaded_successfully || session.active_duration_seconds < 10) {
    return { justCounted: false };
  }
  var THIRTY_MIN = 30 * 60 * 1000;
  var isDup = existingSessions.some(function (s) {
    if (s.id === session.id || !s.is_valid_view) return false;
    if (nowMs - s.view_counted_at > THIRTY_MIN) return false;
    if (session.user_id) return s.user_id === session.user_id;
    return s.anonymous_id && s.anonymous_id === session.anonymous_id;
  });
  session.is_valid_view = true;
  session.view_counted_at = nowMs;
  return { justCounted: !isDup };
}

test('lượt xem đầu tiên (đủ 10s, đã load) được tính', function () {
  var session = { id: 's1', user_id: 'u1', viewer_loaded_successfully: true, active_duration_seconds: 12, is_valid_view: false };
  var result = simulateHeartbeat([], session, Date.now());
  assert.strictEqual(result.justCounted, true);
});

test('chưa đủ 10 giây active thì KHÔNG tính view', function () {
  var session = { id: 's2', user_id: 'u1', viewer_loaded_successfully: true, active_duration_seconds: 4, is_valid_view: false };
  var result = simulateHeartbeat([], session, Date.now());
  assert.strictEqual(result.justCounted, false);
});

test('iframe chưa load xong thì KHÔNG tính view dù đủ thời gian', function () {
  var session = { id: 's3', user_id: 'u1', viewer_loaded_successfully: false, active_duration_seconds: 20, is_valid_view: false };
  var result = simulateHeartbeat([], session, Date.now());
  assert.strictEqual(result.justCounted, false);
});

test('mở lại cùng tài liệu trong vòng 30 phút (cùng user_id) KHÔNG tăng view lần 2', function () {
  var now = Date.now();
  var priorSession = { id: 's4', user_id: 'u1', is_valid_view: true, view_counted_at: now - 10 * 60 * 1000 };
  var newSession = { id: 's5', user_id: 'u1', viewer_loaded_successfully: true, active_duration_seconds: 15, is_valid_view: false };
  var result = simulateHeartbeat([priorSession], newSession, now);
  assert.strictEqual(result.justCounted, false);
});

test('mở lại SAU 30 phút thì được tính view mới', function () {
  var now = Date.now();
  var priorSession = { id: 's6', user_id: 'u1', is_valid_view: true, view_counted_at: now - 31 * 60 * 1000 };
  var newSession = { id: 's7', user_id: 'u1', viewer_loaded_successfully: true, active_duration_seconds: 15, is_valid_view: false };
  var result = simulateHeartbeat([priorSession], newSession, now);
  assert.strictEqual(result.justCounted, true);
});

test('khách ẩn danh: chống trùng theo anonymous_id, không lẫn giữa 2 khách khác nhau', function () {
  var now = Date.now();
  var priorSession = { id: 's8', anonymous_id: 'anon-A', is_valid_view: true, view_counted_at: now - 5 * 60 * 1000 };
  var sameGuestSession = { id: 's9', anonymous_id: 'anon-A', viewer_loaded_successfully: true, active_duration_seconds: 15, is_valid_view: false };
  var otherGuestSession = { id: 's10', anonymous_id: 'anon-B', viewer_loaded_successfully: true, active_duration_seconds: 15, is_valid_view: false };
  assert.strictEqual(simulateHeartbeat([priorSession], sameGuestSession, now).justCounted, false);
  assert.strictEqual(simulateHeartbeat([priorSession], otherGuestSession, now).justCounted, true);
});

console.log('');
console.log(passed + ' passed, ' + failures + ' failed');
if (failures > 0) process.exit(1);