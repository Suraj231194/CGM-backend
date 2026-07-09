<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class PatientProfile extends Model
{
    protected $fillable = [
        'user_id',
        'doctor_id',
        'organization_id',
        'name',
        'date_of_birth',
        'age',
        'gender',
        'phone',
        'risk_level',
        'medical_record_number',
        'diagnosis_notes',
        'emergency_contact_name',
        'emergency_contact_phone',
        'preferred_unit',
    ];

    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'age' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function doctor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function devices(): HasMany
    {
        return $this->hasMany(Device::class, 'patient_id');
    }

    public function readings(): HasMany
    {
        return $this->hasMany(GlucoseReading::class, 'patient_id');
    }

    public function sensorSessions(): HasMany
    {
        return $this->hasMany(SensorSession::class, 'patient_id');
    }

    public function meals(): HasMany
    {
        return $this->hasMany(MealLog::class, 'patient_id');
    }

    public function alerts(): HasMany
    {
        return $this->hasMany(GlucoseAlert::class, 'patient_id');
    }

    public function alertSetting(): HasOne
    {
        return $this->hasOne(AlertSetting::class, 'patient_id');
    }

    public function reports(): HasMany
    {
        return $this->hasMany(ReportExport::class, 'patient_id');
    }

    public function orders(): HasMany
    {
        return $this->hasMany(SensorOrder::class, 'patient_id');
    }

    public function aiInterpretations(): HasMany
    {
        return $this->hasMany(AIInterpretation::class, 'patient_id');
    }

    public function dataGrants(): HasMany
    {
        return $this->hasMany(PatientDataGrant::class, 'patient_id');
    }

    public function consentRecords(): HasMany
    {
        return $this->hasMany(ConsentRecord::class, 'patient_id');
    }

    public function clinicianNotes(): HasMany
    {
        return $this->hasMany(ClinicianNote::class, 'patient_id');
    }

    public function careTasks(): HasMany
    {
        return $this->hasMany(CareTask::class, 'patient_id');
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(NotificationRecord::class, 'patient_id');
    }

    public function latestDevice(): HasOne
    {
        return $this->hasOne(Device::class, 'patient_id')->latestOfMany();
    }
}
