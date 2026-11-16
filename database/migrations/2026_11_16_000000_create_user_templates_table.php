<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CreateUserTemplatesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('user_templates', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->boolean('is_default')->default(false);
            $table->text('items')->nullable();
            $table->timestamps();
        });

        // Starting template: every new user links to the Antares website
        DB::table('user_templates')->insert([
            'name' => 'Antares',
            'is_default' => true,
            'items' => json_encode([
                ['type' => 'link', 'title' => 'Antares Automation', 'url' => 'https://www.antaresautomation.com/', 'site_icon' => true],
            ]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('user_templates');
    }
}
