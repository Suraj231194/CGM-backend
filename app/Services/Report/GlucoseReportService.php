<?php

namespace App\Services\Report;

use App\Models\PatientProfile;
use App\Models\ReportExport;
use App\Models\User;
use App\Services\Glucose\GlucoseSummaryService;
use Carbon\CarbonImmutable;

class GlucoseReportService
{
    public function __construct(private readonly GlucoseSummaryService $summaries) {}

    public function generate(PatientProfile $patient, User $creator, string $period, string $format): ReportExport
    {
        $days = $this->periodDays($period);
        $end = CarbonImmutable::now();
        $start = $end->subDays($days);
        $summary = $this->summaries->summarize($patient, $start, $end);

        return ReportExport::query()->create([
            'patient_id' => $patient->id,
            'created_by' => $creator->id,
            'period' => $period,
            'format' => strtoupper($format),
            'status' => 'ready',
            'summary' => "{$summary['timeInRange']}% time in range, {$summary['average']} mg/dL average, {$summary['readingCount']} reading(s).",
            'date_range_start' => $start,
            'date_range_end' => $end,
            'generated_at' => $end,
        ]);
    }

    private function periodDays(string $period): int
    {
        $normalized = strtolower(trim($period));

        return match (true) {
            str_contains($normalized, '30') => 30,
            str_contains($normalized, '14') => 14,
            str_contains($normalized, '7') => 7,
            str_contains($normalized, '90') => 90,
            default => 14,
        };
    }
}
