<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MealLog extends Model
{
    protected $fillable = [
        'patient_id',
        'timestamp',
        'type',
        'title',
        'net_carbs',
        'protein',
        'fiber',
        'activity_minutes',
        'score',
        'note',
    ];

    protected function casts(): array
    {
        return [
            'timestamp' => 'datetime',
            'net_carbs' => 'integer',
            'protein' => 'integer',
            'fiber' => 'integer',
            'activity_minutes' => 'integer',
            'score' => 'integer',
        ];
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(PatientProfile::class, 'patient_id');
    }
}
