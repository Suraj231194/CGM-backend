<?php

namespace Tests\Feature;

use App\Models\Device;
use App\Models\GlucoseReading;
use App\Models\PatientDataGrant;
use App\Models\PatientProfile;
use App\Models\PushToken;
use App\Models\SensorSession;
use App\Models\User;
use App\Services\Glucose\GlucoseAlertService;
use App\Services\Glucose\GlucoseIngestionService;
use Database\Seeders\AuthBypassSeeder;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PatientApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_doctor_can_list_assigned_patients(): void
    {
        $this->seed(DatabaseSeeder::class);
        $token = $this->tokenFor('doctor@optimus.test');

        $this->withToken($token)
            ->getJson('/api/patients')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(4, 'patients')
            ->assertJsonStructure(['patients' => [['id', 'name', 'doctorId', 'sensorId', 'riskLevel']]]);
    }

    public function test_customer_cannot_read_another_patient(): void
    {
        $this->seed(DatabaseSeeder::class);
        $customer = User::query()->where('email', 'customer@optimus.test')->firstOrFail();
        $otherPatient = PatientProfile::query()->where('user_id', '!=', $customer->id)->orWhereNull('user_id')->firstOrFail();

        $this->withToken($this->tokenFor('customer@optimus.test'))
            ->getJson("/api/patients/{$otherPatient->id}/readings")
            ->assertForbidden();
    }

    public function test_patient_reading_ingestion_creates_alert(): void
    {
        $this->seed(DatabaseSeeder::class);
        $customer = User::query()->where('email', 'customer@optimus.test')->firstOrFail();
        $patient = PatientProfile::query()->where('user_id', $customer->id)->firstOrFail();

        $this->withToken($this->tokenFor('customer@optimus.test'))
            ->postJson("/api/patients/{$patient->id}/readings", [
                'value' => 252,
                'timestamp' => now()->toISOString(),
                'trend' => 'rising',
            ])
            ->assertCreated()
            ->assertJsonPath('status', 'high');

        $this->withToken($this->tokenFor('customer@optimus.test'))
            ->getJson("/api/patients/{$patient->id}/alerts")
            ->assertOk()
            ->assertJsonPath('alerts.0.severity', 'urgent')
            ->assertJsonPath('alerts.0.value', 252);
    }

    public function test_sensor_registration_is_idempotent_for_a_patient(): void
    {
        $this->seed(DatabaseSeeder::class);
        $patient = PatientProfile::query()->whereNotNull('user_id')->firstOrFail();
        $token = $this->tokenFor('customer@optimus.test');
        $serial = 'D115W66200387';

        $this->withToken($token)
            ->postJson("/api/patients/{$patient->id}/sensors", ['serialNumber' => $serial])
            ->assertCreated()
            ->assertJsonPath('serialNumber', $serial);

        $this->withToken($token)
            ->postJson("/api/patients/{$patient->id}/sensors", ['serialNumber' => $serial])
            ->assertOk()
            ->assertJsonPath('serialNumber', $serial);

        $this->assertSame(1, Device::query()->where('serial_number', $serial)->count());
    }

    public function test_replayed_sdk_reading_is_stored_once(): void
    {
        $this->seed(DatabaseSeeder::class);
        $patient = PatientProfile::query()->whereNotNull('user_id')->firstOrFail();
        $device = $patient->devices()->firstOrFail();
        $token = $this->tokenFor('customer@optimus.test');
        $payload = [
            'readings' => [[
                'sensorId' => $device->id,
                'clientReadingId' => 'sdk:OPT-CGM-14D-001:1700000000:12',
                'value' => 117,
                'timestamp' => '2026-07-10T10:00:00Z',
                'trend' => 'rising',
                'source' => 'sdk',
            ]],
        ];

        $this->withToken($token)->postJson("/api/patients/{$patient->id}/readings/bulk", $payload)->assertCreated();
        $this->withToken($token)->postJson("/api/patients/{$patient->id}/readings/bulk", $payload)->assertCreated();

        $this->assertSame(1, GlucoseReading::query()
            ->where('client_reading_id', 'sdk:OPT-CGM-14D-001:1700000000:12')
            ->count());
    }

    public function test_reading_rejects_a_device_owned_by_another_patient(): void
    {
        $this->seed(DatabaseSeeder::class);
        $customer = User::query()->where('email', 'customer@optimus.test')->firstOrFail();
        $patient = PatientProfile::query()->where('user_id', $customer->id)->firstOrFail();
        $otherDevice = Device::query()->where('patient_id', '!=', $patient->id)->firstOrFail();

        $this->withToken($this->tokenFor('customer@optimus.test'))
            ->postJson("/api/patients/{$patient->id}/readings/bulk", [
                'readings' => [[
                    'sensorId' => $otherDevice->id,
                    'clientReadingId' => 'sdk:OTHER:1700000000:1',
                    'value' => 120,
                    'timestamp' => '2026-07-10T10:00:00Z',
                    'source' => 'sdk',
                ]],
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('readings.0.sensorId');
    }

    public function test_sdk_reading_requires_a_stable_client_id(): void
    {
        $this->seed(DatabaseSeeder::class);
        $customer = User::query()->where('email', 'customer@optimus.test')->firstOrFail();
        $patient = PatientProfile::query()->where('user_id', $customer->id)->firstOrFail();
        $device = $patient->devices()->firstOrFail();

        $this->withToken($this->tokenFor('customer@optimus.test'))
            ->postJson("/api/patients/{$patient->id}/readings/bulk", [
                'readings' => [[
                    'sensorId' => $device->id,
                    'value' => 120,
                    'timestamp' => '2026-07-10T10:00:00Z',
                    'source' => 'sdk',
                ]],
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('readings.0.clientReadingId');
    }

    public function test_reading_rejects_a_sensor_session_owned_by_another_patient(): void
    {
        $this->seed(DatabaseSeeder::class);
        $customer = User::query()->where('email', 'customer@optimus.test')->firstOrFail();
        $patient = PatientProfile::query()->where('user_id', $customer->id)->firstOrFail();
        $otherPatient = PatientProfile::query()->where('id', '!=', $patient->id)->firstOrFail();
        $otherDevice = $otherPatient->devices()->firstOrFail();
        $otherSession = SensorSession::query()->create([
            'patient_id' => $otherPatient->id,
            'device_id' => $otherDevice->id,
            'status' => 'active',
            'started_at' => now(),
        ]);

        $this->withToken($this->tokenFor('customer@optimus.test'))
            ->postJson("/api/patients/{$patient->id}/readings/bulk", [
                'readings' => [[
                    'sensor_session_id' => $otherSession->id,
                    'clientReadingId' => 'sdk:OTHER-SESSION:1700000000:1',
                    'value' => 120,
                    'timestamp' => '2026-07-10T10:00:00Z',
                    'source' => 'sdk',
                ]],
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('readings.0.sensor_session_id');
    }

    public function test_database_seeder_does_not_create_glucose_readings(): void
    {
        $this->seed(DatabaseSeeder::class);

        $this->assertSame(0, GlucoseReading::query()->count());
    }

    public function test_reading_rejects_a_sensor_session_for_a_different_device(): void
    {
        $this->seed(DatabaseSeeder::class);
        $patient = PatientProfile::query()->whereNotNull('user_id')->firstOrFail();
        $firstDevice = $patient->devices()->firstOrFail();
        $secondDevice = Device::query()->create([
            'patient_id' => $patient->id,
            'serial_number' => 'SECOND-DEVICE-001',
        ]);
        $session = SensorSession::query()->create([
            'patient_id' => $patient->id,
            'device_id' => $firstDevice->id,
            'status' => 'active',
            'started_at' => now(),
        ]);

        $this->withToken($this->tokenFor('customer@optimus.test'))
            ->postJson("/api/patients/{$patient->id}/readings/bulk", [
                'readings' => [[
                    'sensorId' => $secondDevice->id,
                    'sensor_session_id' => $session->id,
                    'clientReadingId' => 'sdk:SECOND-DEVICE-001:1700000000:1',
                    'value' => 120,
                    'timestamp' => '2026-07-10T10:00:00Z',
                    'source' => 'sdk',
                ]],
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('readings.0.sensor_session_id');

        $this->assertSame(0, GlucoseReading::query()->count());
    }

    public function test_reading_and_alert_creation_are_atomic(): void
    {
        $this->seed(DatabaseSeeder::class);
        $patient = PatientProfile::query()->whereNotNull('user_id')->firstOrFail();
        $device = $patient->devices()->firstOrFail();
        $alerts = new class extends GlucoseAlertService
        {
            public function evaluateReading(GlucoseReading $reading): never
            {
                throw new \RuntimeException('Alert creation failed.');
            }
        };
        $ingestion = new GlucoseIngestionService($alerts);

        try {
            $ingestion->ingest($patient, [
                'device_id' => $device->id,
                'client_reading_id' => 'sdk:ATOMIC:1700000000:1',
                'value' => 250,
                'timestamp' => now(),
                'source' => 'sdk',
            ]);
            $this->fail('Expected alert creation to fail.');
        } catch (\RuntimeException $exception) {
            $this->assertSame('Alert creation failed.', $exception->getMessage());
        }

        $this->assertSame(0, GlucoseReading::query()
            ->where('client_reading_id', 'sdk:ATOMIC:1700000000:1')
            ->count());
    }

    public function test_shared_doctor_permissions_are_enforced(): void
    {
        $this->seed(DatabaseSeeder::class);
        $patient = PatientProfile::query()->whereNotNull('user_id')->firstOrFail();
        $sharedDoctor = User::factory()->create([
            'role' => 'doctor',
            'email' => 'shared-doctor@optimus.test',
        ]);
        PatientDataGrant::query()->create([
            'patient_id' => $patient->id,
            'doctor_id' => $sharedDoctor->id,
            'granted_by' => $patient->user_id,
            'status' => 'accepted',
            'permissions' => ['readings:read'],
            'granted_at' => now(),
        ]);
        $token = $sharedDoctor->createToken('test', $sharedDoctor->tokenAbilities())->plainTextToken;

        $this->withToken($token)
            ->getJson("/api/patients/{$patient->id}/readings")
            ->assertOk();

        $this->withToken($token)
            ->postJson("/api/patients/{$patient->id}/meals", [
                'type' => 'lunch',
                'title' => 'Not permitted',
            ])
            ->assertForbidden();
    }

    public function test_authenticated_user_can_register_a_push_token_idempotently(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::query()->where('email', 'customer@optimus.test')->firstOrFail();
        $token = $this->tokenFor('customer@optimus.test');
        $payload = [
            'token' => 'firebase-registration-token',
            'platform' => 'android',
            'app' => 'optimus_cgm',
        ];

        $this->withToken($token)->postJson('/api/push-tokens', $payload)->assertCreated();
        $this->withToken($token)->postJson('/api/push-tokens', $payload)->assertOk();

        $this->assertSame(1, PushToken::query()->count());
        $this->assertSame($user->id, PushToken::query()->firstOrFail()->user_id);
    }

    public function test_auth_bypass_seeder_only_provisions_required_account_data(): void
    {
        config()->set('app.auth_bypass', true);

        $this->seed(AuthBypassSeeder::class);

        $user = User::query()
            ->where('email', 'customer@optimus.test')
            ->firstOrFail();

        $this->assertNotNull($user->patientProfile);
        $this->assertNotNull($user->patientProfile->alertSetting);
        $this->assertSame(0, Device::query()->count());
        $this->assertSame(0, GlucoseReading::query()->count());
    }

    private function tokenFor(string $email): string
    {
        $response = $this->postJson('/api/auth/sign-in', [
            'email' => $email,
            'password' => 'password',
        ]);

        $response->assertOk();

        return $response->json('token');
    }
}
