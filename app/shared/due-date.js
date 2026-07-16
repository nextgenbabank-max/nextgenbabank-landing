function computeEffectiveDueDate(item, classSessions, modulesById) {
  if (item.due_offset_days == null) {
    return item.due_date ? new Date(item.due_date) : null;
  }
  if (!item.module_id) {
    return item.due_date ? new Date(item.due_date) : null;
  }
  var session = classSessions.find(function (s) { return s.module_id === item.module_id; });
  if (!session) {
    var mod = modulesById[item.module_id];
    if (mod) {
      session = classSessions.find(function (s) { return s.order_index != null && s.order_index === mod.order_index; });
    }
  }
  if (session) {
    var base = new Date(session.scheduled_at);
    base.setDate(base.getDate() + item.due_offset_days);
    return base;
  }
  return item.due_date ? new Date(item.due_date) : null;
}

function annotateEffectiveDueDates(items, classSessions, modulesById) {
  items.forEach(function (item) {
    item._effectiveDueDate = computeEffectiveDueDate(item, classSessions || [], modulesById || {});
  });
  return items;
}
