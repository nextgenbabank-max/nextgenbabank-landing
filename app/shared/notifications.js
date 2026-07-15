function fetchNotificationEvents(userId) {
  return Promise.all([
    window.sb.from('submissions').select('assignment_id,score,max_score,graded,graded_at').eq('user_id', userId).eq('graded', true),
    window.sb.from('assignments').select('id,title,mentor_id'),
    window.sb.from('mentors').select('id,full_name,avatar_initials,avatar_color'),
    window.sb.from('user_achievements').select('achievement_id,earned_at').eq('user_id', userId),
    window.sb.from('achievements').select('id,title,description')
  ]).then(function (r) {
    var submissions = r[0].data || [];
    var assignments = r[1].data || [];
    var mentors = r[2].data || [];
    var userAchievements = r[3].data || [];
    var achievements = r[4].data || [];

    var assignmentById = {};
    assignments.forEach(function (a) { assignmentById[a.id] = a; });
    var mentorById = {};
    mentors.forEach(function (m) { mentorById[m.id] = m; });
    var achievementById = {};
    achievements.forEach(function (a) { achievementById[a.id] = a; });

    var events = [];
    submissions.forEach(function (s) {
      if (!s.graded_at) return;
      var a = assignmentById[s.assignment_id];
      var mentor = a && mentorById[a.mentor_id];
      events.push({
        type: 'grade',
        time: new Date(s.graded_at),
        title: (mentor ? mentor.full_name : 'Giảng viên') + ' đã chấm bài tập "' + (a ? a.title : '') + '"',
        detail: 'Điểm: ' + s.score + '/' + s.max_score
      });
    });
    userAchievements.forEach(function (ua) {
      if (!ua.earned_at) return;
      var ach = achievementById[ua.achievement_id];
      events.push({
        type: 'achievement',
        time: new Date(ua.earned_at),
        title: 'Bạn vừa đạt huy hiệu "' + (ach ? ach.title : '') + '"',
        detail: ach ? ach.description : ''
      });
    });

    events.sort(function (a, b) { return b.time - a.time; });
    return events;
  });
}

function fetchLastReadAt(userId) {
  return window.sb.from('notification_reads').select('last_read_at').eq('user_id', userId).maybeSingle().then(function (res) {
    return res.data ? new Date(res.data.last_read_at) : new Date('2000-01-01');
  });
}

function markNotificationsRead(userId) {
  return window.sb.from('notification_reads').upsert({ user_id: userId, last_read_at: new Date().toISOString() }, { onConflict: 'user_id' });
}

function updateNotificationBadges(count) {
  var displayCount = count > 9 ? '9+' : String(count);
  ['notif-count-main', 'notif-count-mobile', 'notif-badge-sidebar'].forEach(function (id) {
    var el = document.getElementById(id);
    if (!el) return;
    if (count > 0) {
      el.textContent = displayCount;
      el.style.display = '';
    } else {
      el.style.display = 'none';
    }
  });
  var dot = document.getElementById('notif-dot');
  if (dot) dot.style.display = count > 0 ? '' : 'none';
}

function loadNotificationBadge(userId) {
  Promise.all([fetchNotificationEvents(userId), fetchLastReadAt(userId)]).then(function (r) {
    var events = r[0], lastReadAt = r[1];
    var unread = events.filter(function (e) { return e.time > lastReadAt; }).length;
    updateNotificationBadges(unread);
  });
}
