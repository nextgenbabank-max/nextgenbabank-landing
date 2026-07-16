export async function onRequestPost(context) {
  var env = context.env;
  var SUPABASE_URL = env.SUPABASE_URL;
  var SERVICE_ROLE_KEY = env.SUPABASE_SERVICE_ROLE_KEY;
  var ANON_KEY = env.SUPABASE_ANON_KEY;

  function json(status, body) {
    return new Response(JSON.stringify(body), { status: status, headers: { 'Content-Type': 'application/json' } });
  }

  var authHeader = context.request.headers.get('Authorization') || '';
  var callerToken = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!callerToken) {
    return json(401, { ok: false, error: 'Thiếu thông tin xác thực.' });
  }

  var callerRes = await fetch(SUPABASE_URL + '/auth/v1/user', {
    headers: { Authorization: 'Bearer ' + callerToken, apikey: ANON_KEY }
  });
  if (!callerRes.ok) {
    return json(401, { ok: false, error: 'Phiên đăng nhập không hợp lệ.' });
  }
  var callerUser = await callerRes.json();
  var callerId = callerUser && callerUser.id;
  if (!callerId) {
    return json(401, { ok: false, error: 'Phiên đăng nhập không hợp lệ.' });
  }

  var callerProfileRes = await fetch(
    SUPABASE_URL + '/rest/v1/profiles?id=eq.' + callerId + '&select=is_admin',
    { headers: { Authorization: 'Bearer ' + SERVICE_ROLE_KEY, apikey: SERVICE_ROLE_KEY } }
  );
  var callerProfileRows = await callerProfileRes.json();
  var callerProfile = Array.isArray(callerProfileRows) ? callerProfileRows[0] : null;
  if (!callerProfile || !callerProfile.is_admin) {
    return json(403, { ok: false, error: 'Bạn không có quyền thực hiện thao tác này.' });
  }

  var body;
  try {
    body = await context.request.json();
  } catch (e) {
    return json(400, { ok: false, error: 'Dữ liệu gửi lên không hợp lệ.' });
  }

  var targetUserId = (body.user_id || '').trim();
  var newPassword = (body.new_password || '').trim();
  if (!targetUserId) {
    return json(400, { ok: false, error: 'Thiếu thông tin người dùng.' });
  }
  if (!newPassword || newPassword.length < 8) {
    return json(400, { ok: false, error: 'Mật khẩu mới phải có ít nhất 8 ký tự.' });
  }

  var updateRes = await fetch(SUPABASE_URL + '/auth/v1/admin/users/' + targetUserId, {
    method: 'PUT',
    headers: {
      Authorization: 'Bearer ' + SERVICE_ROLE_KEY,
      apikey: SERVICE_ROLE_KEY,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ password: newPassword })
  });
  if (!updateRes.ok) {
    var errBody = await updateRes.json().catch(function () { return {}; });
    return json(500, { ok: false, error: (errBody && (errBody.msg || errBody.message)) || 'Đặt lại mật khẩu thất bại, vui lòng thử lại.' });
  }

  return json(200, { ok: true });
}
