<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PatientProfileResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $sensorId = $this->relationLoaded('latestDevice')
            ? $this->latestDevice?->id
            : $this->devices()->latest()->value('id');

        return [
            'id' => (string) $this->id,
            'userId' => $this->user_id ? (string) $this->user_id : null,
            'name' => $this->name,
            'age' => (int) ($this->age ?? $this->date_of_birth?->age ?? 0),
            'gender' => $this->gender ?? '',
            'doctorId' => $this->doctor_id ? (string) $this->doctor_id : '',
            'sensorId' => $sensorId ? (string) $sensorId : '',
            'riskLevel' => $this->risk_level,
            'phone' => $this->phone,
            'preferredUnit' => $this->preferred_unit,
            'medicalRecordNumber' => $this->medical_record_number,
        ];
    }
}
