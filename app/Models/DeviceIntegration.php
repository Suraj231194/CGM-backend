<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeviceIntegration extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'name',
        'provider',
        'category',
        'status',
        'summary',
        'last_sync_at',
    ];

    protected function casts(): array
    {
        return [
            'last_sync_at' => 'datetime',
        ];
    }
}
