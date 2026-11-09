const scopes = new WeakMap();

// The shell owns navigation; each view also replaces its previous scope on
// refresh. Never leave subscriptions attached to a detached page or session.
export function liveScope(host, isCurrent, onDispose = () => {}) {
  scopes.get(host)?.stop();
  let stopped = false;
  const cleanups = new Set();
  const scope = {
    current: () => !stopped && isCurrent(),
    add(stop) { if (stopped) stop?.(); else if (stop) cleanups.add(stop); return stop; },
    stop() { if (stopped) return; stopped = true; for (const stop of cleanups) stop(); cleanups.clear(); },
  };
  scopes.set(host, scope); onDispose(scope.stop);
  return scope;
}

export function observe(scope, api, method, args, receive, failure, fallback) {
  if (!api[method]) return fallback().then(value => { if (scope.current()) receive(value); }).catch(error => { if (scope.current()) failure(error); });
  return new Promise(resolve => {
    scope.add(api[method](...args, value => {
      try { if (scope.current()) receive(value); }
      catch (error) { if (scope.current()) failure(error); }
      finally { resolve(); }
    }, error => {
      if (scope.current()) failure(error); resolve();
    }, {isCurrent: scope.current}));
    scope.add(resolve);
  });
}
