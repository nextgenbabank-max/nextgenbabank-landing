function queryDocumentsForClass(classId) {
  var query = window.sb.from('documents').select('id,title,url,phase_id,doc_type,module_id,class_id,created_at').order('created_at', { ascending: false });
  if (classId) query = query.or('class_id.eq.' + classId + ',class_id.is.null');
  return query;
}

function toggleDocumentFavorite(userId, documentId, isFav) {
  return isFav
    ? window.sb.from('document_favorites').delete().eq('user_id', userId).eq('document_id', documentId)
    : window.sb.from('document_favorites').insert({ user_id: userId, document_id: documentId });
}
