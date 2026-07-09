<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SensorOrderResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'patientId' => (string) $this->patient_id,
            'productName' => $this->product_name,
            'quantity' => (int) $this->quantity,
            'status' => $this->status,
            'shippingAddress' => $this->shipping_address,
            'createdAt' => $this->created_at?->toISOString(),
            'trackingNumber' => $this->tracking_number,
        ];
    }
}
