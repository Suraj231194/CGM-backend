<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GlucoseAlertResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'patientId' => (string) $this->patient_id,
            'timestamp' => $this->timestamp?->toISOString(),
            'title' => $this->title,
            'message' => $this->message,
            'value' => (int) $this->value,
            'threshold' => (int) $this->threshold,
            'severity' => $this->severity,
            'acknowledged' => (bool) $this->acknowledged,
            'type' => $this->alert_type,
        ];
    }
}
