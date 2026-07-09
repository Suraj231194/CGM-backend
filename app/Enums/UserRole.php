<?php

namespace App\Enums;

enum UserRole: string
{
    case CUSTOMER = 'customer';
    case DOCTOR = 'doctor';
    case ADMIN = 'admin';

    /**
     * @return array<int, string>
     */
    public function abilities(): array
    {
        return match ($this) {
            self::ADMIN => ['*'],
            self::DOCTOR => [
                'patients:read',
                'patients:write',
                'readings:read',
                'alerts:read',
                'alerts:write',
                'reports:read',
                'notes:write',
                'tasks:write',
                'devices:read',
                'organizations:read',
            ],
            self::CUSTOMER => [
                'profile:read',
                'readings:read',
                'readings:write',
                'alerts:read',
                'alerts:write',
                'meals:write',
                'reports:write',
                'devices:write',
                'orders:write',
                'consents:write',
            ],
        };
    }

    public function can(string $ability): bool
    {
        $abilities = $this->abilities();

        return in_array('*', $abilities, true) || in_array($ability, $abilities, true);
    }
}
