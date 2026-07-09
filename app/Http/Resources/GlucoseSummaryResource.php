<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GlucoseSummaryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'patientId' => (string) $this->patient_id,
            'date' => $this->summary_date?->toDateString(),
            'average' => (int) $this->average,
            'minimum' => (int) $this->minimum,
            'maximum' => (int) $this->maximum,
            'timeInRange' => (int) $this->time_in_range,
            'highCount' => (int) $this->high_count,
            'lowCount' => (int) $this->low_count,
            'readingCount' => (int) $this->reading_count,
            'estimatedA1c' => $this->estimated_a1c,
        ];
    }
}
