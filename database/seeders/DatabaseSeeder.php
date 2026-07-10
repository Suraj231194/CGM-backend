<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->environment('production')) {
            $this->command?->warn('Demo data was not seeded because the application is running in production.');

            return;
        }

        $this->call(DemoDatabaseSeeder::class);
    }
}
