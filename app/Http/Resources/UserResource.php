<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'name' => $this->name,
            'role' => $this->role?->value ?? $this->role,
            'email' => $this->email,
            'phone' => $this->phone ?? '',
            'permissions' => $this->tokenAbilities(),
            'isActive' => (bool) $this->is_active,
            'lastLoginAt' => $this->last_login_at?->toISOString(),
        ];
    }
}
