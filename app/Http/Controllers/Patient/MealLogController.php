<?php

namespace App\Http\Controllers\Patient;

use App\Http\Controllers\Controller;
use App\Http\Resources\MealLogResource;
use App\Models\PatientProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MealLogController extends Controller
{
    public function index(PatientProfile $patient): JsonResponse
    {
        return ApiResponse::success([
            'meals' => MealLogResource::collection($patient->meals()->latest('timestamp')->get()),
        ]);
    }

    public function store(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'timestamp' => ['nullable', 'date'],
            'type' => ['required', 'in:breakfast,lunch,dinner,snack'],
            'title' => ['required', 'string', 'max:255'],
            'netCarbs' => ['nullable', 'integer', 'min:0', 'max:500'],
            'protein' => ['nullable', 'integer', 'min:0', 'max:500'],
            'fiber' => ['nullable', 'integer', 'min:0', 'max:500'],
            'activityMinutes' => ['nullable', 'integer', 'min:0', 'max:1440'],
            'score' => ['nullable', 'integer', 'min:0', 'max:100'],
            'note' => ['nullable', 'string', 'max:2000'],
        ]);

        $meal = $patient->meals()->create([
            'timestamp' => $data['timestamp'] ?? now(),
            'type' => $data['type'],
            'title' => $data['title'],
            'net_carbs' => $data['netCarbs'] ?? 0,
            'protein' => $data['protein'] ?? 0,
            'fiber' => $data['fiber'] ?? 0,
            'activity_minutes' => $data['activityMinutes'] ?? 0,
            'score' => $data['score'] ?? $this->score($data),
            'note' => $data['note'] ?? '',
        ]);

        return response()->json(new MealLogResource($meal), 201);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function score(array $data): int
    {
        $carbs = (int) ($data['netCarbs'] ?? 0);
        $protein = (int) ($data['protein'] ?? 0);
        $fiber = (int) ($data['fiber'] ?? 0);
        $activity = (int) ($data['activityMinutes'] ?? 0);

        return max(0, min(100, 100 - max(0, $carbs - 35) + min(20, $protein) + min(15, $fiber * 2) + min(15, $activity)));
    }
}
