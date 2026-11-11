<!doctype html>
@include('layouts.lang')
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>{{ __('messages.pwa.title') }} · {{ env('APP_NAME') }}</title>
  @include('layouts.pwa')
  <style>
    :root { --brand: #7ad21c; --ink: #1f1f1f; --muted: #6b6b6b; --line: #e6e6e6; }
    * { box-sizing: border-box; }
    html, body { margin: 0; background: #ffffff; color: var(--ink); }
    body {
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
      min-height: 100vh; min-height: 100dvh;
      display: flex; flex-direction: column; align-items: center;
      padding: max(16px, env(safe-area-inset-top)) 16px max(16px, env(safe-area-inset-bottom));
      text-align: center;
    }
    header img { height: 36px; width: auto; margin: 4px 0 8px; }
    main { flex: 1; width: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px; }
    .qr {
      width: min(88vw, 62vh, 520px); aspect-ratio: 1;
      padding: 14px; border-radius: 20px; background: #fff;
      border: 3px solid var(--brand);
    }
    .qr img { display: block; width: 100%; height: 100%; }
    h1 { font-size: 1.35rem; margin: 6px 0 0; }
    .handle { color: var(--muted); margin: 0; font-size: 1rem; }
    .hint { color: var(--muted); margin: 0; font-size: .9rem; max-width: 32rem; }
    .url { font-size: .8rem; color: var(--muted); word-break: break-all; }
    .actions { display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; margin-top: 4px; }
    .btn {
      appearance: none; border: 1px solid var(--line); background: #fff; color: var(--ink);
      padding: 10px 16px; border-radius: 999px; font-size: .95rem; text-decoration: none; cursor: pointer;
    }
    .btn.primary { background: var(--brand); border-color: var(--brand); color: #fff; font-weight: 600; }
    .notice { display: none; font-size: .85rem; background: #fff7e0; border: 1px solid #f1d58a; padding: 6px 12px; border-radius: 8px; }
    .install { display: none; margin-top: 16px; border-top: 1px solid var(--line); padding-top: 12px; max-width: 32rem; font-size: .85rem; color: var(--muted); }
    .install strong { color: var(--ink); display: block; margin-bottom: 4px; }
    @media (display-mode: standalone) { .install { display: none !important; } }
  </style>
</head>
<body>
  <header>
    <img src="{{ asset('assets/linkstack/images/pwa/antares-logo-wide.png') }}" alt="{{ env('APP_NAME') }}">
  </header>

  <main>
    <div class="notice" id="offline">{{ __('messages.pwa.offline') }}</div>

    <div class="qr"><img src="{{ $qrSrc }}" alt="{{ __('messages.QR Code') }}" draggable="false"></div>

    <h1>{{ $user->name }}</h1>
    @if($user->littlelink_name)
      <p class="handle">{{ '@'.$user->littlelink_name }}</p>
    @endif
    <p class="hint">{{ __('messages.pwa.hint') }}</p>
    <div class="url">{{ $qrURL }}</div>

    <div class="actions">
      <button type="button" class="btn primary" id="share">{{ __('messages.pwa.share') }}</button>
      @if($user->littlelink_name)
        <a class="btn" href="{{ url('/@'.$user->littlelink_name) }}">{{ __('messages.pwa.open_profile') }}</a>
      @endif
      <a class="btn" href="{{ route('panelIndex') }}">{{ __('messages.pwa.back') }}</a>
    </div>

    <div class="install" id="install">
      <strong>{{ __('messages.pwa.install_title') }}</strong>
      {{ __('messages.pwa.install_android') }}
      <div class="actions"><button type="button" class="btn" id="installBtn" hidden>{{ __('messages.pwa.install_button') }}</button></div>
    </div>
  </main>

  <script>
    (function () {
      var qrURL = @json($qrURL);
      var copiedMsg = @json(__('messages.pwa.copied'));

      // Served from the service worker cache without network
      if (!navigator.onLine) document.getElementById('offline').style.display = 'block';

      document.getElementById('share').addEventListener('click', function () {
        if (navigator.share) {
          navigator.share({ url: qrURL }).catch(function () {});
        } else if (navigator.clipboard) {
          navigator.clipboard.writeText(qrURL).then(function () { alert(copiedMsg); });
        }
      });

      // Keep the screen on while the code is being shown
      var wakeLock = null;
      function lockScreen() {
        if ('wakeLock' in navigator && document.visibilityState === 'visible') {
          navigator.wakeLock.request('screen').then(function (l) { wakeLock = l; }).catch(function () {});
        }
      }
      document.addEventListener('visibilitychange', lockScreen);
      lockScreen();

      // Reload when the service worker fetched a newer QR in the background
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.addEventListener('message', function (e) {
          if (e.data && e.data.type === 'qr-updated') location.reload();
        });
      }

      // Install hint (only in the browser, not inside the installed app)
      var standalone = window.matchMedia('(display-mode: standalone)').matches || navigator.standalone;
      if (!standalone) document.getElementById('install').style.display = 'block';
      var deferredPrompt = null;
      window.addEventListener('beforeinstallprompt', function (e) {
        e.preventDefault();
        deferredPrompt = e;
        document.getElementById('installBtn').hidden = false;
      });
      document.getElementById('installBtn').addEventListener('click', function () {
        if (!deferredPrompt) return;
        deferredPrompt.prompt();
        deferredPrompt = null;
        this.hidden = true;
      });
    })();
  </script>
</body>
</html>
