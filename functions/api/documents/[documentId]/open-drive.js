// POST /api/documents/:documentId/open-drive
// Kiểm tra quyền, ghi log, tăng drive_open_count (atomic), trả về URL Google Drive để frontend
// tự mở bằng window.open(url, "_blank", "noopener,noreferrer") — KHÔNG điều hướng tab hiện tại.
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
  if (!doc.is_drive_open_enabled) {
    return json(403, { ok: false, error: 'Tài liệu này không cho phép mở trên Google Drive.' });
  }

  var userId = await getRequestUserId(context.request, env);
  if (doc.requires_login && !userId) {
    return json(401, { ok: false, error: 'Bạn cần đăng nhập để mở tài liệu này.' });
  }

  var body = {};
  try { body = await context.request.json(); } catch (e) { body = {}; }
  var anonymousId = userId ? null : (String(body.anonymous_id || '').slice(0, 128) || null);
  var viewSessionId = isValidUuid(body.view_session_id) ? body.view_session_id : null;
  var sourcePage = String(body.source_page || '').slice(0, 200) || null;

  var meta = await collectClientMeta(context.request, env);

  var rpcRes = await callRpc(env, 'library_log_drive_open', {
    p_document_id: documentId,
    p_user_id: userId,
    p_anonymous_id: anonymousId,
    p_view_session_id: viewSessionId,
    p_source_page: sourcePage,
    p_device_type: meta.device_type,
    p_browser: meta.browser,
    p_operating_system: meta.operating_system,
    p_ip_hash: meta.ip_hash,
    p_user_agent_hash: meta.user_agent_hash
  });

  if (!rpcRes.ok) {
    return json(500, { ok: false, error: 'Không thể mở tài liệu trên Google Drive.' });
  }

  return json(200, { ok: true, url: rpcRes.body });
}