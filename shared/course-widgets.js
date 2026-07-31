// Shared widget cho chức năng "Xem khóa học": popup "Chọn kênh tư vấn" (Messenger/Zalo)
// và popup "Nhận đề cương khóa học". Dùng chung cho index.html (khu vực danh sách khóa học)
// và 5 trang courses/*.html, để không lặp lại modal HTML/CSS/JS ở từng trang.
//
// Trang nhúng cần có trước khi load file này:
//   <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
//   <script>window.SUPABASE_URL = '...'; window.SUPABASE_KEY = '...';</script>
//
// Kích hoạt bằng data-attribute, không cần JS riêng mỗi trang:
//   <button data-open-consultation data-course-id="..." data-course-name="...">Đăng ký tư vấn</button>
//   <button data-open-syllabus data-course-id="..." data-course-name="...">Nhận đề cương</button>

function formatVnd(amount) {
  var n = Number(amount);
  if (!isFinite(n)) return '';
  return n.toLocaleString('vi-VN', { maximumFractionDigits: 0 }) + ' VNĐ';
}

function validateSyllabusEmail(value) {
  var v = (value || '').trim();
  if (!v) return { valid: false, message: 'Vui lòng nhập email nhận đề cương.' };
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v)) {
    return { valid: false, message: 'Email chưa đúng định dạng. Vui lòng kiểm tra lại.' };
  }
  return { valid: true, message: '' };
}

function validateSyllabusPhone(value) {
  var v = (value || '').trim();
  if (!v) return { valid: true, message: '' };
  if (!/^[0-9+ ]+$/.test(v)) {
    return { valid: false, message: 'Số điện thoại/Zalo chỉ được chứa số, dấu + và khoảng trắng.' };
  }
  return { valid: true, message: '' };
}

(function (global) {
  if (typeof document === 'undefined') return; // đang chạy trong test sandbox (không có DOM)

  var MODAL_HTML =
    '<div class="cw-overlay" id="cw-consultation-overlay" aria-hidden="true">' +
    '  <div class="cw-modal" role="dialog" aria-modal="true" aria-labelledby="cw-consultation-title">' +
    '    <button type="button" class="cw-close" data-cw-close aria-label="Đóng">&times;</button>' +
    '    <h3 id="cw-consultation-title">Chọn kênh tư vấn</h3>' +
    '    <p class="cw-sub">Trao đổi với NextGen BA Banker qua kênh thuận tiện nhất với bạn.</p>' +
    '    <div class="cw-channel-grid">' +
    '      <div class="cw-channel-card">' +
    '        <div class="cw-channel-icon cw-icon-messenger">M</div>' +
    '        <div class="cw-channel-name">Messenger</div>' +
    '        <p>Chat trực tiếp với fanpage trên Messenger.</p>' +
    '        <button type="button" class="cw-btn cw-btn-gold" data-cw-channel="messenger">Chat qua Messenger</button>' +
    '      </div>' +
    '      <div class="cw-channel-card">' +
    '        <div class="cw-channel-icon cw-icon-zalo">Z</div>' +
    '        <div class="cw-channel-name">Zalo</div>' +
    '        <p>Nhắn tin nhanh với đội ngũ tư vấn qua Zalo.</p>' +
    '        <button type="button" class="cw-btn cw-btn-gold" data-cw-channel="zalo">Chat qua Zalo</button>' +
    '      </div>' +
    '    </div>' +
    '    <p class="cw-note">Chúng tôi sẽ hỗ trợ lựa chọn khóa học phù hợp với nền tảng và mục tiêu của bạn.</p>' +
    '  </div>' +
    '</div>' +
    '<div class="cw-overlay" id="cw-syllabus-overlay" aria-hidden="true">' +
    '  <div class="cw-modal" role="dialog" aria-modal="true" aria-labelledby="cw-syllabus-title">' +
    '    <button type="button" class="cw-close" data-cw-close aria-label="Đóng">&times;</button>' +
    '    <div data-cw-syllabus-step="form">' +
    '      <h3 id="cw-syllabus-title">Nhận đề cương khóa học</h3>' +
    '      <p class="cw-sub">Nhập email để nhận nội dung chi tiết, lộ trình học và thông tin đầu ra của khóa học.</p>' +
    '      <form id="cw-syllabus-form" novalidate>' +
    '        <label class="cw-field">Khóa học quan tâm' +
    '          <input type="text" id="cw-f-course" readonly />' +
    '        </label>' +
    '        <label class="cw-field">Họ và tên' +
    '          <input type="text" id="cw-f-name" maxlength="100" placeholder="Nhập họ và tên của bạn" />' +
    '        </label>' +
    '        <label class="cw-field">Email nhận đề cương <span class="cw-req">*</span>' +
    '          <input type="email" id="cw-f-email" placeholder="Nhập email của bạn" required />' +
    '        </label>' +
    '        <div class="cw-error" id="cw-f-email-error" hidden></div>' +
    '        <label class="cw-field">Số điện thoại / Zalo' +
    '          <input type="tel" id="cw-f-phone" placeholder="Nhập số điện thoại hoặc Zalo" />' +
    '        </label>' +
    '        <div class="cw-error" id="cw-f-phone-error" hidden></div>' +
    '        <label class="cw-checkbox">' +
    '          <input type="checkbox" id="cw-f-consent" required />' +
    '          <span>Tôi đồng ý nhận đề cương và thông tin liên quan đến khóa học từ NextGen BA Banker.</span>' +
    '        </label>' +
    '        <div class="cw-error" id="cw-f-consent-error" hidden></div>' +
    '        <button type="submit" class="cw-btn cw-btn-gold cw-btn-block" id="cw-syllabus-submit">Gửi đề cương về email</button>' +
    '        <button type="button" class="cw-btn cw-btn-outline cw-btn-block" data-cw-close>Đóng</button>' +
    '      </form>' +
    '    </div>' +
    '    <div data-cw-syllabus-step="success" hidden>' +
    '      <h3>Đã ghi nhận yêu cầu!</h3>' +
    '      <p class="cw-sub" id="cw-success-text"></p>' +
    '      <p class="cw-note">Đội ngũ NextGen BA Banker sẽ trực tiếp gửi đề cương tới email của bạn trong thời gian sớm nhất. Vui lòng kiểm tra cả thư mục Spam hoặc Quảng cáo.</p>' +
    '      <button type="button" class="cw-btn cw-btn-outline cw-btn-block" data-cw-close>Đóng</button>' +
    '      <button type="button" class="cw-btn cw-btn-gold cw-btn-block" data-cw-chat-consultant>Chat với tư vấn viên</button>' +
    '    </div>' +
    '    <div data-cw-syllabus-step="failure" hidden>' +
    '      <h3>Chưa thể gửi yêu cầu</h3>' +
    '      <p class="cw-sub">Vui lòng kiểm tra kết nối mạng hoặc thử lại sau.</p>' +
    '      <button type="button" class="cw-btn cw-btn-gold cw-btn-block" data-cw-retry>Thử lại</button>' +
    '      <button type="button" class="cw-btn cw-btn-outline cw-btn-block" data-cw-close>Đóng</button>' +
    '      <button type="button" class="cw-btn cw-btn-outline cw-btn-block" data-cw-chat-consultant>Chat với tư vấn viên</button>' +
    '    </div>' +
    '  </div>' +
    '</div>';

  var MODAL_CSS =
    '.cw-overlay{display:none;position:fixed;inset:0;background:rgba(14,44,69,.55);z-index:9999;align-items:flex-start;justify-content:center;padding:5vh 1rem;overflow-y:auto;}' +
    '.cw-overlay.cw-show{display:flex;}' +
    '.cw-modal{background:#FFFFFF;border-radius:16px;max-width:480px;width:100%;padding:1.8rem 1.7rem;position:relative;box-shadow:0 30px 60px -24px rgba(14,44,69,.4);font-family:-apple-system,"Segoe UI","Helvetica Neue",Arial,sans-serif;color:#1C2B30;}' +
    '.cw-modal h3{margin:0 0 .4rem;font-size:1.35rem;color:#0E2C45;}' +
    '.cw-sub{margin:0 0 1rem;color:#46565A;font-size:.95rem;line-height:1.5;}' +
    '.cw-note{font-size:.82rem;color:#46565A;margin-top:.8rem;}' +
    '.cw-close{position:absolute;top:.9rem;right:1rem;border:none;background:none;font-size:1.5rem;line-height:1;cursor:pointer;color:#46565A;padding:.2rem .5rem;border-radius:8px;}' +
    '.cw-close:focus-visible,.cw-btn:focus-visible,.cw-field input:focus-visible{outline:2px solid #E0701C;outline-offset:2px;}' +
    '.cw-channel-grid{display:grid;grid-template-columns:1fr 1fr;gap:.9rem;margin:1rem 0;}' +
    '@media (max-width:520px){.cw-channel-grid{grid-template-columns:1fr;}}' +
    '.cw-channel-card{border:1.5px solid #DBE1E3;border-radius:14px;padding:1.1rem .9rem;text-align:center;}' +
    '.cw-channel-icon{width:44px;height:44px;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto .5rem;font-weight:700;color:#fff;}' +
    '.cw-icon-messenger{background:#0084FF;}' +
    '.cw-icon-zalo{background:#0068FF;}' +
    '.cw-channel-name{font-weight:700;margin-bottom:.3rem;color:#0E2C45;}' +
    '.cw-channel-card p{font-size:.85rem;color:#46565A;margin:0 0 .8rem;}' +
    '.cw-btn{display:inline-block;border-radius:9px;padding:.65rem 1rem;font-size:.92rem;font-weight:600;cursor:pointer;border:1.5px solid transparent;text-align:center;}' +
    '.cw-btn-gold{background:linear-gradient(120deg,#EA8A3C,#C45E12);color:#fff;}' +
    '.cw-btn-gold:disabled{opacity:.6;cursor:not-allowed;}' +
    '.cw-btn-outline{background:#fff;border-color:#DBE1E3;color:#16395A;}' +
    '.cw-btn-block{display:block;width:100%;margin-top:.6rem;}' +
    '.cw-field{display:block;font-size:.85rem;color:#16395A;font-weight:600;margin-bottom:.8rem;}' +
    '.cw-field input{display:block;width:100%;margin-top:.35rem;padding:.6rem .7rem;border:1.5px solid #DBE1E3;border-radius:9px;font-size:.95rem;font-family:inherit;box-sizing:border-box;}' +
    '.cw-field input[readonly]{background:#F3F5F6;color:#46565A;}' +
    '.cw-checkbox{display:flex;gap:.5rem;align-items:flex-start;font-size:.85rem;color:#46565A;margin-bottom:.4rem;}' +
    '.cw-checkbox input{margin-top:.2rem;}' +
    '.cw-error{color:#C0392B;font-size:.8rem;margin:-.5rem 0 .8rem;}';

  function injectOnce() {
    if (document.getElementById('cw-consultation-overlay')) return;
    var style = document.createElement('style');
    style.textContent = MODAL_CSS;
    document.head.appendChild(style);
    var wrap = document.createElement('div');
    wrap.innerHTML = MODAL_HTML;
    while (wrap.firstChild) document.body.appendChild(wrap.firstChild);
  }

  function sb() {
    if (!global.sbCourseClient && global.supabase && global.SUPABASE_URL && global.SUPABASE_KEY) {
      global.sbCourseClient = global.supabase.createClient(global.SUPABASE_URL, global.SUPABASE_KEY);
    }
    return global.sbCourseClient;
  }

  function restInsert(table, body) {
    return fetch(global.SUPABASE_URL + '/rest/v1/' + table, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: global.SUPABASE_KEY,
        Authorization: 'Bearer ' + global.SUPABASE_KEY,
        Prefer: 'return=minimal'
      },
      body: JSON.stringify(body)
    });
  }

  function detectDeviceType() {
    var w = global.innerWidth || 1024;
    if (w < 640) return 'mobile';
    if (w < 1024) return 'tablet';
    return 'desktop';
  }

  var currentCourse = null;

  function openOverlay(id) {
    injectOnce();
    document.getElementById(id).classList.add('cw-show');
    document.body.style.overflow = 'hidden';
  }

  function closeAllOverlays() {
    var overlays = document.querySelectorAll('.cw-overlay');
    for (var i = 0; i < overlays.length; i++) overlays[i].classList.remove('cw-show');
    document.body.style.overflow = '';
  }

  function openConsultation(course) {
    currentCourse = course || currentCourse;
    openOverlay('cw-consultation-overlay');
  }

  function openSyllabus(course) {
    currentCourse = course || currentCourse;
    injectOnce();
    var form = document.getElementById('cw-syllabus-form');
    form.reset();
    document.getElementById('cw-f-course').value = currentCourse ? currentCourse.course_name : '';
    setSyllabusStep('form');
    hideFieldError('cw-f-email-error');
    hideFieldError('cw-f-phone-error');
    hideFieldError('cw-f-consent-error');
    openOverlay('cw-syllabus-overlay');
  }

  function setSyllabusStep(step) {
    var steps = document.querySelectorAll('[data-cw-syllabus-step]');
    for (var i = 0; i < steps.length; i++) {
      steps[i].hidden = steps[i].getAttribute('data-cw-syllabus-step') !== step;
    }
  }

  function showFieldError(elId, message) {
    var el = document.getElementById(elId);
    el.textContent = message;
    el.hidden = false;
  }

  function hideFieldError(elId) {
    var el = document.getElementById(elId);
    el.hidden = true;
    el.textContent = '';
  }

  function handleChannelClick(channel) {
    if (!currentCourse) return;
    var url = channel === 'messenger' ? currentCourse.messenger_url : currentCourse.zalo_url;
    if (url) global.open(url, '_blank', 'noopener');
    restInsert('consultation_events', {
      course_id: currentCourse.course_id || null,
      selected_channel: channel,
      source_page: global.location.pathname,
      source_url: global.location.href,
      device_type: detectDeviceType()
    }).catch(function () {});
  }

  function handleSyllabusSubmit(e) {
    e.preventDefault();
    var email = document.getElementById('cw-f-email').value;
    var phone = document.getElementById('cw-f-phone').value;
    var name = document.getElementById('cw-f-name').value;
    var consent = document.getElementById('cw-f-consent').checked;

    hideFieldError('cw-f-email-error');
    hideFieldError('cw-f-phone-error');
    hideFieldError('cw-f-consent-error');

    var emailCheck = validateSyllabusEmail(email);
    var phoneCheck = validateSyllabusPhone(phone);
    var hasError = false;

    if (!emailCheck.valid) {
      showFieldError('cw-f-email-error', emailCheck.message);
      hasError = true;
    }
    if (!phoneCheck.valid) {
      showFieldError('cw-f-phone-error', phoneCheck.message);
      hasError = true;
    }
    if (!consent) {
      showFieldError('cw-f-consent-error', 'Vui lòng đồng ý nhận đề cương và thông tin liên quan đến khóa học.');
      hasError = true;
    }
    if (hasError || !currentCourse) return;

    var submitBtn = document.getElementById('cw-syllabus-submit');
    submitBtn.disabled = true;
    submitBtn.textContent = 'Đang gửi...';

    fetch(global.SUPABASE_URL + '/rest/v1/rpc/submit_syllabus_request', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: global.SUPABASE_KEY,
        Authorization: 'Bearer ' + global.SUPABASE_KEY
      },
      body: JSON.stringify({
        p_course_id: currentCourse.course_id,
        p_full_name: name,
        p_email: email,
        p_phone: phone,
        p_consent: consent,
        p_source_page: global.location.pathname,
        p_source_url: global.location.href
      })
    })
      .then(function (res) {
        if (!res.ok) throw new Error('HTTP ' + res.status);
        return res.json();
      })
      .then(function (result) {
        if (!result || result.success !== true) {
          if (result && result.message) showFieldError('cw-f-email-error', result.message);
          throw new Error(result && result.error_code ? result.error_code : 'UNKNOWN_ERROR');
        }
        document.getElementById('cw-success-text').innerHTML =
          'Yêu cầu nhận đề cương khóa học <strong>' + escapeHtml(currentCourse.course_name) + '</strong> đã được ghi nhận, gửi tới email: <strong>' + escapeHtml(email) + '</strong>.';
        setSyllabusStep('success');
      })
      .catch(function () {
        setSyllabusStep('failure');
      })
      .finally(function () {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Gửi đề cương về email';
      });
  }

  function escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  function readCourseFromTrigger(el) {
    return {
      course_id: el.getAttribute('data-course-id'),
      course_name: el.getAttribute('data-course-name'),
      messenger_url: el.getAttribute('data-messenger-url') || global.CW_DEFAULT_MESSENGER_URL,
      zalo_url: el.getAttribute('data-zalo-url') || global.CW_DEFAULT_ZALO_URL
    };
  }

  document.addEventListener('DOMContentLoaded', function () {
    injectOnce();

    document.addEventListener('click', function (e) {
      var consultTrigger = e.target.closest('[data-open-consultation]');
      if (consultTrigger) {
        openConsultation(readCourseFromTrigger(consultTrigger));
        return;
      }
      var syllabusTrigger = e.target.closest('[data-open-syllabus]');
      if (syllabusTrigger) {
        openSyllabus(readCourseFromTrigger(syllabusTrigger));
        return;
      }
      var channelBtn = e.target.closest('[data-cw-channel]');
      if (channelBtn) {
        handleChannelClick(channelBtn.getAttribute('data-cw-channel'));
        return;
      }
      if (e.target.closest('[data-cw-chat-consultant]')) {
        closeAllOverlays();
        openConsultation();
        return;
      }
      if (e.target.closest('[data-cw-retry]')) {
        setSyllabusStep('form');
        return;
      }
      if (e.target.closest('[data-cw-close]') || e.target.classList.contains('cw-overlay')) {
        closeAllOverlays();
      }
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') closeAllOverlays();
    });

    document.addEventListener('submit', function (e) {
      if (e.target && e.target.id === 'cw-syllabus-form') handleSyllabusSubmit(e);
    });
  });

  global.CourseWidgets = { openConsultation: openConsultation, openSyllabus: openSyllabus };
})(typeof window !== 'undefined' ? window : this);
