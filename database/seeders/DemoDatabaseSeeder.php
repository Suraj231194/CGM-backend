<?php

namespace Database\Seeders;

use App\Models\AIInterpretation;
use App\Models\AlertSetting;
use App\Models\CareTask;
use App\Models\Device;
use App\Models\DeviceIntegration;
use App\Models\DoctorProfile;
use App\Models\MealLog;
use App\Models\Organization;
use App\Models\OrganizationMember;
use App\Models\PatientProfile;
use App\Models\SensorOrder;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DemoDatabaseSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->environment('production')) {
            throw new \LogicException('Demo data seeding is disabled in production.');
        }

        $organization = Organization::query()->firstOrCreate(
            ['slug' => 'optimus-care'],
            [
                'name' => 'Optimus Care Clinic',
                'type' => 'clinic',
                'timezone' => 'Asia/Kolkata',
            ],
        );

        $customer = User::query()->updateOrCreate(
            ['email' => 'customer@optimus.test'],
            [
                'name' => 'Aarav Mehta',
                'phone' => '+91 98765 43210',
                'role' => 'customer',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
            ],
        );

        $doctor = User::query()->updateOrCreate(
            ['email' => 'doctor@optimus.test'],
            [
                'name' => 'Dr. Meera Shah',
                'phone' => '+91 99887 77665',
                'role' => 'doctor',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
            ],
        );

        $admin = User::query()->updateOrCreate(
            ['email' => 'admin@optimus.test'],
            [
                'name' => 'Optimus Support Admin',
                'phone' => '+91 90000 11122',
                'role' => 'admin',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
            ],
        );

        foreach ([[$doctor, 'doctor'], [$admin, 'admin']] as [$user, $role]) {
            OrganizationMember::query()->updateOrCreate(
                ['organization_id' => $organization->id, 'user_id' => $user->id],
                ['role' => $role, 'joined_at' => now()],
            );
        }

        DoctorProfile::query()->updateOrCreate(
            ['user_id' => $doctor->id],
            [
                'organization_id' => $organization->id,
                'specialty' => 'Endocrinology',
                'license_number' => 'OPT-DOC-001',
                'phone' => '+91 99887 77665',
            ],
        );

        $patients = collect([
            ['name' => 'Aarav Mehta', 'user_id' => $customer->id, 'age' => 42, 'gender' => 'Male', 'risk_level' => 'stable'],
            ['name' => 'Priya Nair', 'user_id' => null, 'age' => 36, 'gender' => 'Female', 'risk_level' => 'watch'],
            ['name' => 'Kabir Sethi', 'user_id' => null, 'age' => 51, 'gender' => 'Male', 'risk_level' => 'urgent'],
            ['name' => 'Nisha Rao', 'user_id' => null, 'age' => 29, 'gender' => 'Female', 'risk_level' => 'stable'],
        ])->map(function (array $data, int $index) use ($doctor, $organization): PatientProfile {
            return PatientProfile::query()->updateOrCreate(
                ['medical_record_number' => 'OPT-PAT-'.($index + 1)],
                [
                    ...$data,
                    'doctor_id' => $doctor->id,
                    'organization_id' => $organization->id,
                    'preferred_unit' => 'mg/dL',
                ],
            );
        });

        $patients->each(function (PatientProfile $patient, int $index): void {
            AlertSetting::query()->firstOrCreate(['patient_id' => $patient->id]);

            Device::query()->updateOrCreate(
                ['serial_number' => 'OPT-CGM-14D-00'.($index + 1)],
                [
                    'patient_id' => $patient->id,
                    'status' => $index === 3 ? 'warmingUp' : 'active',
                    'battery_status' => [74, 38, 86, 97][$index],
                    'connection_status' => ['connected', 'weak', 'connected', 'nearby'][$index],
                    'activation_date' => now()->subDays([9, 12, 3, 0][$index]),
                    'expiry_date' => now()->addDays([5, 2, 11, 14][$index]),
                    'warmup_start_time' => $index === 3 ? now()->subMinutes(24) : now()->subDays([9, 12, 3, 0][$index])->subHour(),
                    'warmup_end_time' => $index === 3 ? now()->addMinutes(36) : now()->subDays([9, 12, 3, 0][$index]),
                ],
            );
        });

        $patient = $patients->first();

        MealLog::query()->updateOrCreate(
            ['patient_id' => $patient->id, 'title' => 'Oats, eggs, and berries'],
            [
                'timestamp' => now()->subHours(6),
                'type' => 'breakfast',
                'net_carbs' => 38,
                'protein' => 24,
                'fiber' => 9,
                'activity_minutes' => 12,
                'score' => 86,
                'note' => 'Stable response after a short walk.',
            ],
        );

        MealLog::query()->updateOrCreate(
            ['patient_id' => $patient->id, 'title' => 'Rice bowl with paneer'],
            [
                'timestamp' => now()->subHours(2),
                'type' => 'lunch',
                'net_carbs' => 58,
                'protein' => 31,
                'fiber' => 7,
                'activity_minutes' => 8,
                'score' => 72,
                'note' => 'Higher carb load; pair with more fiber next time.',
            ],
        );

        SensorOrder::query()->updateOrCreate(
            ['patient_id' => $patient->id, 'tracking_number' => 'OPT-1001'],
            [
                'product_name' => 'Optimus CGM 14-day sensor',
                'quantity' => 2,
                'status' => 'delivered',
                'shipping_address' => '221 Health Park, Mumbai, Maharashtra 400001',
                'created_at' => now()->subDays(21),
            ],
        );

        AIInterpretation::query()->firstOrCreate(
            ['patient_id' => $patient->id, 'period' => '14 day'],
            [
                'summary' => 'Recent readings are mostly in range with mild post-meal rises.',
                'patterns' => ['Lunch meals produce the largest rise.', 'Short walks improve recovery.'],
                'recommendations' => ['Pair rice-heavy meals with extra fiber.', 'Keep the post-meal walk habit.'],
                'disclaimer' => 'AI insights are informational and do not replace clinician guidance.',
                'tone' => 'patient',
                'generated_at' => now(),
            ],
        );

        CareTask::query()->firstOrCreate(
            ['patient_id' => $patients[2]->id, 'title' => 'Urgent review: high-risk trend'],
            [
                'assigned_to' => $doctor->id,
                'owner_role' => 'doctor',
                'status' => 'open',
                'priority' => 'urgent',
                'due_at' => now()->addHours(2),
            ],
        );

        $this->seedIntegrations();
    }

    private function seedIntegrations(): void
    {
        collect([
            ['id' => 'optimus-native', 'name' => 'Optimus CGM SDK', 'provider' => 'Native bridge', 'category' => 'cgm', 'status' => 'available', 'summary' => 'Android .aar and iOS .xcframework integration path for direct sensor connectivity.'],
            ['id' => 'dexcom', 'name' => 'Dexcom', 'provider' => 'OAuth API', 'category' => 'cgm', 'status' => 'available', 'summary' => 'Cloud glucose import for supported Dexcom accounts.'],
            ['id' => 'nightscout', 'name' => 'Nightscout', 'provider' => 'REST adapter', 'category' => 'cgm', 'status' => 'available', 'summary' => 'Import readings from a Nightscout endpoint for continuity.'],
            ['id' => 'apple-health', 'name' => 'Apple Health', 'provider' => 'HealthKit', 'category' => 'health', 'status' => 'comingSoon', 'summary' => 'iOS lifestyle context for activity, sleep, and vitals.'],
            ['id' => 'health-connect', 'name' => 'Health Connect', 'provider' => 'Android', 'category' => 'health', 'status' => 'comingSoon', 'summary' => 'Android health context once native plugin permissions are added.'],
            ['id' => 'watch-widget', 'name' => 'Smartwatch widget', 'provider' => 'Companion surfaces', 'category' => 'watch', 'status' => 'available', 'summary' => 'Glanceable glucose, freshness, trend arrow, and alert state.'],
        ])->each(fn (array $integration) => DeviceIntegration::query()->updateOrCreate(
            ['id' => $integration['id']],
            $integration,
        ));
    }
}

