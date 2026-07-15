window.SUPABASE_URL = 'https://jdkzevfxitprddvaohyi.supabase.co';
window.SUPABASE_KEY = 'sb_publishable_a2p2pbLD3AWJOTZWFswVuQ_trIfygVs';
window.sb = supabase.createClient(window.SUPABASE_URL, window.SUPABASE_KEY);

async function requireAuth() {
  var result = await window.sb.auth.getSession();
  var session = result.data.session;
  if (!session) {
    window.location.href = '/app/login.html';
    return null;
  }
  var profileRes = await window.sb.from('profiles').select('approval_status').eq('id', session.user.id).single();
  var status = profileRes.data && profileRes.data.approval_status;
  if (status && status !== 'approved') {
    await window.sb.auth.signOut();
    window.location.href = '/app/login.html?err=' + status;
    return null;
  }
  return session;
}

async function signOut() {
  await window.sb.auth.signOut();
  window.location.href = '/app/login.html';
}
