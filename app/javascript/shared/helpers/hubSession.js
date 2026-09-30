// Origin-bound protocol: never send credentials or SSO tokens to the parent.
export function rememberHubChannel() {
  const channel = new URLSearchParams(window.location.search).get(
    'happsea_channel'
  );
  if (channel && /^[a-zA-Z0-9-]{16,80}$/.test(channel)) {
    try {
      sessionStorage.setItem('happsea_channel', channel);
    } catch (_) {
      /* storage may be blocked */
    }
  }
}

export function notifyHub(type) {
  const hub = window.chatwootConfig?.happseaHubUrl;
  if (!hub || window.parent === window) return;
  let channel;
  try {
    channel = sessionStorage.getItem('happsea_channel');
  } catch (_) {
    /* no channel */
  }
  window.parent.postMessage({ type, channel }, new URL(hub).origin);
}

export function startHubSession() {
  const hub = window.chatwootConfig?.happseaHubUrl;
  if (!hub || window.parent === window) return () => {};
  const origin = new URL(hub).origin;
  const listener = event => {
    if (
      event.source === window.parent &&
      event.origin === origin &&
      event.data?.type === 'happsea:probe'
    ) {
      notifyHub('happsea:ready');
    }
  };
  window.addEventListener('message', listener);
  notifyHub('happsea:ready');
  return () => window.removeEventListener('message', listener);
}
