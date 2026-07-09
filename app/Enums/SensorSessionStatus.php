<?php

namespace App\Enums;

enum SensorSessionStatus: string
{
    case PENDING = 'pending';
    case WARMING_UP = 'warmingUp';
    case ACTIVE = 'active';
    case COMPLETED = 'completed';
    case EXPIRED = 'expired';
    case FAILED = 'failed';
}
