<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Set of links copied to a user when the admin creates it.
 *
 * Each item is one of:
 *   ['type' => 'link',       'title' => ..., 'url' => ..., 'site_icon' => bool]
 *   ['type' => 'predefined', 'button' => <buttons.name>, 'title' => ..., 'url' => ...]
 *   ['type' => 'heading',    'title' => ...]
 *   ['type' => 'email',      'title' => ...]   mailto: with the email of each user
 */
class UserTemplate extends Model
{
    public const TYPES = ['link', 'predefined', 'heading', 'email'];

    // Buttons that are blocks or internal, not brand buttons
    public const HIDDEN_BUTTONS = ['custom', 'custom_website', 'heading', 'space', 'text', 'icon', 'vcard', 'phone', 'littlelink-custom', 'default email', 'default email_alt'];

    protected $fillable = ['name', 'is_default', 'items'];

    protected $casts = [
        'is_default' => 'boolean',
        'items' => 'array',
    ];

    public static function brandButtons()
    {
        return Button::whereNotIn('name', self::HIDDEN_BUTTONS)->orderBy('alt')->get(['id', 'name', 'alt']);
    }

    // Create the template links for the user, after any links it already has
    public function applyTo(User $user): void
    {
        $linkTypes = LinkType::get()->keyBy('typename');
        $order = (int) Link::where('user_id', $user->id)->max('order');

        foreach ($this->items ?? [] as $item) {
            $type = $item['type'] ?? 'link';
            $data = ['type' => $type, 'title' => $item['title'] ?? ''];

            switch ($type) {
                case 'predefined':
                    $button = Button::where('name', $item['button'] ?? '')->first();
                    if (!$button) continue 2;
                    $data['button_id'] = $button->id;
                    $data['title'] = $data['title'] !== '' ? $data['title'] : $button->alt;
                    $data['link'] = $item['url'] ?? '';
                    break;
                case 'heading':
                    $data['button_id'] = 42;
                    $data['link'] = '';
                    break;
                case 'email':
                    // Same as the "E-Mail" block: button "default email"
                    $data['button_id'] = 6;
                    $data['link'] = 'mailto:' . $user->email;
                    $data['title'] = $data['title'] !== '' ? $data['title'] : $user->email;
                    break;
                default:
                    $data['type'] = 'link';
                    $data['button_id'] = !empty($item['site_icon']) ? 2 : 1;
                    $data['link'] = $item['url'] ?? '';
            }

            // Same block parameters UserController::saveLink stores
            $params = [];
            $linkType = $linkTypes->get($data['type']);
            foreach (['custom_html', 'ignore_container', 'include_libraries'] as $key) {
                if ($linkType && isset($linkType->$key)) {
                    $params[$key] = $linkType->$key;
                }
            }
            $data['type_params'] = json_encode($params);

            $link = new Link($data);
            $link->user_id = $user->id;
            $link->order = ++$order;
            $link->save();
        }
    }
}
