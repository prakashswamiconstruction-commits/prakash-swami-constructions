(() => {
  const SUPABASE_URL = 'https://aamstyeeewncmgqdxpoh.supabase.co';
  const SUPABASE_KEY = 'sb_publishable_fOzZvfiio6HSaEgplYUgOA_lWy1tbVe';
  const client = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

  function installForgotPassword() {
    const form = document.getElementById('form');
    const id = document.getElementById('id');
    const loginButton = form?.querySelector('button[type="submit"]');
    if (!form || !id || !loginButton || document.getElementById('forgot-password')) return;

    const wrap = document.createElement('div');
    wrap.style.cssText = 'margin-top:10px;text-align:center';
    wrap.innerHTML = '<button id="forgot-password" type="button" style="border:0;background:none;color:#2563eb;cursor:pointer;font-weight:700">Forgot password?</button>';
    loginButton.parentNode.insertAdjacentElement('afterend', wrap);

    document.getElementById('forgot-password').onclick = async () => {
      const email = id.value.trim();
      const errorBox = document.getElementById('error');
      if (!email) {
        errorBox.textContent = 'पहले Admin email दर्ज करें।';
        errorBox.classList.remove('hidden');
        return;
      }
      if (email.toLowerCase() !== 'satpalswami22742@gmail.com') {
        errorBox.textContent = 'Password reset केवल registered Admin email से किया जा सकता है।';
        errorBox.classList.remove('hidden');
        return;
      }
      const { error } = await client.auth.resetPasswordForEmail(email, {
        redirectTo: window.location.href.split('#')[0]
      });
      if (error) {
        errorBox.textContent = 'Password reset email भेजने में समस्या: ' + error.message;
        errorBox.classList.remove('hidden');
        return;
      }
      alert('Password reset link Admin email पर भेज दिया गया है। Email खोलकर नया password सेट करें।');
    };
  }

  async function handleRecovery() {
    if (!window.location.hash.includes('access_token')) return;
    const form = document.getElementById('form');
    const login = document.getElementById('login');
    if (!form || !login) return;
    const card = login.querySelector('.card');
    if (!card || document.getElementById('recovery-form')) return;

    const recovery = document.createElement('div');
    recovery.id = 'recovery-form';
    recovery.style.cssText = 'margin-top:18px;padding-top:18px;border-top:1px solid #ddd';
    recovery.innerHTML = '<h3>नया Admin Password</h3><input id="new-admin-password" type="password" minlength="8" placeholder="नया password (कम से कम 8 अक्षर)" style="width:100%;box-sizing:border-box;padding:12px;border:1px solid #ddd;border-radius:10px;margin:10px 0"><button id="save-admin-password" type="button" class="primary">Password बदलें</button>';
    card.appendChild(recovery);

    document.getElementById('save-admin-password').onclick = async () => {
      const password = document.getElementById('new-admin-password').value;
      if (password.length < 8) {
        alert('Password कम से कम 8 characters का होना चाहिए।');
        return;
      }
      const { error } = await client.auth.updateUser({ password });
      if (error) {
        alert('Password बदलने में समस्या: ' + error.message);
        return;
      }
      alert('Admin password successfully बदल गया। अब नए password से login करें।');
      window.location.hash = '';
      location.reload();
    };
  }

  function start() {
    installForgotPassword();
    handleRecovery();
    const observer = new MutationObserver(installForgotPassword);
    observer.observe(document.body, { childList: true, subtree: true });
    setTimeout(handleRecovery, 300);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();