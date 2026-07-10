<?php

namespace App\Http\Controllers\Glucose;

use App\Http\Controllers\Controller;
use App\Http\Resources\GlucoseReadingResource;
use App\Models\PatientProfile;
use App\Models\SensorSession;
use App\Services\Glucose\GlucoseIngestionService;
use App\Support\ApiResponse;
use App\Support\DateRange;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class GlucoseReadingController extends Controller
{
    public function __construct(private readonly GlucoseIngestionService $ingestion) {}

    public function index(Request $request, PatientProfile $patient): JsonResponse
    {
        $range = DateRange::fromRequest($request);
        $query = $patient->readings()
            ->when($range->from, fn ($query) => $query->where('timestamp', '>=', $range->from))
            ->when($range->to, fn ($query) => $query->where('timestamp', '<=', $range->to))
            ->orderByDesc('timestamp');

        if ($request->filled('offset')) {
            $query->offset((int) $request->query('offset'));
        }

        $query->limit(max(1, min((int) $request->query('limit', 288), 1000)));

        return ApiResponse::success([
            'readings' => GlucoseReadingResource::collection($query->get()),
        ]);
    }

    public function store(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $this->validatedReading($request);
        $reading = $this->ingestion->ingest($patient, $data);

        return response()->json(new GlucoseReadingResource($reading), 201);
    }

    public function bulkStore(Request $request, PatientProfile $patient): JsonResponse
    {
        $deviceForPatient = Rule::exists('devices', 'id')
            ->where(fn ($query) => $query->where('patient_id', $patient->id));
        $sessionForPatient = Rule::exists('sensor_sessions', 'id')
            ->where(fn ($query) => $query->where('patient_id', $patient->id));

        $data = $request->validate([
            'readings' => ['required', 'array', 'min:1', 'max:1000'],
            'readings.*.value' => ['required', 'integer', 'min:20', 'max:600'],
            'readings.*.timestamp' => ['required', 'date'],
            'readings.*.sensorId' => ['nullable', $deviceForPatient],
            'readings.*.device_id' => ['nullable', $deviceForPatient],
            'readings.*.clientReadingId' => ['nullable', 'string', 'max:190'],
            'readings.*.client_reading_id' => ['nullable', 'string', 'max:190'],
            'readings.*.sensor_session_id' => ['nullable', $sessionForPatient],
            'readings.*.trend' => ['nullable', 'string'],
            'readings.*.unit' => ['nullable', 'string', 'max:20'],
            'readings.*.source' => ['nullable', 'string', 'max:40'],
        ]);

        foreach ($data['readings'] as $index => $payload) {
            if (($payload['source'] ?? null) === 'sdk'
                && empty($payload['clientReadingId'])
                && empty($payload['client_reading_id'])) {
                throw ValidationException::withMessages([
                    "readings.{$index}.clientReadingId" => 'A stable client reading ID is required for SDK data.',
                ]);
            }

            $data['readings'][$index] = $this->normalizeAndValidateSessionDevice(
                $payload,
                $patient,
                "readings.{$index}.",
            );
        }

        $readings = collect($data['readings'])
            ->map(fn (array $payload) => $this->ingestion->ingest($patient, $payload));

        return ApiResponse::success([
            'readings' => GlucoseReadingResource::collection($readings),
        ], status: 201);
    }

    /**
     * @return array<string, mixed>
     */
    private function validatedReading(Request $request): array
    {
        /** @var PatientProfile $patient */
        $patient = $request->route('patient');
        $deviceForPatient = Rule::exists('devices', 'id')
            ->where(fn ($query) => $query->where('patient_id', $patient->id));
        $sessionForPatient = Rule::exists('sensor_sessions', 'id')
            ->where(fn ($query) => $query->where('patient_id', $patient->id));

        $data = $request->validate([
            'value' => ['required', 'integer', 'min:20', 'max:600'],
            'timestamp' => ['nullable', 'date'],
            'sensorId' => ['nullable', $deviceForPatient],
            'device_id' => ['nullable', $deviceForPatient],
            'clientReadingId' => ['nullable', 'string', 'max:190'],
            'client_reading_id' => ['nullable', 'string', 'max:190'],
            'sensor_session_id' => ['nullable', $sessionForPatient],
            'trend' => ['nullable', 'string'],
            'status' => ['nullable', 'in:low,normal,high'],
            'unit' => ['nullable', 'string', 'max:20'],
            'source' => ['nullable', 'string', 'max:40'],
            'raw_payload' => ['nullable', 'array'],
        ]);

        if (($data['source'] ?? null) === 'sdk'
            && empty($data['clientReadingId'])
            && empty($data['client_reading_id'])) {
            throw ValidationException::withMessages([
                'clientReadingId' => 'A stable client reading ID is required for SDK data.',
            ]);
        }

        return $this->normalizeAndValidateSessionDevice($data, $patient);
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function normalizeReadingPayload(array $payload): array
    {
        if (isset($payload['sensorId']) && ! isset($payload['device_id'])) {
            $payload['device_id'] = $payload['sensorId'];
        }

        if (isset($payload['clientReadingId']) && ! isset($payload['client_reading_id'])) {
            $payload['client_reading_id'] = $payload['clientReadingId'];
        }

        return $payload;
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function normalizeAndValidateSessionDevice(
        array $payload,
        PatientProfile $patient,
        string $errorPrefix = '',
    ): array {
        $payload = $this->normalizeReadingPayload($payload);
        $sessionId = $payload['sensor_session_id'] ?? null;
        if (! $sessionId) {
            return $payload;
        }

        $session = SensorSession::query()
            ->whereKey($sessionId)
            ->where('patient_id', $patient->id)
            ->first();

        if (! $session) {
            return $payload;
        }

        $deviceId = $payload['device_id'] ?? null;
        if ($deviceId !== null && (int) $deviceId !== (int) $session->device_id) {
            throw ValidationException::withMessages([
                "{$errorPrefix}sensor_session_id" => 'The sensor session does not belong to the supplied device.',
            ]);
        }

        $payload['device_id'] = $session->device_id;

        return $payload;
    }
}
