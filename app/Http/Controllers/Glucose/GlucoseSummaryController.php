<?php

namespace App\Http\Controllers\Glucose;

use App\Http\Controllers\Controller;
use App\Models\PatientProfile;
use App\Services\Glucose\GlucoseSummaryService;
use App\Support\ApiResponse;
use App\Support\DateRange;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GlucoseSummaryController extends Controller
{
    public function __construct(private readonly GlucoseSummaryService $summaries) {}

    public function show(Request $request, PatientProfile $patient): JsonResponse
    {
        $range = DateRange::fromRequest($request);

        return ApiResponse::success([
            'summary' => [
                'patientId' => (string) $patient->id,
                ...$this->summaries->summarize($patient, $range->from, $range->to),
            ],
        ]);
    }
}
