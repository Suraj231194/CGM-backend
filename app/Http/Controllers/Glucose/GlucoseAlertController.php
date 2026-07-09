<?php

namespace App\Http\Controllers\Glucose;

use App\Http\Controllers\Controller;
use App\Http\Resources\AlertSettingResource;
use App\Http\Resources\GlucoseAlertResource;
use App\Models\GlucoseAlert;
use App\Models\PatientProfile;
use App\Services\Glucose\GlucoseAlertService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GlucoseAlertController extends Controller
{
    public function __construct(private readonly GlucoseAlertService $alerts) {}

    public function index(PatientProfile $patient): JsonResponse
    {
        return ApiResponse::success([
            'alerts' => GlucoseAlertResource::collection($patient->alerts()->latest('timestamp')->get()),
        ]);
    }

    public function acknowledge(Request $request, GlucoseAlert $alert): JsonResponse
    {
        abort_unless($request->user()?->canAccessPatient($alert->patient), 403);

        $alert->update([
            'acknowledged' => true,
            'acknowledged_by' => $request->user()->id,
            'acknowledged_at' => now(),
        ]);

        return response()->json(new GlucoseAlertResource($alert->refresh()));
    }

    public function settings(PatientProfile $patient): JsonResponse
    {
        return response()->json(new AlertSettingResource($this->alerts->settingsFor($patient)));
    }

    public function updateSettings(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'notificationsEnabled' => ['required', 'boolean'],
            'lowThreshold' => ['required', 'integer', 'min:40', 'max:140'],
            'highThreshold' => ['required', 'integer', 'min:120', 'max:400'],
            'quietHoursEnabled' => ['required', 'boolean'],
            'sensorDisconnectReminderMinutes' => ['required', 'integer', 'min:5', 'max:240'],
        ]);

        $settings = $this->alerts->settingsFor($patient);
        $settings->update([
            'notifications_enabled' => $data['notificationsEnabled'],
            'low_threshold' => $data['lowThreshold'],
            'high_threshold' => $data['highThreshold'],
            'quiet_hours_enabled' => $data['quietHoursEnabled'],
            'sensor_disconnect_reminder_minutes' => $data['sensorDisconnectReminderMinutes'],
        ]);

        return response()->json(new AlertSettingResource($settings->refresh()));
    }
}
