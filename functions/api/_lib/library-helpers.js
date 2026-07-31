// Helper dùng chung cho các API "Thư viện tài liệu tham khảo" (functions/api/documents/*, functions/api/document-view-sessions/*).
// Thư mục _lib bắt đầu bằng "_" nên Cloudflare Pages Functions KHÔNG coi đây là route.

export function json(status, body) {
  return new Response(JSON.stringify(body), { status: status, headers: { 'Content-Type': 'application/json' } });
}

export async function getRequestUserId(request, env) {
  var authHeader = request.headers.get('Authorization') || '';
  var token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) return null;
  var res = await fetch(env.SUPABASE_URL + '/auth/v1/user', {
    headers: { Authorization: 'Bearer ' + token, apikey: env.SUPABASE_ANON_KEY }
  });
  if (!res.ok) return null;
  var user = await res.json();
  return (user && user.id) || null;
}

export async function hashValue(value) {
  if (!value) return null;
  var data = new TextEncoder().encode(String(value));
  var digest = await crypto.subtle.digest('SHA-256', data);
  var bytes = Array.from(new Uint8Array(digest));
  return bytes.map(function (b) { return b.toString(16).padStart(2, '0'); }).join('');
}

export function parseUserAgent(ua) {
  ua = ua || '';
  var deviceType = /Mobi|Android(?!.*Tablet)|iPhone/i.test(ua) ? 'mobile' : (/Tablet|iPad/i.test(ua) ? 'tablet' : 'desktop');
  var browser = 'other';
  if (/Edg\//i.test(ua)) browser = 'edge';
  else if (/Chrome\//i.test(ua) && !/Chromium/i.test(ua)) browser = 'chrome';
  else if (/Firefox\//i.test(ua)) browser = 'firefox';
  else if (/Safari\//i.test(ua) && !/Chrome/i.test(ua)) browser = 'safari';
  var os = 'other';
  if (/Windows/i.test(ua)) os = 'windows';
  else if (/Mac OS X/i.test(ua)) os = 'macos';
  else if (/Android/i.test(ua)) os = 'android';
  else if (/iPhone|iPad|iOS/i.test(ua)) os = 'ios';
  else if (/Linux/i.test(ua)) os = 'linux';
  return { device_type: deviceType, browser: browser, operating_system: os };
}

export async function collectClientMeta(request, env) {
  var ua = request.headers.get('User-Agent') || '';
  var ip = request.headers.get('CF-Connecting-IP') || '';
  var parsed = parseUserAgent(ua);
  var ipHash = await hashValue(ip ? ip + ':' + (env.IP_HASH_SALT || 'nextgen-ba') : null);
  var uaHash = await hashValue(ua ? ua + ':' + (env.IP_HASH_SALT || 'nextgen-ba') : null);
  return {
    device_type: parsed.device_type,
    browser: parsed.browser,
    operating_system: parsed.operating_system,
    ip_hash: ipHash,
    user_agent_hash: uaHash
  };
}

export async function callRpc(env, fnName, params) {
  var res = await fetch(env.SUPABASE_URL + '/rest/v1/rpc/' + fnName, {
    method: 'POST',
    headers: {
      Authorization: 'Bearer ' + env.SUPABASE_SERVICE_ROLE_KEY,
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      'Content-Type': 'application/json',
      Prefer: 'params=single-object'
    },
    body: JSON.stringify(params || {})
  });
  var body = null;
  try { body = await res.json(); } catch (e) { body = null; }
  return { ok: res.ok, status: res.status, body: body };
}

export async function getDocumentGuard(env, documentId) {
  var res = await fetch(
    env.SUPABASE_URL + '/rest/v1/library_documents?id=eq.' + encodeURIComponent(documentId) +
      '&select=id,status,requires_login,is_viewable,is_drive_open_enabled,is_download_link_enabled',
    { headers: { Authorization: 'Bearer ' + env.SUPABASE_SERVICE_ROLE_KEY, apikey: env.SUPABASE_SERVICE_ROLE_KEY } }
  );
  if (!res.ok) return null;
  var rows = await res.json();
  return Array.isArray(rows) && rows[0] ? rows[0] : null;
}

export function isValidUuid(value) {
  return typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}