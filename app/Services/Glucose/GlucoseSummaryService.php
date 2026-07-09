<?php

namespace App\Services\Glucose;

use App\Models\DailyGlucoseSummary;
use App\Models\GlucoseReading;
use App\Models\PatientProfile;
use Carbon\CarbonInterface;
use Illuminate\Support\Collection;

class GlucoseSummaryService
{
    /**
     * @return array<string, int|float|null>
     */
    public function summarize(PatientProfile $patient, ?CarbonInterface $from = null, ?CarbonInterface $to = null): array
    {
        $query = $patient->readings();

        if ($from) {
            $query->where('timestamp', '>=', $from);
        }

        if ($to) {
            $query->where('timestamp', '<=', $to);
        }

        return $this->summarizeReadings($query->orderBy('timestamp')->get());
    }

    /**
     * @param  Collection<int, GlucoseReading>  $readings
     * @return array<string, int|float|null>
     */
    public function summarizeReadings(Collection $readings): array
    {
        $count = $readings->count();

        if ($count === 0) {
            return [
                'average' => 0,
                'minimum' => 0,
                'maximum' => 0,
                'timeInRange' => 0,
                'highCount' => 0,
                'lowCount' => 0,
                'readingCount' => 0,
                'estimatedA1c' => null,
            ];
        }

        $values = $readings->pluck('value');
        $inRange = $readings->whereBetween('value', [70, 180])->count();
        $average = (int) round((float) $values->avg());

        return [
            'average' => $average,
            'minimum' => (int) $values->min(),
            'maximum' => (int) $values->max(),
            'timeInRange' => (int) round(($inRange / $count) * 100),
            'highCount' => $readings->where('value', '>', 180)->count(),
            'lowCount' => $readings->where('value', '<', 70)->count(),
            'readingCount' => $count,
            'estimatedA1c' => round(($average + 46.7) / 28.7, 2),
        ];
    }

    public function persistDaily(PatientProfile $patient, CarbonInterface $date): DailyGlucoseSummary
    {
        $start = $date->copy()->startOfDay();
        $end = $date->copy()->endOfDay();
        $summary = $this->summarize($patient, $start, $end);

        return DailyGlucoseSummary::query()->updateOrCreate(
            [
                'patient_id' => $patient->id,
                'summary_date' => $date->toDateString(),
            ],
            [
                'average' => $summary['average'],
                'minimum' => $summary['minimum'],
                'maximum' => $summary['maximum'],
                'time_in_range' => $summary['timeInRange'],
                'high_count' => $summary['highCount'],
                'low_count' => $summary['lowCount'],
                'reading_count' => $summary['readingCount'],
                'estimated_a1c' => $summary['estimatedA1c'],
            ],
        );
    }
}
