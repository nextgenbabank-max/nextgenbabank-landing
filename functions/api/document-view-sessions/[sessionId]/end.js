// POST /api/document-view-sessions/:sessionId/end
// Gọi khi người dùng rời trang chi tiết tài liệu (beforeunload/pagehide) — chốt heartbeat cuối + ended_at.
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
  activeDelta = Math.min(activeDelta, 60);

  var rpcRes = await callRpc(env, 'library_end_view_session', {
    p_session_id: sessionId,
    p_active_delta_seconds: Math.round(activeDelta)
  });

  if (!rpcRes.ok) {
    return json(500, { ok: false, error: 'Không thể kết thúc phiên xem.' });
  }
  return json(200, { ok: true });
}