<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReportExport extends Model
{
    protected $fillable = [
        'patient_id',
        'created_by',
        'period',
        'format',
        'status',
        'summary',
        'file_path',
        'csv_path',
        'share_link',
        'date_range_start',
        'date_range_end',
        'generated_at',
    ];

    protected function casts(): array
    {
        return [
            'date_range_start' => 'datetime',
            'date_range_end' => 'datetime',
            'generated_at' => 'datetime',
        ];
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(PatientProfile::class, 'patient_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
