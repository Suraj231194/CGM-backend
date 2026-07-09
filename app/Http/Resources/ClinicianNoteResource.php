<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ClinicianNoteResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'patientId' => (string) $this->patient_id,
            'authorId' => $this->author_id ? (string) $this->author_id : '',
            'authorName' => $this->author?->name ?? 'Clinician',
            'createdAt' => $this->created_at?->toISOString(),
            'note' => $this->note,
        ];
    }
}
