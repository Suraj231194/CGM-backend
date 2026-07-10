<?php

namespace Database\Seeders;

use App\Models\AlertSetting;
use App\Models\PatientProfile;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AuthBypassSeeder extends Seeder
{
    public function run(): void
    {
        if (! config('app.auth_bypass')) {
            return;
        }

        $email = (string) config('app.auth_bypass_email', 'customer@optimus.test');
        $password = (string) config('app.auth_bypass_password', 'password');

        $user = User::query()->updateOrCreate(
            ['email' => $email],
            [
                'name' => 'Optimus CGM Customer',
                'role' => 'customer',
                'password' => Hash::make($password),
                'email_verified_at' => now(),
                'is_active' => true,
            ],
        );

        $patient = PatientProfile::query()->firstOrCreate(
            ['user_id' => $user->id],
            [
                'name' => $user->name,
                'risk_level' => 'stable',
                'medical_record_number' => 'OPT-BYPASS-'.$user->id,
                'preferred_unit' => 'mg/dL',
            ],
        );

        AlertSetting::query()->firstOrCreate(['patient_id' => $patient->id]);
    }
}
