        <!-- Profile QR -->
        @php list($profileQrSrc) = qrCodeImage(profileUrl($userinfo), 600); @endphp
        <style>
          .profile-qr { display: inline-flex; flex-direction: column; align-items: center; gap: 6px; margin: 24px auto 0; padding: 12px 12px 8px; background: #fff; border: 3px solid #7ad21c; border-radius: 18px; cursor: zoom-in; }
          .profile-qr img { display: block; width: 160px; height: 160px; }
          .profile-qr span { color: #6b6b6b; font-size: .8rem; font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
          .profile-qr-overlay { position: fixed; inset: 0; z-index: 1000; display: none; align-items: center; justify-content: center; background: rgba(0, 0, 0, .85); cursor: zoom-out; }
          .profile-qr-overlay.open { display: flex; }
          .profile-qr-overlay img { width: min(88vw, 88vh, 520px); height: auto; padding: 14px; background: #fff; border: 3px solid #7ad21c; border-radius: 20px; }
        </style>
        <center>
          <div class="profile-qr fadein" role="button" tabindex="0" aria-label="{{ __('messages.pwa.profile_qr_enlarge') }}" onclick="document.getElementById('profile-qr-overlay').classList.add('open')" onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();this.click();}">
            <img src="{{ $profileQrSrc }}" alt="{{ __('messages.QR Code') }}" draggable="false">
            <span>{{ __('messages.pwa.profile_qr_hint') }}</span>
          </div>
        </center>
        <div class="profile-qr-overlay" id="profile-qr-overlay" onclick="this.classList.remove('open')">
          <img src="{{ $profileQrSrc }}" alt="{{ __('messages.QR Code') }}" draggable="false">
        </div>
        <script>document.addEventListener('keydown', function (e) { if (e.key === 'Escape') document.getElementById('profile-qr-overlay').classList.remove('open'); });</script>
