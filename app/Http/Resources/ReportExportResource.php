<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReportExportResource extends JsonResource
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
            'generatedAt' => ($this->generated_at ?? $this->created_at)?->toISOString(),
            'format' => $this->format,
            'status' => $this->status,
            'summary' => $this->summary,
            'filePath' => $this->file_path,
            'csvPath' => $this->csv_path,
            'shareLink' => $this->share_link,
            'dateRangeStart' => $this->date_range_start?->toISOString(),
            'dateRangeEnd' => $this->date_range_end?->toISOString(),
            'backendRecordId' => (string) $this->id,
        ];
    }
}
