<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AIInterpretationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'patientId' => (string) $this->patient_id,
            'period' => $this->period,
            'summary' => $this->summary,
            'patterns' => $this->patterns ?? [],
            'recommendations' => $this->recommendations ?? [],
            'disclaimer' => $this->disclaimer ?? 'AI insights are informational and do not replace clinician guidance.',
            'tone' => $this->tone,
        ];
    }
}
