<?php

namespace App\Http\Controllers\Patient;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Resources\PatientProfileResource;
use App\Models\PatientProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PatientProfileController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = PatientProfile::query()->with('latestDevice');

        if ($user->hasRole(UserRole::CUSTOMER)) {
            $query->where('user_id', $user->id);
        } elseif ($user->hasRole(UserRole::DOCTOR)) {
            $query->where(function ($query) use ($user): void {
                $query->where('doctor_id', $user->id)
                    ->orWhereHas('dataGrants', function ($grant) use ($user): void {
                        $grant->where('doctor_id', $user->id)
                            ->where('status', 'accepted')
                            ->where(fn ($q) => $q->whereNull('expires_at')->orWhere('expires_at', '>', now()));
                    });
            });
        }

        if ($request->filled('doctorId')) {
            $query->where('doctor_id', $request->query('doctorId'));
        }

        return ApiResponse::success([
            'patients' => PatientProfileResource::collection($query->orderBy('name')->get()),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'user_id' => ['nullable', 'exists:users,id'],
            'doctor_id' => ['nullable', 'exists:users,id'],
            'organization_id' => ['nullable', 'exists:organizations,id'],
            'name' => ['required', 'string', 'max:255'],
            'date_of_birth' => ['nullable', 'date'],
            'age' => ['nullable', 'integer', 'min:0', 'max:130'],
            'gender' => ['nullable', 'string', 'max:40'],
            'phone' => ['nullable', 'string', 'max:40'],
            'risk_level' => ['nullable', 'in:stable,watch,urgent'],
            'medical_record_number' => ['nullable', 'string', 'max:80'],
            'diagnosis_notes' => ['nullable', 'string'],
        ]);

        $patient = PatientProfile::query()->create($data);
        $patient->alertSetting()->create();

        return response()->json(new PatientProfileResource($patient->load('latestDevice')), 201);
    }

    public function show(PatientProfile $patient): JsonResponse
    {
        return response()->json(new PatientProfileResource($patient->load('latestDevice')));
    }

    public function update(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'doctor_id' => ['nullable', 'exists:users,id'],
            'organization_id' => ['nullable', 'exists:organizations,id'],
            'name' => ['sometimes', 'string', 'max:255'],
            'date_of_birth' => ['nullable', 'date'],
            'age' => ['nullable', 'integer', 'min:0', 'max:130'],
            'gender' => ['nullable', 'string', 'max:40'],
            'phone' => ['nullable', 'string', 'max:40'],
            'risk_level' => ['nullable', 'in:stable,watch,urgent'],
            'medical_record_number' => ['nullable', 'string', 'max:80'],
            'diagnosis_notes' => ['nullable', 'string'],
            'preferred_unit' => ['nullable', 'string', 'max:20'],
        ]);

        $patient->update($data);

        return response()->json(new PatientProfileResource($patient->refresh()->load('latestDevice')));
    }
}
