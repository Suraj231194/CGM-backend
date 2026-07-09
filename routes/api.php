<?php

use App\Http\Controllers\Auth\AuthController;
use App\Http\Controllers\Auth\PasswordController;
use App\Http\Controllers\Common\MasterDataController;
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

    Route::get('/device-integrations', [MasterDataController::class, 'integrations']);
    Route::get('/master-data/integrations', [MasterDataController::class, 'integrations']);
    Route::get('/master-data/enums', [MasterDataController::class, 'enums']);

    Route::get('/patients', [PatientProfileController::class, 'index']);
    Route::post('/patients', [PatientProfileController::class, 'store'])->middleware('role:doctor,admin');

    Route::middleware('patient.access')->prefix('patients/{patient}')->group(function (): void {
        Route::get('/', [PatientProfileController::class, 'show']);
        Route::put('/', [PatientProfileController::class, 'update']);
        Route::get('/dashboard', [PatientDashboardController::class, 'show']);

        Route::get('/readings', [GlucoseReadingController::class, 'index']);
        Route::post('/readings', [GlucoseReadingController::class, 'store']);
        Route::post('/readings/bulk', [GlucoseReadingController::class, 'bulkStore']);
        Route::get('/glucose-summary', [GlucoseSummaryController::class, 'show']);

        Route::get('/meals', [MealLogController::class, 'index']);
        Route::post('/meals', [MealLogController::class, 'store']);

        Route::get('/sensors', [DeviceController::class, 'index']);
        Route::post('/sensors', [DeviceController::class, 'store']);
        Route::get('/sensor-sessions', [SensorSessionController::class, 'index']);
        Route::post('/sensor-sessions', [SensorSessionController::class, 'store']);

        Route::get('/alerts', [GlucoseAlertController::class, 'index']);
        Route::get('/alert-settings', [GlucoseAlertController::class, 'settings']);
        Route::put('/alert-settings', [GlucoseAlertController::class, 'updateSettings']);

        Route::get('/reports', [GlucoseReportController::class, 'index']);
        Route::post('/reports', [GlucoseReportController::class, 'store']);

        Route::get('/orders', [SensorOrderController::class, 'index']);
        Route::post('/orders', [SensorOrderController::class, 'store']);

        Route::get('/interpretations', [AIInterpretationController::class, 'index']);
        Route::post('/interpretations', [AIInterpretationController::class, 'store'])->middleware('role:doctor,admin');

        Route::get('/consent-preferences', [PatientSharingController::class, 'consent']);
        Route::put('/consent-preferences', [PatientSharingController::class, 'updateConsent']);
        Route::post('/data-grants', [PatientSharingController::class, 'grantDoctorAccess']);

        Route::get('/clinician-notes', [DoctorPatientController::class, 'notes'])->middleware('role:doctor,admin');
        Route::post('/clinician-notes', [DoctorPatientController::class, 'addNote'])->middleware('role:doctor,admin');
        Route::get('/care-tasks', [DoctorPatientController::class, 'tasks'])->middleware('role:doctor,admin');
        Route::post('/care-tasks', [DoctorPatientController::class, 'assignTask'])->middleware('role:doctor,admin');
        Route::post('/escalations', [DoctorPatientController::class, 'escalate'])->middleware('role:doctor,admin');
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
