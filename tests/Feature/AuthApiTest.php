<?php

namespace Tests\Feature;

use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_sign_in_and_fetch_session(): void
    {
        $this->seed(DatabaseSeeder::class);

        $response = $this->postJson('/api/auth/sign-in', [
            'email' => 'customer@optimus.test',
            'password' => 'password',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('user.role', 'customer')
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email', 'role']]);

        $token = $response->json('token');

        $this->withToken($token)
            ->getJson('/api/auth/session')
            ->assertOk()
            ->assertJsonPath('valid', true)
            ->assertJsonPath('user.email', 'customer@optimus.test');
    }
}
