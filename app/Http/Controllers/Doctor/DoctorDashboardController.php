<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Http\Resources\CareTaskResource;
use App\Http\Resources\GlucoseAlertResource;
use App\Http\Resources\PatientProfileResource;
use App\Models\CareTask;
use App\Models\GlucoseAlert;
use App\Models\PatientProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DoctorDashboardController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $patientQuery = PatientProfile::query()->with('latestDevice');

        if (! $user->hasRole('admin')) {
            $patientQuery->where('doctor_id', $user->id);
        }

        $patientIds = (clone $patientQuery)->pluck('id');

        return ApiResponse::success([
            'patients' => PatientProfileResource::collection(
                $patientQuery->orderByRaw("CASE risk_level WHEN 'urgent' THEN 1 WHEN 'watch' THEN 2 ELSE 3 END")->get(),
            ),
            'activeAlerts' => GlucoseAlertResource::collection(
                GlucoseAlert::query()->whereIn('patient_id', $patientIds)->where('acknowledged', false)->latest('timestamp')->limit(20)->get(),
            ),
            'openTasks' => CareTaskResource::collection(
                CareTask::query()->whereIn('patient_id', $patientIds)->where('status', '!=', 'completed')->latest()->limit(30)->get(),
            ),
        ]);
    }
}
