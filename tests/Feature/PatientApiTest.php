<?php

namespace Tests\Feature;

use App\Models\PatientProfile;
use App\Models\User;
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
