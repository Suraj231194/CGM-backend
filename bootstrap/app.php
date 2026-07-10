<?php

use App\Http\Middleware\BypassAuth;
use App\Http\Middleware\EnsureDoctorAccess;
use App\Http\Middleware\EnsureOrganizationAccess;
use App\Http\Middleware\EnsurePatientAccess;
use App\Http\Middleware\EnsureRole;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $aliases = [
            'doctor' => EnsureDoctorAccess::class,
            'organization.access' => EnsureOrganizationAccess::class,
            'patient.access' => EnsurePatientAccess::class,
            'role' => EnsureRole::class,
        ];

        if (env('AUTH_BYPASS', false) && env('APP_ENV') !== 'testing') {
            $aliases['auth'] = BypassAuth::class;
        }

        $middleware->alias($aliases);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );
    })->create();
