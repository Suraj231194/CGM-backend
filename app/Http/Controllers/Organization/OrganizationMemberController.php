<?php

namespace App\Http\Controllers\Organization;

use App\Http\Controllers\Controller;
use App\Models\Organization;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrganizationMemberController extends Controller
{
    public function index(Organization $organization): JsonResponse
    {
        return ApiResponse::success([
            'members' => $organization->members()->with('user:id,name,email,role,phone')->get(),
        ]);
    }

    public function store(Request $request, Organization $organization): JsonResponse
    {
        $data = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
            'role' => ['nullable', 'string', 'max:80'],
        ]);

        $member = $organization->members()->updateOrCreate(
            ['user_id' => $data['user_id']],
            [
                'role' => $data['role'] ?? 'member',
                'joined_at' => now(),
            ],
        );

        return ApiResponse::success(['member' => $member->load('user:id,name,email,role,phone')], status: 201);
    }

    public function destroy(Organization $organization, int $member): JsonResponse
    {
        $organization->members()->whereKey($member)->delete();

        return ApiResponse::success(message: 'Member removed.');
    }
}
