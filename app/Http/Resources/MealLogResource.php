<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MealLogResource extends JsonResource
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
            'type' => $this->type,
            'title' => $this->title,
            'netCarbs' => (int) $this->net_carbs,
            'protein' => (int) $this->protein,
            'fiber' => (int) $this->fiber,
            'activityMinutes' => (int) $this->activity_minutes,
            'score' => (int) $this->score,
            'note' => $this->note ?? '',
        ];
    }
}
