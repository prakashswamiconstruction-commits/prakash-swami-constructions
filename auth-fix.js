(() => {
  const SUPABASE_URL = 'https://aamstyeeewncmgqdxpoh.supabase.co';
  const SUPABASE_KEY = 'sb_publishable_fOzZvfiio6HSaEgplYUgOA_lWy1tbVe';
  const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
  const PHONE = v => {
    const d = String(v || '').replace(/\D/g, '');
    if (!d) return '';
    if (d.startsWith('91') && d.length === 12) return '+' + d;
    if (d.length === 10) return '+91' + d;
    return String(v).trim();
  };
  const show = (msg) => { if (typeof window.err === 'function') window.err(msg); else alert(msg); };
  const open = (html) => { if (typeof window.openModal === 'function') window.openModal(html); };
  const close = () => { if (typeof window.closeModal === 'function') window.closeModal(); };

  const form = document.getElementById('loginForm');
  if (form) form.onsubmit = async (e) => {
    e.preventDefault();
    const active = document.querySelector('.tabs button.active');
    const selectedRole = active?.dataset.role || 'admin';
    const id = document.getElementById('loginId').value.trim();
    const pass = document.getElementById('password').value;
    document.getElementById('err')?.classList.add('hidden');
    try {
      let result;
      if (selectedRole === 'worker') {
        const phone = PHONE(id);
        result = await sb.auth.signInWithOtp({ phone });
        if (result.error) return show(result.error.message);
        open(`<div class="modal-head"><h3>OTP Verification</h3><button class="close" onclick="closeModal()">✕</button></div><div class="field"><label>OTP</label><input id="otp" inputmode="numeric" autocomplete="one-time-code"></div><button class="primary full" onclick="window.verifyWorkerOtp('${phone}')">Verify & Login</button>`);
        return;
      }
      if (selectedRole === 'customer') {
        result = await sb.auth.signInWithPassword({ email: id, password: pass });
      } else {
        const phone = PHONE(id);
        result = await sb.auth.signInWithPassword({ phone, password: pass });
        if (result.error) {
          // Fallback keeps Admin phone+password UX working even if phone auth provider is disabled.
          result = await sb.auth.signInWithPassword({ email: `${phone.replace('+91','')}@prakashswamiconstructions.local`, password: pass });
        }
      }
      if (result.error) return show(result.error.message);
      if (typeof window.enter === 'function') await window.enter(result.data.user);
    } catch (x) { show(x?.message || 'Login failed'); }
  };

  window.verifyWorkerOtp = async (phone) => {
    const token = document.getElementById('otp')?.value.trim();
    const r = await sb.auth.verifyOtp({ phone, token, type: 'sms' });
    if (r.error) return show(r.error.message);
    close();
    if (typeof window.enter === 'function') await window.enter(r.data.user);
  };

  const signupButton = document.getElementById('signupBtn');
  if (signupButton) signupButton.onclick = () => open(`<div class="modal-head"><h3>Customer Registration</h3><button class="close" onclick="closeModal()">✕</button></div><div class="form-grid"><div class="field"><label>Name</label><input id="fix_sn" autocomplete="name"></div><div class="field"><label>Phone</label><input id="fix_sp" inputmode="tel"></div><div class="field"><label>Email</label><input id="fix_se" type="email" autocomplete="email"></div><div class="field"><label>Password</label><input id="fix_sw" type="password" autocomplete="new-password"></div><div class="field"><label>Address</label><input id="fix_sa"></div></div><button class="primary full" onclick="window.fixSignup()">Create Account</button>`);
  window.fixSignup = async () => {
    const name = document.getElementById('fix_sn').value.trim();
    const phone = PHONE(document.getElementById('fix_sp').value);
    const email = document.getElementById('fix_se').value.trim();
    const password = document.getElementById('fix_sw').value;
    const address = document.getElementById('fix_sa').value.trim();
    if (!name || !email || password.length < 8) return show('Name, valid email और कम से कम 8 character का password जरूरी है।');
    const r = await sb.auth.signUp({ email, password, options: { data: { name, phone, address } } });
    if (r.error) return show(r.error.message);
    close();
    if (r.data.session && r.data.user) {
      if (typeof window.enter === 'function') await window.enter(r.data.user);
    } else {
      alert('Account बन गया है। Email confirmation link से account verify करें, फिर Customer Login से प्रवेश करें।');
    }
  };
})();
