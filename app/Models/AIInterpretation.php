<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AIInterpretation extends Model
{
    protected $table = 'ai_interpretations';

    protected $fillable = [
        'patient_id',
        'period',
        'summary',
        'patterns',
        'recommendations',
        'disclaimer',
        'tone',
        'generated_at',
    ];

    protected function casts(): array
    {
        return [
            'patterns' => 'array',
            'recommendations' => 'array',
            'generated_at' => 'datetime',
        ];
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(PatientProfile::class, 'patient_id');
    }
}
