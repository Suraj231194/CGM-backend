<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GlucoseAlert extends Model
{
    protected $fillable = [
        'patient_id',
        'glucose_reading_id',
        'alert_type',
        'severity',
        'title',
        'message',
        'value',
        'threshold',
        'acknowledged',
        'acknowledged_by',
        'acknowledged_at',
        'timestamp',
    ];

    protected function casts(): array
    {
        return [
            'value' => 'integer',
            'threshold' => 'integer',
            'acknowledged' => 'boolean',
            'acknowledged_at' => 'datetime',
            'timestamp' => 'datetime',
        ];
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(PatientProfile::class, 'patient_id');
    }

    public function reading(): BelongsTo
    {
        return $this->belongsTo(GlucoseReading::class, 'glucose_reading_id');
    }

    public function acknowledgedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'acknowledged_by');
    }
}
