// POST /api/documents/:documentId/view-sessions
// Tạo một phiên xem tài liệu mới (bước đầu của luồng đếm view hợp lệ).
import { json, getRequestUserId, collectClientMeta, callRpc, getDocumentGuard, isValidUuid } from '../../_lib/library-helpers.js';

export async function onRequestPost(context) {
  var env = context.env;
  var documentId = context.params.documentId;

  if (!isValidUuid(documentId)) {
    return json(400, { ok: false, error: 'documentId không hợp lệ.' });
  }

  var doc = await getDocumentGuard(env, documentId);
  if (!doc || doc.status !== 'PUBLISHED') {
    return json(404, { ok: false, error: 'Không tìm thấy tài liệu.' });
  }
  if (!doc.is_viewable) {
    return json(403, { ok: false, error: 'Tài liệu này hiện không cho phép xem trực tuyến.' });
  }

  var userId = await getRequestUserId(context.request, env);
  if (doc.requires_login && !userId) {
    return json(401, { ok: false, error: 'Bạn cần đăng nhập để xem tài liệu này.' });
  }

  var body = {};
  try { body = await context.request.json(); } catch (e) { body = {}; }
  var anonymousId = userId ? null : (String(body.anonymous_id || '').slice(0, 128) || null);
  if (!userId && !anonymousId) {
    return json(400, { ok: false, error: 'Thiếu anonymous_id cho khách chưa đăng nhập.' });
  }

  var meta = await collectClientMeta(context.request, env);
  var referrer = context.request.headers.get('Referer') || null;

  var rpcRes = await callRpc(env, 'library_start_view_session', {
    p_document_id: documentId,
    p_user_id: userId,
    p_anonymous_id: anonymousId,
    p_device_type: meta.device_type,
    p_browser: meta.browser,
    p_operating_system: meta.operating_system,
    p_ip_hash: meta.ip_hash,
    p_user_agent_hash: meta.user_agent_hash,
    p_referrer: referrer
  });

  if (!rpcRes.ok) {
    return json(500, { ok: false, error: 'Không thể tạo phiên xem.' });
  }

  return json(200, { ok: true, session_id: rpcRes.body });
}