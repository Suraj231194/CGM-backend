<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class PasswordController extends Controller
{
    public function update(Request $request): JsonResponse
    {
        $input = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        abort_unless(Hash::check($input['current_password'], $request->user()->password), 422, 'The provided password does not match your current password.');

        $request->user()->forceFill([
            'password' => Hash::make($input['password']),
        ])->save();

        return ApiResponse::success(message: 'Password updated.');
    }
}
