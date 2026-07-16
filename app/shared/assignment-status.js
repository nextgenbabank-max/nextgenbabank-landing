var ASSIGNMENT_DUE_SOON_DAYS = 3;

var ASSIGNMENT_STATUS_LABEL = {
  not_started: 'Chưa bắt đầu',
  draft: 'Đang làm',
  due_soon: 'Chưa nộp',
  overdue: 'Quá hạn',
  pending_review: 'Chờ chấm',
  resubmitted: 'Đã nộp lại',
  needs_revision: 'Yêu cầu chỉnh sửa',
  graded: 'Đã chấm'
};

var ASSIGNMENT_STATUS_BADGE = {
  not_started: 'b-notstarted',
  draft: 'b-draft',
  due_soon: 'b-duesoon',
  overdue: 'b-danger',
  pending_review: 'b-review',
  resubmitted: 'b-resubmit',
  needs_revision: 'b-danger',
  graded: 'b-done'
};

function computeSubmissionState(assignment, submission, hasRevisionRequested, now) {
  now = now || new Date();
  var due = assignment && assignment._effectiveDueDate ? new Date(assignment._effectiveDueDate) : null;

  if (submission) {
    if (submission.status === 'graded') return 'graded';
    if (submission.status === 'needs_revision') return 'needs_revision';
    if (submission.status === 'submitted') return hasRevisionRequested ? 'resubmitted' : 'pending_review';
    if (submission.status === 'draft') return (due && now > due) ? 'overdue' : 'draft';
  }
  if (due && now > due) return 'overdue';
  if (due) {
    var diffDays = (due - now) / (1000 * 60 * 60 * 24);
    if (diffDays >= 0 && diffDays <= ASSIGNMENT_DUE_SOON_DAYS) return 'due_soon';
  }
  return 'not_started';
}

function assignmentStatusLabel(key) { return ASSIGNMENT_STATUS_LABEL[key] || key; }
function assignmentStatusBadgeClass(key) { return ASSIGNMENT_STATUS_BADGE[key] || 'b-new'; }

function assignmentDetailLink(assignment) {
  if (!assignment) return '#';
  if (assignment.type === 'quiz') return 'quiz.html?a=' + assignment.id;
  return 'assignment-detail.html?a=' + assignment.id;
}

var CASE_STUDY_STATUS_LABEL = { not_started: 'Chưa bắt đầu', in_progress: 'Đang thực hiện', completed: 'Đã hoàn thành' };
var CASE_STUDY_STATUS_BADGE = { not_started: 'b-notstarted', in_progress: 'b-review', completed: 'b-done' };

function computeCaseStudyState(donePct) {
  if (donePct >= 100) return 'completed';
  if (donePct > 0) return 'in_progress';
  return 'not_started';
}
function caseStudyStatusLabel(key) { return CASE_STUDY_STATUS_LABEL[key] || key; }
function caseStudyStatusBadgeClass(key) { return CASE_STUDY_STATUS_BADGE[key] || 'b-new'; }
