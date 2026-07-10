<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class GlucoseReading extends Model
{
    protected $fillable = [
        'patient_id',
        'device_id',
        'client_reading_id',
        'sensor_session_id',
        'timestamp',
        'value',
        'unit',
        'trend',
        'status',
        'source',
        'raw_payload',
    ];

    protected function casts(): array
    {
        return [
            'timestamp' => 'datetime',
            'value' => 'integer',
            'raw_payload' => 'array',
        ];
    }

    protected static function booted(): void
    {
        static::saving(function (GlucoseReading $reading): void {
            $reading->status = $reading->status ?: self::statusForValue((int) $reading->value);
        });
    }

    public static function statusForValue(int $value): string
    {
        return match (true) {
            $value < 70 => 'low',
            $value > 180 => 'high',
            default => 'normal',
        };
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(PatientProfile::class, 'patient_id');
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }

    public function sensorSession(): BelongsTo
    {
        return $this->belongsTo(SensorSession::class);
    }

    public function alerts(): HasMany
    {
        return $this->hasMany(GlucoseAlert::class);
    }
}
