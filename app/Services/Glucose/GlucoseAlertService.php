<?php

namespace App\Services\Glucose;

use App\Models\AlertSetting;
use App\Models\GlucoseAlert;
use App\Models\GlucoseReading;
use App\Models\NotificationRecord;
use App\Models\PatientProfile;

class GlucoseAlertService
{
    public function settingsFor(PatientProfile $patient): AlertSetting
    {
        return $patient->alertSetting()->firstOrCreate([], [
            'notifications_enabled' => true,
            'low_threshold' => 70,
            'high_threshold' => 180,
            'quiet_hours_enabled' => false,
            'sensor_disconnect_reminder_minutes' => 15,
        ]);
    }

    public function evaluateReading(GlucoseReading $reading): ?GlucoseAlert
    {
        $patient = $reading->patient;
        $settings = $this->settingsFor($patient);

        if (! $settings->notifications_enabled) {
            return null;
        }

        $value = (int) $reading->value;
        $isHigh = $value >= $settings->high_threshold;
        $isLow = $value <= $settings->low_threshold;

        if (! $isHigh && ! $isLow) {
            return null;
        }

        $urgentHigh = $value >= 250;
        $urgentLow = $value <= 55;
        $urgent = $urgentHigh || $urgentLow || $isLow;

        if ($settings->quiet_hours_enabled && $isHigh && ! $urgent && $this->isQuietHour($reading->timestamp)) {
            return null;
        }

        $alert = GlucoseAlert::query()->firstOrCreate(
            [
                'glucose_reading_id' => $reading->id,
                'alert_type' => $isHigh ? 'high' : 'low',
            ],
            [
                'patient_id' => $reading->patient_id,
                'severity' => $urgent ? 'urgent' : 'warning',
                'title' => $this->title($isHigh, $urgentHigh, $urgentLow),
                'message' => $this->message($isHigh, $urgentHigh, $settings),
                'value' => $value,
                'threshold' => $isHigh ? $settings->high_threshold : $settings->low_threshold,
                'timestamp' => $reading->timestamp,
            ],
        );

        NotificationRecord::query()->firstOrCreate(
            [
                'patient_id' => $reading->patient_id,
                'type' => 'glucose_alert',
                'timestamp' => $reading->timestamp,
                'title' => $alert->title,
            ],
            [
                'message' => $alert->message,
                'delivered' => true,
                'route' => '/alerts',
            ],
        );

        return $alert;
    }

    private function isQuietHour(mixed $timestamp): bool
    {
        $hour = $timestamp?->copy()->timezone(config('app.timezone'))->hour ?? now()->hour;

        return $hour >= 22 || $hour < 7;
    }

    private function title(bool $isHigh, bool $urgentHigh, bool $urgentLow): string
    {
        if ($isHigh) {
            return $urgentHigh ? 'Urgent high glucose alert' : 'High glucose alert';
        }

        return $urgentLow ? 'Urgent low glucose alert' : 'Low glucose alert';
    }

    private function message(bool $isHigh, bool $urgentHigh, AlertSetting $settings): string
    {
        if ($isHigh) {
            return $urgentHigh
                ? 'Glucose is very high. Follow your clinician-approved safety plan and confirm with a finger-prick meter if needed.'
                : "Glucose crossed {$settings->high_threshold} mg/dL. Review food, activity, and care-team guidance.";
        }

        return "Glucose dropped below {$settings->low_threshold} mg/dL. Follow your clinician-approved safety plan.";
    }
}
