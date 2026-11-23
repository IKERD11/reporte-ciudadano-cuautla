// Poll the existing authorized RPCs; no additional table grants or public channels.
export function startDashboardSync(
  refresh: () => Promise<void>,
  canRefresh: () => boolean,
  windowEvents: Pick<Window, 'addEventListener' | 'removeEventListener'>,
  page: Pick<Document, 'visibilityState' | 'addEventListener' | 'removeEventListener'>,
  interval = 30_000,
) {
  let stopped = false;
  let pending = false;
  const update = async () => {
    if (stopped || pending || page.visibilityState !== 'visible' || !canRefresh()) return;
    pending = true;
    try { await refresh(); }
    catch { /* The caller displays request errors; keep future retries available. */ }
    finally { pending = false; }
  };
  const onReturn = () => { void update(); };
  const timer = setInterval(onReturn, interval);
  windowEvents.addEventListener('focus', onReturn);
  windowEvents.addEventListener('online', onReturn);
  page.addEventListener('visibilitychange', onReturn);
  return () => {
    stopped = true;
    clearInterval(timer);
    windowEvents.removeEventListener('focus', onReturn);
    windowEvents.removeEventListener('online', onReturn);
    page.removeEventListener('visibilitychange', onReturn);
  };
}
