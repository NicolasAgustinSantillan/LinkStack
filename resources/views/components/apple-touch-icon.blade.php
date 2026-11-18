{{-- Apple touch icon: used by iOS when the page is added to the home screen (SVGs are not supported, so we fall back to the PWA icon) --}}
@if(file_exists(base_path("assets/linkstack/images/").findFile('favicon')) && !str_ends_with(strtolower(findFile('favicon')), '.svg'))
<link rel="apple-touch-icon" href="{{ asset('assets/linkstack/images/'.findFile('favicon')) }}">
@else
<link rel="apple-touch-icon" href="{{ asset('assets/linkstack/images/pwa/icon-192.png') }}">
@endif
