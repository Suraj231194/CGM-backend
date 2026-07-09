<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AlertSetting extends Model
{
    protected $fillable = [
        'patient_id',
        'notifications_enabled',
        'low_threshold',
        'high_threshold',
        'quiet_hours_enabled',
        'sensor_disconnect_reminder_minutes',
    ];

    protected function casts(): array
    {
        return [
            'notifications_enabled' => 'boolean',
            'low_threshold' => 'integer',
            'high_threshold' => 'integer',
            'quiet_hours_enabled' => 'boolean',
            'sensor_disconnect_reminder_minutes' => 'integer',
        ];
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(PatientProfile::class, 'patient_id');
    }
}
