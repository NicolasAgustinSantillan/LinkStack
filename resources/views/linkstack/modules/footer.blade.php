<div class="container">
	{{-- Antares: no Home/Terms/Privacy/Contact links on the profile card --}}
	<div class="footer fadein" style="margin:5% 0px 35px 0px;"></div>

	@if(env('DISPLAY_CREDIT') === true)
	{{-- Removed class spacing --}}
	<a style="text-decoration: none;" class="" href="https://linkstack.org" target="_blank" title="{{__('messages.Learn more about LinkStack')}}">
		<div style="vertical-align: middle;display: inline-block;padding-bottom:50px;" class="credit-hover hvr-grow fadein">
			<img style="width:200px" class="" src="{{ asset('assets/linkstack/images/powered-by-linkstack.svg') }}" alt="LinkStack">
		</div>
	</a>
	@endif
	</div>