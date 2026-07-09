<?php

namespace App\Http\Controllers\Common;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Resources\DeviceIntegrationResource;
use App\Models\DeviceIntegration;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class MasterDataController extends Controller
{
    public function integrations(): JsonResponse
    {
        return ApiResponse::success([
            'integrations' => DeviceIntegrationResource::collection(DeviceIntegration::query()->orderBy('name')->get()),
        ]);
    }

    public function enums(): JsonResponse
    {
        return ApiResponse::success([
            'roles' => array_map(fn (UserRole $role) => $role->value, UserRole::cases()),
            'glucoseStatuses' => ['low', 'normal', 'high'],
            'sensorStatuses' => ['inactive', 'attached', 'connecting', 'warmingUp', 'active', 'expired'],
            'connectionStatuses' => ['connected', 'nearby', 'weak', 'offline'],
            'mealTypes' => ['breakfast', 'lunch', 'dinner', 'snack'],
            'alertSeverities' => ['info', 'warning', 'urgent'],
        ]);
    }
}
