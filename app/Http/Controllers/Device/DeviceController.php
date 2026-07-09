<?php

namespace App\Http\Controllers\Device;

use App\Http\Controllers\Controller;
use App\Http\Resources\DeviceResource;
use App\Models\Device;
use App\Models\PatientProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    public function index(PatientProfile $patient): JsonResponse
    {
        return ApiResponse::success([
            'sensors' => DeviceResource::collection($patient->devices()->latest()->get()),
        ]);
    }

    public function store(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'serialNumber' => ['required_without:serial_number', 'string', 'max:120'],
            'serial_number' => ['required_without:serialNumber', 'string', 'max:120'],
            'model' => ['nullable', 'string', 'max:120'],
            'manufacturer' => ['nullable', 'string', 'max:120'],
            'status' => ['nullable', 'string', 'max:40'],
            'batteryStatus' => ['nullable', 'integer', 'min:0', 'max:100'],
            'connectionStatus' => ['nullable', 'string', 'max:40'],
        ]);

        $device = $patient->devices()->create([
            'serial_number' => $data['serialNumber'] ?? $data['serial_number'],
            'model' => $data['model'] ?? 'Optimus CGM 14-day sensor',
            'manufacturer' => $data['manufacturer'] ?? 'Optimus',
            'status' => $data['status'] ?? 'inactive',
            'battery_status' => $data['batteryStatus'] ?? 100,
            'connection_status' => $data['connectionStatus'] ?? 'offline',
        ]);

        return response()->json(new DeviceResource($device), 201);
    }

    public function update(Request $request, Device $device): JsonResponse
    {
        abort_unless($request->user()?->canAccessPatient($device->patient), 403);

        $data = $request->validate([
            'status' => ['nullable', 'string', 'max:40'],
            'batteryStatus' => ['nullable', 'integer', 'min:0', 'max:100'],
            'connectionStatus' => ['nullable', 'string', 'max:40'],
            'activationDate' => ['nullable', 'date'],
            'expiryDate' => ['nullable', 'date'],
            'warmupStartTime' => ['nullable', 'date'],
            'warmupEndTime' => ['nullable', 'date'],
        ]);

        $device->update([
            'status' => $data['status'] ?? $device->status,
            'battery_status' => $data['batteryStatus'] ?? $device->battery_status,
            'connection_status' => $data['connectionStatus'] ?? $device->connection_status,
            'activation_date' => $data['activationDate'] ?? $device->activation_date,
            'expiry_date' => $data['expiryDate'] ?? $device->expiry_date,
            'warmup_start_time' => $data['warmupStartTime'] ?? $device->warmup_start_time,
            'warmup_end_time' => $data['warmupEndTime'] ?? $device->warmup_end_time,
            'last_sync_at' => now(),
        ]);

        return response()->json(new DeviceResource($device->refresh()));
    }
}
