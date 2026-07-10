<?php

use App\Http\Controllers\Auth\AuthController;
use App\Http\Controllers\Auth\PasswordController;
use App\Http\Controllers\Common\MasterDataController;
use App\Http\Controllers\Common\PushTokenController;
use App\Http\Controllers\Device\DeviceController;
use App\Http\Controllers\Device\SensorSessionController;
use App\Http\Controllers\Doctor\DoctorDashboardController;
use App\Http\Controllers\Doctor\DoctorPatientController;
use App\Http\Controllers\Glucose\GlucoseAlertController;
use App\Http\Controllers\Glucose\GlucoseReadingController;
use App\Http\Controllers\Glucose\GlucoseSummaryController;
use App\Http\Controllers\Organization\OrganizationController;
use App\Http\Controllers\Organization\OrganizationMemberController;
use App\Http\Controllers\Patient\AIInterpretationController;
use App\Http\Controllers\Patient\MealLogController;
use App\Http\Controllers\Patient\PatientDashboardController;
use App\Http\Controllers\Patient\PatientProfileController;
use App\Http\Controllers\Patient\PatientSharingController;
use App\Http\Controllers\Patient\SensorOrderController;
use App\Http\Controllers\Report\GlucoseReportController;
use App\Http\Resources\UserResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function (): void {
    Route::post('/sign-in', [AuthController::class, 'signIn'])->middleware('throttle:login');
    Route::post('/login', [AuthController::class, 'signIn'])->middleware('throttle:login');
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:login');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('/sign-out', [AuthController::class, 'signOut']);
        Route::post('/logout', [AuthController::class, 'signOut']);
        Route::get('/session', [AuthController::class, 'session']);
        Route::post('/refresh', [AuthController::class, 'refresh']);
        Route::put('/password', [PasswordController::class, 'update']);
    });
});

Route::middleware('auth:sanctum')->group(function (): void {
    Route::get('/user', fn (Request $request) => new UserResource($request->user()));
    Route::post('/push-tokens', [PushTokenController::class, 'store'])->middleware('throttle:60,1');

    Route::get('/device-integrations', [MasterDataController::class, 'integrations']);
    Route::get('/master-data/integrations', [MasterDataController::class, 'integrations']);
    Route::get('/master-data/enums', [MasterDataController::class, 'enums']);

    Route::get('/patients', [PatientProfileController::class, 'index']);
    Route::post('/patients', [PatientProfileController::class, 'store'])->middleware('role:doctor,admin');

    Route::middleware('patient.access')->prefix('patients/{patient}')->group(function (): void {
        Route::get('/', [PatientProfileController::class, 'show'])
            ->middleware('patient.permission:profile:read');
        Route::put('/', [PatientProfileController::class, 'update'])
            ->middleware('patient.permission:profile:write');
        Route::get('/dashboard', [PatientDashboardController::class, 'show'])
            ->middleware('patient.permission:profile:read,readings:read');

        Route::get('/readings', [GlucoseReadingController::class, 'index'])
            ->middleware('patient.permission:readings:read');
        Route::post('/readings', [GlucoseReadingController::class, 'store'])
            ->middleware('patient.permission:readings:write');
        Route::post('/readings/bulk', [GlucoseReadingController::class, 'bulkStore'])
            ->middleware('patient.permission:readings:write');
        Route::get('/glucose-summary', [GlucoseSummaryController::class, 'show'])
            ->middleware('patient.permission:readings:read');

        Route::get('/meals', [MealLogController::class, 'index'])
            ->middleware('patient.permission:meals:read');
        Route::post('/meals', [MealLogController::class, 'store'])
            ->middleware('patient.permission:meals:write');

        Route::get('/sensors', [DeviceController::class, 'index'])
            ->middleware('patient.permission:devices:read');
        Route::post('/sensors', [DeviceController::class, 'store'])
            ->middleware('patient.permission:devices:write');
        Route::get('/sensor-sessions', [SensorSessionController::class, 'index'])
            ->middleware('patient.permission:devices:read');
        Route::post('/sensor-sessions', [SensorSessionController::class, 'store'])
            ->middleware('patient.permission:devices:write');

        Route::get('/alerts', [GlucoseAlertController::class, 'index'])
            ->middleware('patient.permission:alerts:read');
        Route::get('/alert-settings', [GlucoseAlertController::class, 'settings'])
            ->middleware('patient.permission:alerts:read');
        Route::put('/alert-settings', [GlucoseAlertController::class, 'updateSettings'])
            ->middleware('patient.permission:alerts:write');

        Route::get('/reports', [GlucoseReportController::class, 'index'])
            ->middleware('patient.permission:reports:read');
        Route::post('/reports', [GlucoseReportController::class, 'store'])
            ->middleware('patient.permission:reports:write');

        Route::get('/orders', [SensorOrderController::class, 'index'])
            ->middleware('patient.permission:orders:read');
        Route::post('/orders', [SensorOrderController::class, 'store'])
            ->middleware('patient.permission:orders:write');

        Route::get('/interpretations', [AIInterpretationController::class, 'index'])
            ->middleware('patient.permission:interpretations:read');
        Route::post('/interpretations', [AIInterpretationController::class, 'store'])
            ->middleware(['role:doctor,admin', 'patient.permission:interpretations:write']);

        Route::get('/consent-preferences', [PatientSharingController::class, 'consent'])
            ->middleware('patient.permission:consents:read');
        Route::put('/consent-preferences', [PatientSharingController::class, 'updateConsent'])
            ->middleware('patient.permission:consents:write');
        Route::post('/data-grants', [PatientSharingController::class, 'grantDoctorAccess'])
            ->middleware('patient.permission:sharing:write');

        Route::get('/clinician-notes', [DoctorPatientController::class, 'notes'])
            ->middleware(['role:doctor,admin', 'patient.permission:notes:read']);
        Route::post('/clinician-notes', [DoctorPatientController::class, 'addNote'])
            ->middleware(['role:doctor,admin', 'patient.permission:notes:write']);
        Route::get('/care-tasks', [DoctorPatientController::class, 'tasks'])
            ->middleware(['role:doctor,admin', 'patient.permission:tasks:read']);
        Route::post('/care-tasks', [DoctorPatientController::class, 'assignTask'])
            ->middleware(['role:doctor,admin', 'patient.permission:tasks:write']);
        Route::post('/escalations', [DoctorPatientController::class, 'escalate'])
            ->middleware(['role:doctor,admin', 'patient.permission:tasks:write']);
    });

    Route::patch('/devices/{device}', [DeviceController::class, 'update']);
    Route::patch('/sensor-sessions/{session}', [SensorSessionController::class, 'update']);

    Route::post('/alerts/{alert}/acknowledge', [GlucoseAlertController::class, 'acknowledge']);
    Route::patch('/alerts/{alert}/acknowledge', [GlucoseAlertController::class, 'acknowledge']);
    Route::patch('/care-tasks/{task}/complete', [DoctorPatientController::class, 'completeTask'])->middleware('role:doctor,admin');

    Route::get('/doctor/dashboard', [DoctorDashboardController::class, 'show'])->middleware('role:doctor,admin');
    Route::get('/admin/dashboard', [DoctorDashboardController::class, 'show'])->middleware('role:admin');

    Route::apiResource('organizations', OrganizationController::class)->middleware('role:admin');
    Route::get('/organizations/{organization}/members', [OrganizationMemberController::class, 'index'])
        ->middleware('organization.access');
    Route::post('/organizations/{organization}/members', [OrganizationMemberController::class, 'store'])
        ->middleware('role:admin');
    Route::delete('/organizations/{organization}/members/{member}', [OrganizationMemberController::class, 'destroy'])
        ->middleware('role:admin');
});
