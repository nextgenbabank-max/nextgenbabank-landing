// POST /api/document-view-sessions/:sessionId/loaded
// Đánh dấu iframe Google Drive Preview đã load thành công cho phiên xem này.
import { json, callRpc, isValidUuid } from '../../_lib/library-helpers.js';

export async function onRequestPost(context) {
  var env = context.env;
  var sessionId = context.params.sessionId;
  if (!isValidUuid(sessionId)) {
    return json(400, { ok: false, error: 'sessionId không hợp lệ.' });
  }
  var rpcRes = await callRpc(env, 'library_mark_view_loaded', { p_session_id: sessionId });
  if (!rpcRes.ok) {
    return json(500, { ok: false, error: 'Không thể cập nhật phiên xem.' });
  }
  return json(200, { ok: true });
}