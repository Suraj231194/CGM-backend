<?php

namespace App\Http\Controllers\Device;

use App\Http\Controllers\Controller;
use App\Http\Resources\SensorSessionResource;
use App\Models\Device;
use App\Models\PatientProfile;
use App\Models\SensorSession;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SensorSessionController extends Controller
{
    public function index(PatientProfile $patient): JsonResponse
    {
        return ApiResponse::success([
            'sessions' => SensorSessionResource::collection($patient->sensorSessions()->latest()->get()),
        ]);
    }

    public function store(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'sensorId' => ['required_without:device_id', 'exists:devices,id'],
            'device_id' => ['required_without:sensorId', 'exists:devices,id'],
            'status' => ['nullable', 'string', 'max:40'],
            'startedAt' => ['nullable', 'date'],
            'expiresAt' => ['nullable', 'date'],
            'notes' => ['nullable', 'string'],
        ]);

        $device = Device::query()->findOrFail($data['device_id'] ?? $data['sensorId']);
        abort_unless((int) $device->patient_id === (int) $patient->id, 422, 'Sensor does not belong to this patient.');

        $session = $patient->sensorSessions()->create([
            'device_id' => $device->id,
            'status' => $data['status'] ?? 'active',
            'started_at' => $data['startedAt'] ?? now(),
            'expires_at' => $data['expiresAt'] ?? now()->addDays(14),
            'notes' => $data['notes'] ?? null,
        ]);

        $device->update([
            'status' => 'active',
            'activation_date' => $session->started_at,
            'expiry_date' => $session->expires_at,
            'connection_status' => 'connected',
        ]);

        return response()->json(new SensorSessionResource($session), 201);
    }

    public function update(Request $request, SensorSession $session): JsonResponse
    {
        abort_unless($request->user()?->canAccessPatient($session->patient), 403);

        $data = $request->validate([
            'status' => ['nullable', 'string', 'max:40'],
            'endedAt' => ['nullable', 'date'],
            'notes' => ['nullable', 'string'],
        ]);

        $session->update([
            'status' => $data['status'] ?? $session->status,
            'ended_at' => $data['endedAt'] ?? $session->ended_at,
            'notes' => $data['notes'] ?? $session->notes,
        ]);

        return response()->json(new SensorSessionResource($session->refresh()));
    }
}
