<?php

namespace App\Http\Controllers\Common;

use App\Http\Controllers\Controller;
use App\Models\PushToken;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PushTokenController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string', 'max:4096'],
            'platform' => ['required', 'in:android,ios,web'],
            'app' => ['nullable', 'string', 'max:80'],
        ]);

        $tokenHash = hash('sha256', $data['token']);
        $pushToken = PushToken::query()->firstOrNew(['token_hash' => $tokenHash]);
        $created = ! $pushToken->exists;

        $pushToken->fill([
            'user_id' => $request->user()->id,
            'token' => $data['token'],
            'platform' => $data['platform'],
            'app' => $data['app'] ?? 'optimus_cgm',
            'last_seen_at' => now(),
        ])->save();

        return ApiResponse::success([
            'pushToken' => [
                'id' => (string) $pushToken->id,
                'platform' => $pushToken->platform,
                'app' => $pushToken->app,
                'lastSeenAt' => $pushToken->last_seen_at?->toISOString(),
            ],
        ], status: $created ? 201 : 200);
    }
}
