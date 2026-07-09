<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CareTaskResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'patientId' => (string) $this->patient_id,
            'title' => $this->title,
            'ownerRole' => $this->owner_role,
            'status' => $this->status,
            'priority' => $this->priority,
            'createdAt' => $this->created_at?->toISOString(),
            'dueAt' => $this->due_at?->toISOString(),
            'completedAt' => $this->completed_at?->toISOString(),
        ];
    }
}
