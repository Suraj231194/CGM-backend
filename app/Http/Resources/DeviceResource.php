<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeviceResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'serialNumber' => $this->serial_number,
            'patientId' => $this->patient_id ? (string) $this->patient_id : '',
            'status' => $this->status,
            'batteryStatus' => (int) $this->battery_status,
            'connectionStatus' => $this->connection_status,
            'activationDate' => $this->activation_date?->toISOString(),
            'expiryDate' => $this->expiry_date?->toISOString(),
            'warmupStartTime' => $this->warmup_start_time?->toISOString(),
            'warmupEndTime' => $this->warmup_end_time?->toISOString(),
            'lastSyncAt' => $this->last_sync_at?->toISOString(),
            'model' => $this->model,
            'manufacturer' => $this->manufacturer,
        ];
    }
}
