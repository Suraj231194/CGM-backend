<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConsentRecordResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'healthData' => (bool) $this->health_data,
            'sensorData' => (bool) $this->sensor_data,
            'aiCoaching' => (bool) $this->ai_coaching,
            'reportSharing' => (bool) $this->report_sharing,
            'termsAccepted' => (bool) $this->terms_accepted,
            'status' => $this->status,
            'consentedAt' => $this->consented_at?->toISOString(),
        ];
    }
}
