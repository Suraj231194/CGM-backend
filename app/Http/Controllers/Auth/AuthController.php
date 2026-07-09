<?php

namespace App\Http\Controllers\Auth;

use App\Actions\Fortify\CreateNewUser;
use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Services\Audit\AuditLogService;
use App\Services\Auth\AuthService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function __construct(
        private readonly AuthService $auth,
        private readonly AuditLogService $audit,
    ) {}

    public function signIn(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:120'],
        ]);

        $session = $this->auth->signIn($credentials);
        $this->audit->record($session['user'], 'auth_sign_in', 'user', $session['user']->id, 'User signed in.', [], $request);

        return ApiResponse::success([
            'token' => $session['token'],
            'user' => new UserResource($session['user']),
        ]);
    }

    public function register(Request $request, CreateNewUser $creator): JsonResponse
    {
        $input = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255'],
            'phone' => ['nullable', 'string', 'max:40'],
            'role' => ['nullable', 'in:customer,doctor,admin'],
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        $user = $creator->create($input);
        $token = $user->createToken('optimus-mobile', $user->tokenAbilities())->plainTextToken;
        $this->audit->record($user, 'auth_register', 'user', $user->id, 'User registered.', [], $request);

        return ApiResponse::success([
            'token' => $token,
            'user' => new UserResource($user),
        ], status: 201);
    }

    public function signOut(Request $request): JsonResponse
    {
        $user = $request->user();
        $this->auth->signOut($user);
        $this->audit->record($user, 'auth_sign_out', 'user', $user->id, 'User signed out.', [], $request);

        return ApiResponse::success(message: 'Signed out.');
    }

    public function session(Request $request): JsonResponse
    {
        return ApiResponse::success([
            'valid' => true,
            'user' => new UserResource($request->user()),
        ]);
    }

    public function refresh(Request $request): JsonResponse
    {
        $token = $this->auth->refresh($request->user());

        return ApiResponse::success([
            'token' => $token,
            'user' => new UserResource($request->user()->refresh()),
        ]);
    }
}
