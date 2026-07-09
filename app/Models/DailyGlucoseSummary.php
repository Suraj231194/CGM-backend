<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DailyGlucoseSummary extends Model
{
    protected $fillable = [
        'patient_id',
        'summary_date',
        'average',
        'minimum',
        'maximum',
        'time_in_range',
        'high_count',
        'low_count',
        'reading_count',
        'estimated_a1c',
    ];

    protected function casts(): array
    {
        return [
            'summary_date' => 'date',
            'average' => 'integer',
            'minimum' => 'integer',
            'maximum' => 'integer',
            'time_in_range' => 'integer',
            'high_count' => 'integer',
            'low_count' => 'integer',
            'reading_count' => 'integer',
            'estimated_a1c' => 'decimal:2',
        ];
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(PatientProfile::class, 'patient_id');
    }
}
