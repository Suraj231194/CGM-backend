<?php

namespace App\Http\Controllers\Patient;

use App\Http\Controllers\Controller;
use App\Http\Resources\DeviceResource;
use App\Http\Resources\GlucoseAlertResource;
use App\Http\Resources\GlucoseReadingResource;
use App\Http\Resources\MealLogResource;
use App\Http\Resources\PatientProfileResource;
use App\Models\PatientProfile;
use App\Services\Glucose\GlucoseSummaryService;
use App\Support\ApiResponse;
use App\Support\DateRange;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PatientDashboardController extends Controller
{
    public function __construct(private readonly GlucoseSummaryService $summaries) {}

    public function show(Request $request, PatientProfile $patient): JsonResponse
    {
        $range = DateRange::fromRequest($request);
        $latestReading = $patient->readings()->latest('timestamp')->first();

        return ApiResponse::success([
            'patient' => new PatientProfileResource($patient->load('latestDevice')),
            'sensor' => $patient->latestDevice ? new DeviceResource($patient->latestDevice) : null,
            'latestReading' => $latestReading ? new GlucoseReadingResource($latestReading) : null,
            'summary' => $this->summaries->summarize($patient, $range->from, $range->to),
            'activeAlerts' => GlucoseAlertResource::collection(
                $patient->alerts()->where('acknowledged', false)->latest('timestamp')->limit(10)->get(),
            ),
            'recentMeals' => MealLogResource::collection(
                $patient->meals()->latest('timestamp')->limit(10)->get(),
            ),
        ]);
    }
}
