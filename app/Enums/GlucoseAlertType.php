<?php

namespace App\Enums;

enum GlucoseAlertType: string
{
    case LOW = 'low';
    case HIGH = 'high';
    case RAPID_CHANGE = 'rapid_change';
    case SENSOR_EXPIRY = 'sensor_expiry';
    case STALE_READING = 'stale_reading';
    case SENSOR_STATUS = 'sensor_status';
}
