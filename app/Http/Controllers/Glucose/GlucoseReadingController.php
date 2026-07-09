<?php

namespace App\Http\Controllers\Glucose;

use App\Http\Controllers\Controller;
use App\Http\Resources\GlucoseReadingResource;
use App\Models\PatientProfile;
use App\Services\Glucose\GlucoseIngestionService;
use App\Support\ApiResponse;
use App\Support\DateRange;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

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
        $data = $request->validate([
            'readings' => ['required', 'array', 'min:1', 'max:1000'],
            'readings.*.value' => ['required', 'integer', 'min:20', 'max:600'],
            'readings.*.timestamp' => ['required', 'date'],
            'readings.*.sensorId' => ['nullable', 'exists:devices,id'],
            'readings.*.device_id' => ['nullable', 'exists:devices,id'],
            'readings.*.trend' => ['nullable', 'string'],
            'readings.*.unit' => ['nullable', 'string', 'max:20'],
            'readings.*.source' => ['nullable', 'string', 'max:40'],
        ]);

        $readings = collect($data['readings'])
            ->map(fn (array $payload) => $this->ingestion->ingest($patient, $this->normalizeReadingPayload($payload)));

        return ApiResponse::success([
            'readings' => GlucoseReadingResource::collection($readings),
        ], status: 201);
    }

    /**
     * @return array<string, mixed>
     */
    private function validatedReading(Request $request): array
    {
        $data = $request->validate([
            'value' => ['required', 'integer', 'min:20', 'max:600'],
            'timestamp' => ['nullable', 'date'],
            'sensorId' => ['nullable', 'exists:devices,id'],
            'device_id' => ['nullable', 'exists:devices,id'],
            'sensor_session_id' => ['nullable', 'exists:sensor_sessions,id'],
            'trend' => ['nullable', 'string'],
            'status' => ['nullable', 'in:low,normal,high'],
            'unit' => ['nullable', 'string', 'max:20'],
            'source' => ['nullable', 'string', 'max:40'],
            'raw_payload' => ['nullable', 'array'],
        ]);

        return $this->normalizeReadingPayload($data);
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

        return $payload;
    }
}
