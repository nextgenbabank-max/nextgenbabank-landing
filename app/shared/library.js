// Helper dùng chung cho tính năng "Thư viện tài liệu tham khảo" (tai-lieu.html, tai-lieu-danh-muc.html,
// tai-lieu-chi-tiet.html, admin-library.html). Load sau app.js, trước script riêng của từng trang.

var LIBRARY_ANON_ID_KEY = 'nextgenLibraryAnonId';
var LIBRARY_RECENT_VIEW_KEY_PREFIX = 'nextgenLibraryRecentView:';

function libraryGetAnonymousId() {
  try {
    var id = localStorage.getItem(LIBRARY_ANON_ID_KEY);
    if (!id) {
      id = 'anon-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 12);
      localStorage.setItem(LIBRARY_ANON_ID_KEY, id);
    }
    return id;
  } catch (e) {
    return 'anon-session-only-' + Math.random().toString(36).slice(2, 12);
  }
}

// Chấp nhận các dạng URL phổ biến của Google Drive/Docs:
// https://drive.google.com/file/d/FILE_ID/view?usp=sharing
// https://drive.google.com/open?id=FILE_ID
// https://drive.google.com/uc?id=FILE_ID&export=download
// https://docs.google.com/document/d/FILE_ID/edit
function libraryExtractDriveFileId(rawUrl) {
  if (!rawUrl) return null;
  var url;
  try { url = new URL(String(rawUrl).trim()); } catch (e) { return null; }

  var host = url.hostname.replace(/^www\./, '');
  if (host !== 'drive.google.com' && host !== 'docs.google.com') return null;

  var pathMatch = url.pathname.match(/\/d\/([a-zA-Z0-9_-]{10,})/);
  if (pathMatch) return pathMatch[1];

  var idParam = url.searchParams.get('id');
  if (idParam && /^[a-zA-Z0-9_-]{10,}$/.test(idParam)) return idParam;

  return null;
}

function libraryIsAllowedDriveUrl(rawUrl) {
  return !!libraryExtractDriveFileId(rawUrl);
}

function libraryGetPreviewUrl(fileId) {
  return 'https://drive.google.com/file/d/' + fileId + '/preview';
}

function libraryGetViewUrl(fileId) {
  return 'https://drive.google.com/file/d/' + fileId + '/view';
}

function libraryNormalizeDriveUrl(rawUrl) {
  var fileId = libraryExtractDriveFileId(rawUrl);
  if (!fileId) return null;
  return { fileId: fileId, driveUrl: libraryGetViewUrl(fileId), previewUrl: libraryGetPreviewUrl(fileId) };
}

function libraryFormatFileSize(bytes) {
  if (bytes == null || isNaN(bytes)) return '—';
  var n = Number(bytes);
  if (n < 1024) return n + ' B';
  if (n < 1024 * 1024) return (n / 1024).toFixed(1) + ' KB';
  if (n < 1024 * 1024 * 1024) return (n / (1024 * 1024)).toFixed(1) + ' MB';
  return (n / (1024 * 1024 * 1024)).toFixed(1) + ' GB';
}

function libraryFormatCount(n) {
  n = Number(n) || 0;
  if (n >= 1000000) return (n / 1000000).toFixed(1).replace(/\.0$/, '') + 'tr';
  if (n >= 1000) return (n / 1000).toFixed(1).replace(/\.0$/, '') + 'k';
  return String(n);
}

function libraryTimeAgo(dateStr) {
  if (!dateStr) return '—';
  var diffMs = Date.now() - new Date(dateStr).getTime();
  var mins = Math.floor(diffMs / 60000);
  if (mins < 1) return 'Vừa xong';
  if (mins < 60) return mins + ' phút trước';
  var hours = Math.floor(mins / 60);
  if (hours < 24) return hours + ' giờ trước';
  var days = Math.floor(hours / 24);
  if (days < 30) return days + ' ngày trước';
  var months = Math.floor(days / 30);
  if (months < 12) return months + ' tháng trước';
  return Math.floor(months / 12) + ' năm trước';
}

function libraryDifficultyLabel(level) {
  return level === 'beginner' ? 'Cơ bản' : level === 'advanced' ? 'Nâng cao' : level === 'intermediate' ? 'Trung cấp' : '—';
}

function libraryFileTypeLabel(type) {
  var map = { pdf: 'PDF', docx: 'Word', doc: 'Word', xlsx: 'Excel', xls: 'Excel', pptx: 'PowerPoint', ppt: 'PowerPoint' };
  return map[(type || '').toLowerCase()] || (type || '').toUpperCase();
}

// ============================================================
// View tracking client — quản lý 1 phiên xem cho trang chi tiết tài liệu.
// Luồng: startViewSession() -> onIframeLoaded() -> heartbeat định kỳ (chỉ khi tab visible) -> endViewSession()
// ============================================================
function createLibraryViewTracker(documentId) {
  var sessionId = null;
  var heartbeatTimer = null;
  var lastTickAt = null;
  var ended = false;

  function authHeaders() {
    return window.sb.auth.getSession().then(function (res) {
      var token = res.data.session && res.data.session.access_token;
      var headers = { 'Content-Type': 'application/json' };
      if (token) headers.Authorization = 'Bearer ' + token;
      return headers;
    });
  }

  function post(path, body) {
    return authHeaders().then(function (headers) {
      return fetch(path, { method: 'POST', headers: headers, body: JSON.stringify(body || {}) });
    }).then(function (res) {
      return res.json().then(function (data) { return { ok: res.ok, status: res.status, data: data }; });
    });
  }

  function start() {
    return post('/api/documents/' + documentId + '/view-sessions', { anonymous_id: libraryGetAnonymousId() })
      .then(function (result) {
        if (result.ok && result.data && result.data.session_id) {
          sessionId = result.data.session_id;
          lastTickAt = Date.now();
          heartbeatTimer = setInterval(tick, 20000);
        }
        return result;
      });
  }

  function onIframeLoaded() {
    if (!sessionId) return;
    post('/api/document-view-sessions/' + sessionId + '/loaded', {});
  }

  function tick() {
    if (!sessionId || ended) return;
    if (document.hidden) { lastTickAt = Date.now(); return; } // không tính thời gian khi tab bị ẩn
    var now = Date.now();
    var deltaSeconds = Math.round((now - lastTickAt) / 1000);
    lastTickAt = now;
    if (deltaSeconds <= 0) return;
    post('/api/document-view-sessions/' + sessionId + '/heartbeat', { active_delta_seconds: deltaSeconds });
  }

  function end() {
    if (!sessionId || ended) return;
    ended = true;
    if (heartbeatTimer) clearInterval(heartbeatTimer);
    var deltaSeconds = document.hidden ? 0 : Math.max(Math.round((Date.now() - lastTickAt) / 1000), 0);
    var payload = JSON.stringify({ active_delta_seconds: deltaSeconds });
    if (navigator.sendBeacon) {
      try {
        navigator.sendBeacon('/api/document-view-sessions/' + sessionId + '/end', new Blob([payload], { type: 'application/json' }));
        return;
      } catch (e) { /* fall through */ }
    }
    post('/api/document-view-sessions/' + sessionId + '/end', { active_delta_seconds: deltaSeconds });
  }

  function getSessionId() { return sessionId; }

  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) lastTickAt = Date.now();
  });
  window.addEventListener('pagehide', end);
  window.addEventListener('beforeunload', end);

  return { start: start, onIframeLoaded: onIframeLoaded, end: end, getSessionId: getSessionId };
}