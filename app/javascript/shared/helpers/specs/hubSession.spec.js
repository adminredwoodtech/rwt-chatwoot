import { rememberHubChannel, notifyHub, startHubSession } from '../hubSession';

describe('Hub session protocol', () => {
  const parent = { postMessage: vi.fn() };
  beforeEach(() => {
    vi.stubGlobal('parent', parent);
    window.chatwootConfig = { happseaHubUrl: 'https://hub.example.com' };
    sessionStorage.clear();
    parent.postMessage.mockClear();
  });
  afterEach(() => {
    vi.unstubAllGlobals();
    window.chatwootConfig = {};
    window.history.replaceState({}, '', '/');
  });

  it('persists only the correlation nonce, not the SSO token', () => {
    window.history.replaceState(
      {},
      '',
      '/?happsea_channel=attempt-unique-1234&sso_auth_token=secret'
    );
    rememberHubChannel();
    notifyHub('happsea:auth-required');
    expect(parent.postMessage).toHaveBeenCalledWith(
      { type: 'happsea:auth-required', channel: 'attempt-unique-1234' },
      'https://hub.example.com'
    );
    expect(sessionStorage.length).toBe(1);
  });

  it('responds to trusted parent probes and removes the listener on unmount', () => {
    const stop = startHubSession();
    expect(parent.postMessage).toHaveBeenCalledTimes(1);
    const probe = origin =>
      new MessageEvent('message', {
        origin,
        source: parent,
        data: { type: 'happsea:probe' },
      });
    window.dispatchEvent(probe('https://evil.test'));
    expect(parent.postMessage).toHaveBeenCalledTimes(1);
    window.dispatchEvent(probe('https://hub.example.com'));
    expect(parent.postMessage).toHaveBeenCalledTimes(2);
    stop();
    window.dispatchEvent(probe('https://hub.example.com'));
    expect(parent.postMessage).toHaveBeenCalledTimes(2);
  });
});
