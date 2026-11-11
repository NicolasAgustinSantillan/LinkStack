{{-- PWA: makes the dashboard installable and registers the service worker that keeps "/qr" available offline --}}
<link rel="manifest" href="{{ url('/manifest.webmanifest') }}">
<meta name="theme-color" content="#7ad21c">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="{{ env('APP_NAME') }}">
<link rel="apple-touch-icon" href="{{ asset('assets/linkstack/images/pwa/icon-192.png') }}">
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', function () {
      navigator.serviceWorker.register('{{ url('/sw.js') }}', { scope: '/' }).catch(function () {});
    });
    // Forget the cached QR when the user explicitly logs out
    document.addEventListener('submit', function (e) {
      var action = e.target && e.target.getAttribute('action');
      if (action && /\/logout$/.test(action) && navigator.serviceWorker.controller) {
        navigator.serviceWorker.controller.postMessage({ type: 'logout' });
      }
    }, true);
  }
</script>
