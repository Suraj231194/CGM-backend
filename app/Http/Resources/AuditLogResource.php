<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AuditLogResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'actorId' => $this->actor_id ? (string) $this->actor_id : '',
            'actorRole' => $this->actor_role ?? '',
            'action' => $this->action,
            'targetId' => $this->target_id ?? '',
            'targetType' => $this->target_type ?? '',
            'timestamp' => $this->created_at?->toISOString(),
            'details' => $this->details ?? '',
        ];
    }
}
