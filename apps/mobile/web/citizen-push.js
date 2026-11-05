window.setCitizenPush = async (endpoint, token, enabled, key) => {
  if (!('serviceWorker' in navigator) || !('PushManager' in window) || !key)
    return !enabled;
  const url = new URL('notification-sw.js', document.baseURI);
  const headers = {Authorization: 'Bearer ' + token, 'Content-Type': 'application/json'};
  if (enabled && await Notification.requestPermission() !== 'granted') return false;
  const registration = enabled ? await navigator.serviceWorker.register(url)
    : await navigator.serviceWorker.getRegistration(url);
  if (!registration) return !enabled;
  let subscription = await registration.pushManager.getSubscription();
  if (enabled && !subscription) {
    const raw = atob(key.replace(/-/g, '+').replace(/_/g, '/'));
    subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true, applicationServerKey: Uint8Array.from(raw, c => c.charCodeAt(0)),
    });
  }
  if (!subscription) return !enabled;
  const response = await fetch(endpoint + '/push-subscriptions', {
    method: enabled ? 'POST' : 'DELETE', headers,
    body: JSON.stringify(enabled ? {subscription: subscription.toJSON()} : {endpoint: subscription.endpoint}),
  });
  if (!enabled) await subscription.unsubscribe();
  return response.ok;
};
