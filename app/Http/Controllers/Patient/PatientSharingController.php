<?php

namespace App\Http\Controllers\Patient;

use App\Http\Controllers\Controller;
use App\Http\Resources\ConsentRecordResource;
use App\Models\PatientProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PatientSharingController extends Controller
{
    public function consent(PatientProfile $patient): JsonResponse
    {
        $consent = $patient->consentRecords()->latest()->first()
            ?? $patient->consentRecords()->create(['user_id' => $patient->user_id]);

        return response()->json(new ConsentRecordResource($consent));
    }

    public function updateConsent(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'healthData' => ['required', 'boolean'],
            'sensorData' => ['required', 'boolean'],
            'aiCoaching' => ['required', 'boolean'],
            'reportSharing' => ['required', 'boolean'],
            'termsAccepted' => ['required', 'boolean'],
        ]);

        $consent = $patient->consentRecords()->create([
            'user_id' => $request->user()->id,
            'health_data' => $data['healthData'],
            'sensor_data' => $data['sensorData'],
            'ai_coaching' => $data['aiCoaching'],
            'report_sharing' => $data['reportSharing'],
            'terms_accepted' => $data['termsAccepted'],
            'status' => $data['termsAccepted'] ? 'accepted' : 'pending',
            'consented_at' => $data['termsAccepted'] ? now() : null,
        ]);

        return response()->json(new ConsentRecordResource($consent));
    }

    public function grantDoctorAccess(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'doctor_id' => ['required', 'exists:users,id'],
            'expires_at' => ['nullable', 'date', 'after:now'],
            'permissions' => ['nullable', 'array'],
        ]);

        $grant = $patient->dataGrants()->updateOrCreate(
            ['doctor_id' => $data['doctor_id']],
            [
                'granted_by' => $request->user()->id,
                'status' => 'accepted',
                'permissions' => $data['permissions'] ?? ['readings:read', 'reports:read'],
                'granted_at' => now(),
                'expires_at' => $data['expires_at'] ?? null,
            ],
        );

        return ApiResponse::success(['grant' => $grant], status: 201);
    }
}
