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

  var fullName = (body.full_name || '').trim();
  var email = (body.email || '').trim().toLowerCase();
  var phone = (body.phone || '').trim();
  var role = body.role === 'mentor' ? 'mentor' : 'student';
  var orgTitle = (body.org_title || '').trim();
  var password = (body.temp_password || '').trim();

  if (!fullName || !email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return json(400, { ok: false, error: 'Họ tên hoặc email không hợp lệ.' });
  }
  if (!password || password.length < 8) {
    return json(400, { ok: false, error: 'Mật khẩu tạm phải có ít nhất 8 ký tự.' });
  }

  var createRes = await fetch(SUPABASE_URL + '/auth/v1/admin/users', {
    method: 'POST',
    headers: {
      Authorization: 'Bearer ' + SERVICE_ROLE_KEY,
      apikey: SERVICE_ROLE_KEY,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      email: email,
      password: password,
      email_confirm: true,
      user_metadata: { full_name: fullName, phone: phone, role: role }
    })
  });
  var createBody = await createRes.json();
  if (!createRes.ok) {
    var msg = (createBody && createBody.msg) || (createBody && createBody.message) || '';
    if (/already.*registered|already exists/i.test(msg)) {
      return json(409, { ok: false, error: 'Email này đã có tài khoản.' });
    }
    return json(500, { ok: false, error: 'Tạo tài khoản thất bại, vui lòng thử lại.' });
  }
  var newUserId = createBody && createBody.id;
  if (!newUserId) {
    return json(500, { ok: false, error: 'Tạo tài khoản thất bại, vui lòng thử lại.' });
  }

  async function rollback() {
    await fetch(SUPABASE_URL + '/auth/v1/admin/users/' + newUserId, {
      method: 'DELETE',
      headers: { Authorization: 'Bearer ' + SERVICE_ROLE_KEY, apikey: SERVICE_ROLE_KEY }
    }).catch(function () {});
  }

  var patchRes = await fetch(SUPABASE_URL + '/rest/v1/profiles?id=eq.' + newUserId, {
    method: 'PATCH',
    headers: {
      Authorization: 'Bearer ' + SERVICE_ROLE_KEY,
      apikey: SERVICE_ROLE_KEY,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal'
    },
    body: JSON.stringify({
      approval_status: 'approved',
      approved_at: new Date().toISOString(),
      approved_by: callerId,
      is_mentor: role === 'mentor'
    })
  });
  if (!patchRes.ok) {
    await rollback();
    return json(500, { ok: false, error: 'Tạo tài khoản thất bại, vui lòng thử lại.' });
  }

  if (role === 'mentor') {
    var mentorRes = await fetch(SUPABASE_URL + '/rest/v1/mentors', {
      method: 'POST',
      headers: {
        Authorization: 'Bearer ' + SERVICE_ROLE_KEY,
        apikey: SERVICE_ROLE_KEY,
        'Content-Type': 'application/json',
        Prefer: 'return=minimal'
      },
      body: JSON.stringify({ full_name: fullName, role_title: orgTitle, user_id: newUserId })
    });
    if (!mentorRes.ok) {
      await rollback();
      return json(500, { ok: false, error: 'Tạo tài khoản thất bại, vui lòng thử lại.' });
    }
  }

  return json(200, { ok: true, user_id: newUserId, temp_password: password });
}

