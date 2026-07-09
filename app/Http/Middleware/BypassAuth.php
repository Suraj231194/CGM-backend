<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * Development-only middleware that skips token authentication.
 * Auto-authenticates as the first user (or the user specified via X-Bypass-User-Id header).
 */
class BypassAuth
{
    public function handle(Request $request, Closure $next, ...$guards): Response
    {
        $userId = $request->header('X-Bypass-User-Id');
        $user = $userId
            ? User::query()->find($userId)
            : User::query()->first();

        if ($user) {
            Auth::setUser($user);
            $request->setUserResolver(fn () => $user);
        }

        return $next($request);
    }
}
