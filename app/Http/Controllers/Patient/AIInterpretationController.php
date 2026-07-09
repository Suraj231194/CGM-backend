<?php

namespace App\Http\Controllers\Patient;

use App\Http\Controllers\Controller;
use App\Http\Resources\AIInterpretationResource;
use App\Models\PatientProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AIInterpretationController extends Controller
{
    public function index(PatientProfile $patient): JsonResponse
    {
        return ApiResponse::success([
            'interpretations' => AIInterpretationResource::collection(
                $patient->aiInterpretations()->latest('generated_at')->get(),
            ),
        ]);
    }

    public function store(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'period' => ['required', 'string', 'max:80'],
            'summary' => ['required', 'string'],
            'patterns' => ['nullable', 'array'],
            'recommendations' => ['nullable', 'array'],
            'disclaimer' => ['nullable', 'string'],
            'tone' => ['nullable', 'string', 'max:40'],
        ]);

        $interpretation = $patient->aiInterpretations()->create([
            ...$data,
            'patterns' => $data['patterns'] ?? [],
            'recommendations' => $data['recommendations'] ?? [],
            'tone' => $data['tone'] ?? 'patient',
            'generated_at' => now(),
        ]);

        return response()->json(new AIInterpretationResource($interpretation), 201);
    }
}
