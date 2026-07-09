<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AlertSettingResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'notificationsEnabled' => (bool) $this->notifications_enabled,
            'lowThreshold' => (int) $this->low_threshold,
            'highThreshold' => (int) $this->high_threshold,
            'quietHoursEnabled' => (bool) $this->quiet_hours_enabled,
            'sensorDisconnectReminderMinutes' => (int) $this->sensor_disconnect_reminder_minutes,
        ];
    }
}
