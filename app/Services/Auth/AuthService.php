<?php

namespace App\Services\Auth;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthService
{
    /**
     * @param  array{email: string, password: string, device_name?: string}  $credentials
     * @return array{token: string, user: User}
     */
    public function signIn(array $credentials): array
    {
        $email = Str::lower($credentials['email']);
        $user = User::query()->where('email', $email)->first();

        if (! $user || ! $user->is_active || ! Hash::check($credentials['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $user->forceFill(['last_login_at' => now()])->save();

        return [
            'token' => $user->createToken(
                $credentials['device_name'] ?? 'optimus-mobile',
                $user->tokenAbilities(),
            )->plainTextToken,
            'user' => $user->refresh(),
        ];
    }

    public function refresh(User $user): string
    {
        $user->currentAccessToken()?->delete();

        return $user->createToken('optimus-mobile', $user->tokenAbilities())->plainTextToken;
    }

    public function signOut(User $user): void
    {
        $user->currentAccessToken()?->delete();
    }
}
