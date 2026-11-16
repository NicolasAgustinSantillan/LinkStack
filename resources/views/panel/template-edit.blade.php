@extends('layouts.sidebar')

@section('content')

@php
  $items = old('items_json') ? (json_decode(old('items_json'), true) ?: []) : ($template->items ?? []);
@endphp

<style>
  .tpl-item { border: 1px solid rgba(128, 128, 128, .3); border-radius: 10px; padding: 12px; margin-bottom: 10px; }
  .tpl-item .row > div { margin-bottom: 8px; }
  .tpl-item .tpl-actions { display: flex; gap: 6px; justify-content: flex-end; }
</style>

<div class="conatiner-fluid content-inner mt-n5 py-0">
  <div class="row">
    <div class="col-lg-12">
      <div class="card rounded">
        <div class="card-body">
          <section class="text-gray-400">
            <h2 class="mb-4 card-header"><i class="bi bi-layout-text-window-reverse"> {{ $template->exists ? $template->name : __('messages.templates.new') }}</i></h2>
            <div class="card-body p-0 p-md-3">

              @if($errors->any())
                <div class="alert alert-danger">
                  @foreach($errors->all() as $error)<div>{{ $error }}</div>@endforeach
                </div>
              @endif

              <form id="tpl-form" action="{{ route('saveTemplate', $template->exists ? $template->id : 'new') }}" method="post">
                @csrf
                <input type="hidden" name="items_json" id="items_json">

                <div class="form-group col-lg-6 mb-3">
                  <label class="form-label">{{ __('messages.Name') }}</label>
                  <input type="text" class="form-control" name="name" value="{{ old('name', $template->name) }}" required maxlength="255">
                </div>

                <div class="form-check mb-4">
                  <input class="form-check-input" type="checkbox" name="is_default" value="1" id="is_default" @checked(old('is_default', $template->is_default))>
                  <label class="form-check-label" for="is_default">{{ __('messages.templates.is_default') }}</label>
                </div>

                <h5>{{ __('messages.templates.items') }}</h5>
                <p class="text-muted small">{{ __('messages.templates.items_hint') }}</p>

                <div id="tpl-items"></div>

                <button type="button" class="btn btn-outline-primary btn-sm mb-4" id="tpl-add">+ {{ __('messages.templates.add_item') }}</button>

                <div>
                  <button type="submit" class="btn btn-primary">{{ __('messages.Save') }}</button>
                  <a href="{{ route('showTemplates') }}" class="btn btn-secondary">{{ __('messages.Cancel') }}</a>
                </div>
              </form>

            </div>
          </section>
        </div>
      </div>
    </div>
  </div>
</div>

<template id="tpl-row">
  <div class="tpl-item">
    <div class="row">
      <div class="col-md-3">
        <label class="form-label small">{{ __('messages.templates.type') }}</label>
        <select class="form-select" data-field="type">
          <option value="link">{{ __('messages.templates.type_link') }}</option>
          <option value="predefined">{{ __('messages.templates.type_predefined') }}</option>
          <option value="heading">{{ __('messages.templates.type_heading') }}</option>
        </select>
      </div>
      <div class="col-md-3" data-show="predefined">
        <label class="form-label small">{{ __('messages.templates.button') }}</label>
        <select class="form-select" data-field="button">
          @foreach($buttons as $button)
            <option value="{{ $button->name }}">{{ $button->alt }}</option>
          @endforeach
        </select>
      </div>
      <div class="col-md-3">
        <label class="form-label small">{{ __('messages.Title') }}</label>
        <input type="text" class="form-control" data-field="title" maxlength="255">
      </div>
      <div class="col-md-4" data-show="link predefined">
        <label class="form-label small">URL</label>
        <input type="text" class="form-control" data-field="url" placeholder="https://">
      </div>
    </div>
    <div class="d-flex flex-wrap justify-content-between align-items-center">
      <div class="form-check" data-show="link">
        <input class="form-check-input" type="checkbox" data-field="site_icon">
        <label class="form-check-label small">{{ __('messages.templates.site_icon') }}</label>
      </div>
      <div class="tpl-actions ms-auto">
        <button type="button" class="btn btn-sm btn-outline-secondary" data-action="up" title="↑"><i class="bi bi-arrow-up"></i></button>
        <button type="button" class="btn btn-sm btn-outline-secondary" data-action="down" title="↓"><i class="bi bi-arrow-down"></i></button>
        <button type="button" class="btn btn-sm btn-outline-danger" data-action="remove" title="{{ __('messages.Delete') }}"><i class="bi bi-trash"></i></button>
      </div>
    </div>
  </div>
</template>

<script>
  (function () {
    var list = document.getElementById('tpl-items');
    var rowTemplate = document.getElementById('tpl-row');

    function field(row, name) { return row.querySelector('[data-field="' + name + '"]'); }

    function refresh(row) {
      var type = field(row, 'type').value;
      row.querySelectorAll('[data-show]').forEach(function (el) {
        el.style.display = el.dataset.show.split(' ').indexOf(type) >= 0 ? '' : 'none';
      });
    }

    function addRow(item) {
      item = item || { type: 'link', site_icon: true };
      var row = rowTemplate.content.firstElementChild.cloneNode(true);
      field(row, 'type').value = item.type || 'link';
      if (item.button) field(row, 'button').value = item.button;
      field(row, 'title').value = item.title || '';
      field(row, 'url').value = item.url || '';
      field(row, 'site_icon').checked = !!item.site_icon;
      field(row, 'type').addEventListener('change', function () { refresh(row); });
      row.querySelector('[data-action="up"]').addEventListener('click', function () {
        if (row.previousElementSibling) list.insertBefore(row, row.previousElementSibling);
      });
      row.querySelector('[data-action="down"]').addEventListener('click', function () {
        if (row.nextElementSibling) list.insertBefore(row.nextElementSibling, row);
      });
      row.querySelector('[data-action="remove"]').addEventListener('click', function () { row.remove(); });
      list.appendChild(row);
      refresh(row);
    }

    @json($items).forEach(addRow);
    document.getElementById('tpl-add').addEventListener('click', function () { addRow(); });

    document.getElementById('tpl-form').addEventListener('submit', function () {
      var items = Array.prototype.map.call(list.children, function (row) {
        var type = field(row, 'type').value;
        return {
          type: type,
          button: type === 'predefined' ? field(row, 'button').value : null,
          title: field(row, 'title').value,
          url: type === 'heading' ? '' : field(row, 'url').value,
          site_icon: type === 'link' && field(row, 'site_icon').checked
        };
      });
      document.getElementById('items_json').value = JSON.stringify(items);
    });
  })();
</script>

@endsection
