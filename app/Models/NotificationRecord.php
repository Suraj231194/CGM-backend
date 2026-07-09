<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationRecord extends Model
{
    protected $fillable = [
        'patient_id',
        'timestamp',
        'title',
        'message',
        'type',
        'delivered',
        'route',
    ];

    protected function casts(): array
    {
        return [
            'timestamp' => 'datetime',
            'delivered' => 'boolean',
        ];
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(PatientProfile::class, 'patient_id');
    }
}
