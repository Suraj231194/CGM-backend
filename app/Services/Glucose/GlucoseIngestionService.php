<?php

namespace App\Services\Glucose;

use App\Models\GlucoseReading;
use App\Models\PatientProfile;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

class GlucoseIngestionService
{
    public function __construct(private readonly GlucoseAlertService $alerts) {}

    /**
     * @param  array<string, mixed>  $payload
     */
    public function ingest(PatientProfile $patient, array $payload): GlucoseReading
    {
        $values = [
            'device_id' => $payload['device_id'] ?? $payload['sensor_id'] ?? null,
            'client_reading_id' => $payload['client_reading_id'] ?? null,
            'sensor_session_id' => $payload['sensor_session_id'] ?? null,
            'timestamp' => $payload['timestamp'] ?? now(),
            'value' => $payload['value'],
            'unit' => $payload['unit'] ?? 'mg/dL',
            'trend' => $payload['trend'] ?? 'steady',
            'status' => $payload['status'] ?? GlucoseReading::statusForValue((int) $payload['value']),
            'source' => $payload['source'] ?? 'mobile',
            'raw_payload' => $payload['raw_payload'] ?? null,
        ];

        return DB::transaction(function () use ($patient, $values): GlucoseReading {
            $clientReadingId = $values['client_reading_id'];
            try {
                $reading = $clientReadingId
                    ? $patient->readings()->firstOrCreate(
                        ['client_reading_id' => $clientReadingId],
                        $values,
                    )
                    : $patient->readings()->create($values);
            } catch (QueryException $exception) {
                $reading = $clientReadingId
                    ? $patient->readings()->where('client_reading_id', $clientReadingId)->first()
                    : null;

                if (! $reading) {
                    throw $exception;
                }
            }

            if ($reading->wasRecentlyCreated) {
                $this->alerts->evaluateReading($reading->load('patient'));
            }

            return $reading;
        }, attempts: 3);
    }
}
