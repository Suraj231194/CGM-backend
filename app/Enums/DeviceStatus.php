<?php

namespace App\Enums;

enum DeviceStatus: string
{
    case INACTIVE = 'inactive';
    case ATTACHED = 'attached';
    case CONNECTING = 'connecting';
    case WARMING_UP = 'warmingUp';
    case ACTIVE = 'active';
    case EXPIRED = 'expired';
}
