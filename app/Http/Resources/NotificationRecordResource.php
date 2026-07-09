<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationRecordResource extends JsonResource
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
            'type' => $this->type,
            'delivered' => (bool) $this->delivered,
            'route' => $this->route,
        ];
    }
}
