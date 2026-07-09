<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ConsentRecord extends Model
{
    protected $fillable = [
        'patient_id',
        'user_id',
        'health_data',
        'sensor_data',
        'ai_coaching',
        'report_sharing',
        'terms_accepted',
        'status',
        'consented_at',
    ];

    protected function casts(): array
    {
        return [
            'health_data' => 'boolean',
            'sensor_data' => 'boolean',
            'ai_coaching' => 'boolean',
            'report_sharing' => 'boolean',
            'terms_accepted' => 'boolean',
            'consented_at' => 'datetime',
        ];
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(PatientProfile::class, 'patient_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
