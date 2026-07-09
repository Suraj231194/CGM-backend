<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Device extends Model
{
    protected $fillable = [
        'patient_id',
        'serial_number',
        'model',
        'manufacturer',
        'status',
        'battery_status',
        'connection_status',
        'activation_date',
        'expiry_date',
        'warmup_start_time',
        'warmup_end_time',
        'last_sync_at',
        'metadata',
    ];

    protected function casts(): array
    {
        return [
            'battery_status' => 'integer',
            'activation_date' => 'datetime',
            'expiry_date' => 'datetime',
            'warmup_start_time' => 'datetime',
            'warmup_end_time' => 'datetime',
            'last_sync_at' => 'datetime',
            'metadata' => 'array',
        ];
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(PatientProfile::class, 'patient_id');
    }

    public function sessions(): HasMany
    {
        return $this->hasMany(SensorSession::class);
    }

    public function activeSession(): HasOne
    {
        return $this->hasOne(SensorSession::class)->latestOfMany();
    }

    public function readings(): HasMany
    {
        return $this->hasMany(GlucoseReading::class);
    }
}
