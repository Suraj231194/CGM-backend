<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SensorSessionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'sensorId' => (string) $this->device_id,
            'patientId' => (string) $this->patient_id,
            'status' => $this->status,
            'startedAt' => $this->started_at?->toISOString(),
            'warmedUpAt' => $this->warmed_up_at?->toISOString(),
            'endedAt' => $this->ended_at?->toISOString(),
            'expiresAt' => $this->expires_at?->toISOString(),
            'notes' => $this->notes,
        ];
    }
}
