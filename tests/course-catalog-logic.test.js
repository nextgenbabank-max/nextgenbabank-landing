// Test thuần Node.js (không phụ thuộc framework nào) cho các hàm nghiệp vụ thuần của
// tính năng "Xem khóa học": định dạng giá VNĐ, validate email/phone trong popup Nhận đề cương.
//
// Chạy: node tests/course-catalog-logic.test.js
//
// Các hàm được nạp qua vm từ shared/course-widgets.js (thuần JS, không phụ thuộc DOM/window
// cho phần được test — phần đăng ký sự kiện DOM tự bỏ qua vì sandbox không có `document`).

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

var source = fs.readFileSync(path.join(__dirname, '..', 'shared', 'course-widgets.js'), 'utf8');
var sandbox = { console: console };
vm.createContext(sandbox);
vm.runInContext(source, sandbox);

console.log('1) formatVnd');

test('định dạng số nguyên với dấu chấm phân cách hàng nghìn + hậu tố VNĐ', function () {
  assert.strictEqual(sandbox.formatVnd(4599000), '4.599.000 VNĐ');
});

test('định dạng giá theo chặng nhỏ hơn', function () {
  assert.strictEqual(sandbox.formatVnd(1299000), '1.299.000 VNĐ');
});

test('giá trị không hợp lệ trả về chuỗi rỗng', function () {
  assert.strictEqual(sandbox.formatVnd(NaN), '');
  assert.strictEqual(sandbox.formatVnd(undefined), '');
});

console.log('2) validateSyllabusEmail');

test('rỗng -> báo lỗi "Vui lòng nhập email..."', function () {
  var r = sandbox.validateSyllabusEmail('');
  assert.strictEqual(r.valid, false);
  assert.strictEqual(r.message, 'Vui lòng nhập email nhận đề cương.');
});

test('chỉ có khoảng trắng -> coi như rỗng', function () {
  var r = sandbox.validateSyllabusEmail('   ');
  assert.strictEqual(r.valid, false);
});

test('sai định dạng (thiếu @) -> báo lỗi định dạng', function () {
  var r = sandbox.validateSyllabusEmail('nguyenvana.gmail.com');
  assert.strictEqual(r.valid, false);
  assert.strictEqual(r.message, 'Email chưa đúng định dạng. Vui lòng kiểm tra lại.');
});

test('sai định dạng (thiếu domain) -> báo lỗi định dạng', function () {
  var r = sandbox.validateSyllabusEmail('a@b');
  assert.strictEqual(r.valid, false);
});

test('email hợp lệ -> valid true, không có message', function () {
  var r = sandbox.validateSyllabusEmail('nguyenvana@gmail.com');
  assert.strictEqual(r.valid, true);
  assert.strictEqual(r.message, '');
});

console.log('3) validateSyllabusPhone');

test('rỗng -> hợp lệ vì là trường tuỳ chọn', function () {
  var r = sandbox.validateSyllabusPhone('');
  assert.strictEqual(r.valid, true);
});

test('chỉ số -> hợp lệ', function () {
  var r = sandbox.validateSyllabusPhone('0912345678');
  assert.strictEqual(r.valid, true);
});

test('số có dấu + và khoảng trắng -> hợp lệ', function () {
  var r = sandbox.validateSyllabusPhone('+84 912 345 678');
  assert.strictEqual(r.valid, true);
});

test('có chữ cái -> không hợp lệ', function () {
  var r = sandbox.validateSyllabusPhone('0912abc678');
  assert.strictEqual(r.valid, false);
  assert.strictEqual(r.message, 'Số điện thoại/Zalo chỉ được chứa số, dấu + và khoảng trắng.');
});

console.log('\n' + passed + ' passed, ' + failures + ' failed');
if (failures > 0) process.exit(1);
