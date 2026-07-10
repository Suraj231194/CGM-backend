<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GlucoseReadingResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'clientReadingId' => $this->client_reading_id,
            'sensorId' => $this->device_id ? (string) $this->device_id : '',
            'patientId' => (string) $this->patient_id,
            'timestamp' => $this->timestamp?->toISOString(),
            'value' => (int) $this->value,
            'unit' => $this->unit,
            'trend' => $this->trend,
            'status' => $this->status,
            'source' => $this->source,
        ];
    }
}
