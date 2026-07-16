var SESSION_STATUS_LABEL = {
  cancelled: 'Đã hủy',
  rescheduled: 'Đã đổi lịch',
  ongoing: 'Đang diễn ra',
  upcoming: 'Sắp diễn ra',
  completed: 'Đã hoàn thành',
  not_started: 'Chưa diễn ra'
};

var SESSION_STATUS_BADGE = {
  cancelled: 'b-danger',
  rescheduled: 'b-duesoon',
  ongoing: 'b-review',
  upcoming: 'b-progress',
  completed: 'b-done',
  not_started: 'b-notstarted'
};

var SESSION_DEFAULT_DURATION_MS = 3 * 60 * 60 * 1000;

function sessionEndTime(session) {
  if (session.ends_at) return new Date(session.ends_at);
  return new Date(new Date(session.scheduled_at).getTime() + SESSION_DEFAULT_DURATION_MS);
}

function computeSessionPhase(session, now) {
  now = now || new Date();
  if (session.status === 'cancelled') return 'cancelled';
  if (session.status === 'rescheduled') return 'rescheduled';
  var start = new Date(session.scheduled_at);
  var end = sessionEndTime(session);
  if (now < start) {
    var hoursUntil = (start - now) / (1000 * 60 * 60);
    return hoursUntil <= 24 ? 'upcoming' : 'not_started';
  }
  if (now <= end) return 'ongoing';
  return 'completed';
}

function sessionMeetVisible(session, now) {
  now = now || new Date();
  if (!session.meet_link) return false;
  if (session.is_published === false) return false;
  if (session.status === 'cancelled') return false;
  return now <= sessionEndTime(session);
}

function sessionStatusLabel(key) { return SESSION_STATUS_LABEL[key] || key; }
function sessionStatusBadgeClass(key) { return SESSION_STATUS_BADGE[key] || 'b-new'; }
