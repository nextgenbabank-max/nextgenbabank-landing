// POST /api/document-view-sessions/:sessionId/heartbeat
// Frontend gọi mỗi 15-30s khi tab đang active/visible, gửi số giây active kể từ heartbeat trước.
// Server cộng dồn active_duration_seconds và tự quyết định tính view hợp lệ (>=10s, chống trùng 30 phút)
// bên trong 1 hàm Postgres duy nhất (atomic).
import { json, callRpc, isValidUuid } from '../../_lib/library-helpers.js';

export async function onRequestPost(context) {
  var env = context.env;
  var sessionId = context.params.sessionId;
  if (!isValidUuid(sessionId)) {
    return json(400, { ok: false, error: 'sessionId không hợp lệ.' });
  }

  var body = {};
  try { body = await context.request.json(); } catch (e) { body = {}; }
  var activeDelta = Number(body.active_delta_seconds);
  if (!Number.isFinite(activeDelta) || activeDelta < 0) activeDelta = 0;
  activeDelta = Math.min(activeDelta, 60); // chặn 1 heartbeat cộng dồn quá lớn (client bất thường/giả mạo)

  var rpcRes = await callRpc(env, 'library_heartbeat_view_session', {
    p_session_id: sessionId,
    p_active_delta_seconds: Math.round(activeDelta)
  });

  if (!rpcRes.ok) {
    return json(500, { ok: false, error: 'Không thể cập nhật heartbeat.' });
  }

  var row = Array.isArray(rpcRes.body) ? rpcRes.body[0] : rpcRes.body;
  return json(200, {
    ok: true,
    active_duration_seconds: row && row.active_duration_seconds,
    is_valid_view: row && row.is_valid_view,
    just_counted: row && row.just_counted
  });
}