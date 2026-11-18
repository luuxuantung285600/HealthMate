/* Runs before styles to apply a saved choice without a light/dark flash. */
(() => {
  if (window.HealthMateAppearance) return;
  const storageKey = 'healthmate.admin.theme';
  const valid = value => ['system', 'light', 'dark'].includes(value);
  const media = window.matchMedia?.('(prefers-color-scheme: dark)');
  let preference = 'system';
  try {
    const saved = window.localStorage.getItem(storageKey);
    if (valid(saved)) preference = saved;
  } catch { /* The interface remains usable when storage is blocked. */ }
  function apply() {
    const theme = preference === 'system' ? (media?.matches ? 'dark' : 'light') : preference;
    document.documentElement.dataset.theme = theme;
    document.documentElement.dataset.themePreference = preference;
    for (const control of document.querySelectorAll('[data-admin-theme]')) control.value = preference;
  }
  window.HealthMateAppearance = {
    getPreference: () => preference,
    setPreference(value) {
      if (!valid(value)) return;
      preference = value;
      try { window.localStorage.setItem(storageKey, value); } catch { /* Session choice still applies. */ }
      apply();
    },
  };
  media?.addEventListener?.('change', () => { if (preference === 'system') apply(); });
  window.addEventListener('storage', event => {
    if (event.key !== storageKey && event.key !== null) return;
    preference = valid(event.newValue) ? event.newValue : 'system';
    apply();
  });
  apply();
})();
