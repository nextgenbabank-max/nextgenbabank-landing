function fetchNotificationEvents(userId) {
  var events = [];
  var now = new Date();
  var recentSince = new Date(now.getTime() - 14 * 86400000);

  return Promise.all([
    window.sb.from('submissions').select('id,assignment_id,score,max_score,status,graded_at').eq('user_id', userId),
    window.sb.from('assignments').select('id,title,mentor_id,due_date,due_offset_days,module_id,class_id,created_at'),
    window.sb.from('mentors').select('id,full_name,avatar_initials,avatar_color'),
    window.sb.from('user_achievements').select('achievement_id,earned_at').eq('user_id', userId),
    window.sb.from('achievements').select('id,title,description'),
    window.sb.from('class_members').select('class_id').eq('student_id', userId),
    window.sb.from('modules').select('id,order_index')
  ]).then(function (r) {
    var submissions = r[0].data || [];
    var assignments = (r[1].data || []);
    var mentors = r[2].data || [];
    var userAchievements = r[3].data || [];
    var achievements = r[4].data || [];
    var myClassIds = (r[5].data || []).map(function (cm) { return cm.class_id; });
    var modulesById = {};
    (r[6].data || []).forEach(function (m) { modulesById[m.id] = m; });

    assignments = assignments.filter(function (a) { return !a.class_id || myClassIds.indexOf(a.class_id) !== -1; });

    var assignmentById = {};
    assignments.forEach(function (a) { assignmentById[a.id] = a; });
    var mentorById = {};
    mentors.forEach(function (m) { mentorById[m.id] = m; });
    var achievementById = {};
    achievements.forEach(function (a) { achievementById[a.id] = a; });
    var subByAssignment = {};
    submissions.forEach(function (s) { subByAssignment[s.assignment_id] = s; });

    submissions.forEach(function (s) {
      if (s.status !== 'graded' || !s.graded_at) return;
      var a = assignmentById[s.assignment_id];
      var mentor = a && mentorById[a.mentor_id];
      events.push({
        type: 'grade',
        time: new Date(s.graded_at),
        title: (mentor ? mentor.full_name : 'Mentor') + ' đã chấm bài tập "' + (a ? a.title : '') + '"',
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

    assignments.forEach(function (a) {
      if (a.created_at && new Date(a.created_at) >= recentSince) {
        events.push({
          type: 'new_assignment',
          time: new Date(a.created_at),
          title: 'Bài tập mới: "' + a.title + '"',
          detail: 'Bài tập vừa được giao cho bạn.'
        });
      }
    });

    var subIds = submissions.map(function (s) { return s.id; });
    var classSessionsQuery = myClassIds.length
      ? window.sb.from('class_sessions').select('id,title,scheduled_at,created_at,updated_at,module_id,session_type,class_id').in('class_id', myClassIds)
      : Promise.resolve({ data: [] });
    var documentsQuery = window.sb.from('documents').select('id,title,created_at,class_id');
    var versionsQuery = subIds.length
      ? window.sb.from('submission_versions').select('submission_id,action,created_at').in('submission_id', subIds)
      : Promise.resolve({ data: [] });
    var messagesQuery = window.sb.from('messages').select('id,created_at,sender_id,body,file_name').eq('student_id', userId).neq('sender_id', userId);
    var announcementsQuery = myClassIds.length
      ? window.sb.from('class_announcements').select('message,created_at').in('class_id', myClassIds)
      : Promise.resolve({ data: [] });

    return Promise.all([classSessionsQuery, documentsQuery, versionsQuery, messagesQuery, announcementsQuery]).then(function (r2) {
      var sessions = r2[0].data || [];
      var documents = (r2[1].data || []).filter(function (d) { return !d.class_id || myClassIds.indexOf(d.class_id) !== -1; });
      var versions = r2[2].data || [];
      var messages = r2[3].data || [];
      var announcements = r2[4].data || [];

      annotateEffectiveDueDates(assignments, sessions, modulesById);

      assignments.forEach(function (a) {
        if (!a._effectiveDueDate) return;
        var sub = subByAssignment[a.id];
        var hasSubmitted = sub && (sub.status === 'submitted' || sub.status === 'graded');
        if (hasSubmitted) return;
        var diffDays = (a._effectiveDueDate - now) / 86400000;
        if (diffDays >= 0 && diffDays <= 3) {
          events.push({
            type: 'due_soon',
            time: now,
            title: 'Bài tập sắp đến hạn: "' + a.title + '"',
            detail: 'Hạn nộp: ' + a._effectiveDueDate.toLocaleDateString('vi-VN')
          });
        } else if (diffDays < 0) {
          events.push({
            type: 'overdue',
            time: a._effectiveDueDate,
            title: 'Bài tập đã quá hạn: "' + a.title + '"',
            detail: 'Hạn nộp: ' + a._effectiveDueDate.toLocaleDateString('vi-VN')
          });
        }
      });

      versions.forEach(function (v) {
        if (v.action !== 'revision_requested') return;
        var sub = submissions.find(function (s) { return s.id === v.submission_id; });
        var a = sub && assignmentById[sub.assignment_id];
        events.push({
          type: 'needs_revision',
          time: new Date(v.created_at),
          title: 'Mentor yêu cầu chỉnh sửa bài "' + (a ? a.title : '') + '"',
          detail: 'Vui lòng xem chi tiết và nộp lại bài.'
        });
      });

      documents.forEach(function (d) {
        if (d.created_at && new Date(d.created_at) >= recentSince) {
          events.push({
            type: 'new_document',
            time: new Date(d.created_at),
            title: 'Tài liệu mới: "' + d.title + '"',
            detail: 'Tài liệu vừa được thêm vào lớp học của bạn.'
          });
        }
      });

      sessions.forEach(function (s) {
        var createdAt = s.created_at ? new Date(s.created_at) : null;
        if (createdAt && createdAt >= recentSince) {
          if (s.session_type === 'one-on-one') {
            events.push({ type: 'new_1on1', time: createdAt, title: 'Lịch hẹn Meet 1:1 mới', detail: s.title });
          } else {
            events.push({ type: 'new_session', time: createdAt, title: 'Lịch học mới: "' + s.title + '"', detail: new Date(s.scheduled_at).toLocaleDateString('vi-VN') });
          }
        } else if (s.updated_at && s.created_at && (new Date(s.updated_at) - new Date(s.created_at)) > 60000) {
          events.push({
            type: 'session_updated',
            time: new Date(s.updated_at),
            title: 'Buổi học đã được cập nhật: "' + s.title + '"',
            detail: 'Giờ học hoặc link Meet có thay đổi, vui lòng kiểm tra lại.'
          });
        }
      });

      messages.forEach(function (m) {
        events.push({
          type: 'new_message',
          time: new Date(m.created_at),
          title: 'Tin nhắn mới từ Mentor',
          detail: m.body || ('Đã gửi file: ' + (m.file_name || ''))
        });
      });

      announcements.forEach(function (ann) {
        events.push({
          type: 'class_announcement',
          time: new Date(ann.created_at),
          title: 'Thông báo từ lớp học',
          detail: ann.message
        });
      });

      events.sort(function (a, b) { return b.time - a.time; });
      return events;
    });
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

var NOTIFICATION_ICON_MAP = {
  grade: 'check',
  achievement: 'award',
  class_announcement: 'bell',
  new_assignment: 'file',
  due_soon: 'clock',
  overdue: 'alert',
  needs_revision: 'alert',
  new_document: 'file',
  new_session: 'calendar',
  session_updated: 'calendar',
  new_1on1: 'calendar',
  new_message: 'chat'
};

function getNotificationIconKey(type) {
  return NOTIFICATION_ICON_MAP[type] || 'bell';
}
