@extends('layouts.sidebar')

@section('content')

<div class="conatiner-fluid content-inner mt-n5 py-0">
  <div class="row">
    <div class="col-lg-12">
      <div class="card rounded">
        <div class="card-body">
          <section class="text-gray-400">
            <h2 class="mb-4 card-header"><i class="bi bi-layout-text-window-reverse"> {{ __('messages.templates.title') }}</i></h2>
            <div class="card-body p-0 p-md-3">

              <p>{{ __('messages.templates.intro') }}</p>

              @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
              @endif

              @if($templates->isEmpty())
                <p class="text-muted">{{ __('messages.templates.empty') }}</p>
              @else
                <div class="table-responsive">
                  <table class="table table-striped align-middle">
                    <thead>
                      <tr>
                        <th>{{ __('messages.Name') }}</th>
                        <th>{{ __('messages.templates.items') }}</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      @foreach($templates as $template)
                        <tr>
                          <td>
                            {{ $template->name }}
                            @if($template->is_default)
                              <span class="badge bg-success ms-1">{{ __('messages.templates.default') }}</span>
                            @endif
                          </td>
                          <td>{{ count($template->items ?? []) }}</td>
                          <td class="text-end text-nowrap">
                            <a class="btn btn-sm btn-primary" href="{{ route('editTemplate', $template->id) }}"><i class="bi bi-pencil"></i> {{ __('messages.Edit') }}</a>
                            <form action="{{ route('deleteTemplate', $template->id) }}" method="post" class="d-inline" onsubmit="return confirm(@json(__('messages.templates.confirm_delete')))">
                              @csrf
                              <button type="submit" class="btn btn-sm btn-danger"><i class="bi bi-trash"></i> {{ __('messages.Delete') }}</button>
                            </form>
                          </td>
                        </tr>
                      @endforeach
                    </tbody>
                  </table>
                </div>
              @endif

              <a class="btn btn-primary mt-2" href="{{ route('editTemplate', 'new') }}">+ {{ __('messages.templates.new') }}</a>

            </div>
          </section>
        </div>
      </div>
    </div>
  </div>
</div>

@endsection
