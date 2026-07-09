<?php

namespace App\Http\Controllers\Organization;

use App\Http\Controllers\Controller;
use App\Http\Resources\OrganizationResource;
use App\Models\Organization;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class OrganizationController extends Controller
{
    public function index(): JsonResponse
    {
        return ApiResponse::success([
            'organizations' => OrganizationResource::collection(Organization::query()->orderBy('name')->get()),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'slug' => ['nullable', 'string', 'max:255', 'unique:organizations,slug'],
            'type' => ['nullable', 'string', 'max:80'],
            'timezone' => ['nullable', 'string', 'max:80'],
        ]);

        $organization = Organization::query()->create([
            'name' => $data['name'],
            'slug' => $data['slug'] ?? Str::slug($data['name']),
            'type' => $data['type'] ?? 'clinic',
            'timezone' => $data['timezone'] ?? 'Asia/Kolkata',
        ]);

        return response()->json(new OrganizationResource($organization), 201);
    }

    public function show(Organization $organization): JsonResponse
    {
        return response()->json(new OrganizationResource($organization));
    }

    public function update(Request $request, Organization $organization): JsonResponse
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'type' => ['nullable', 'string', 'max:80'],
            'timezone' => ['nullable', 'string', 'max:80'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $organization->update($data);

        return response()->json(new OrganizationResource($organization->refresh()));
    }

    public function destroy(Organization $organization): JsonResponse
    {
        $organization->delete();

        return ApiResponse::success(message: 'Organization deleted.');
    }
}
