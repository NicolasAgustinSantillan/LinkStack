<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

use App\Models\UserTemplate;

// Admin → "Templates for new users"
class UserTemplateController extends Controller
{
    public function index()
    {
        $templates = UserTemplate::orderByDesc('is_default')->orderBy('name')->get();

        return view('panel/templates', ['templates' => $templates]);
    }

    public function edit($id)
    {
        $template = $id === 'new' ? new UserTemplate(['items' => []]) : UserTemplate::findOrFail($id);

        return view('panel/template-edit', [
            'template' => $template,
            'buttons' => UserTemplate::brandButtons(),
        ]);
    }

    public function save(Request $request, $id)
    {
        $template = $id === 'new' ? new UserTemplate() : UserTemplate::findOrFail($id);

        $items = json_decode($request->input('items_json', '[]'), true);
        $request->merge(['items' => is_array($items) ? array_values($items) : []]);

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'items' => 'array',
            'items.*.type' => 'required|in:' . implode(',', UserTemplate::TYPES),
            'items.*.title' => 'nullable|string|max:255|required_unless:items.*.type,predefined',
            'items.*.url' => 'nullable|string|max:2000|required_unless:items.*.type,heading',
            'items.*.button' => 'nullable|string|required_if:items.*.type,predefined',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        $template->name = $request->input('name');
        $template->is_default = $request->boolean('is_default');
        $template->items = array_map(function ($item) {
            return [
                'type' => $item['type'],
                'title' => trim($item['title'] ?? ''),
                'url' => trim($item['url'] ?? ''),
                'button' => $item['button'] ?? null,
                'site_icon' => !empty($item['site_icon']),
            ];
        }, $request->input('items'));
        $template->save();

        // Only one template is preselected when creating users
        if ($template->is_default) {
            UserTemplate::where('id', '!=', $template->id)->update(['is_default' => false]);
        }

        return redirect()->route('showTemplates')->with('success', __('messages.templates.saved'));
    }

    public function delete($id)
    {
        UserTemplate::findOrFail($id)->delete();

        return redirect()->route('showTemplates');
    }
}
