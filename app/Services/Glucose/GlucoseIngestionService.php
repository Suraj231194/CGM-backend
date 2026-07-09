<?php

namespace App\Services\Glucose;

use App\Models\GlucoseReading;
use App\Models\PatientProfile;

class GlucoseIngestionService
{
    public function __construct(private readonly GlucoseAlertService $alerts) {}

    /**
     * @param  array<string, mixed>  $payload
     */
    public function ingest(PatientProfile $patient, array $payload): GlucoseReading
    {
        $reading = $patient->readings()->create([
            'device_id' => $payload['device_id'] ?? $payload['sensor_id'] ?? null,
            'sensor_session_id' => $payload['sensor_session_id'] ?? null,
            'timestamp' => $payload['timestamp'] ?? now(),
            'value' => $payload['value'],
            'unit' => $payload['unit'] ?? 'mg/dL',
            'trend' => $payload['trend'] ?? 'steady',
            'status' => $payload['status'] ?? GlucoseReading::statusForValue((int) $payload['value']),
            'source' => $payload['source'] ?? 'mobile',
            'raw_payload' => $payload['raw_payload'] ?? null,
        ]);

        $this->alerts->evaluateReading($reading->load('patient'));

        return $reading;
    }
}
