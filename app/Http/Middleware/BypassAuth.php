<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * Explicit bypass middleware that skips token authentication.
 * Uses the configured bypass account unless X-Bypass-User-Id is supplied.
 */
class BypassAuth
{
    public function handle(Request $request, Closure $next, ...$guards): Response
    {
        $userId = $request->header('X-Bypass-User-Id');
        $user = $userId
            ? User::query()->find($userId)
            : User::query()->where(
                'email',
                config('app.auth_bypass_email', 'customer@optimus.test'),
            )->first();

        if (! $user) {
            return response()->json([
                'message' => 'Authentication bypass account is not provisioned.',
            ], 503);
        }

        Auth::setUser($user);
        $request->setUserResolver(fn () => $user);

        return $next($request);
    }
}
