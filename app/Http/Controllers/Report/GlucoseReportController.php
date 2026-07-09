<?php

namespace App\Http\Controllers\Report;

use App\Http\Controllers\Controller;
use App\Http\Resources\ReportExportResource;
use App\Models\PatientProfile;
use App\Services\Report\GlucoseReportService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GlucoseReportController extends Controller
{
    public function __construct(private readonly GlucoseReportService $reports) {}

    public function index(PatientProfile $patient): JsonResponse
    {
        return ApiResponse::success([
            'reports' => ReportExportResource::collection($patient->reports()->latest('generated_at')->get()),
        ]);
    }

    public function store(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'period' => ['required', 'string', 'max:80'],
            'format' => ['required', 'in:PDF,CSV,pdf,csv'],
        ]);

        $report = $this->reports->generate($patient, $request->user(), $data['period'], $data['format']);

        return response()->json(new ReportExportResource($report), 201);
    }
}
