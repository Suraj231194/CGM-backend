<?php

namespace App\Http\Middleware;

use App\Models\PatientProfile;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePatientAccess
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        $patient = $request->route('patient');

        if (! $user || ! $patient) {
            abort(403, 'Patient access is required.');
        }

        $patientProfile = $patient instanceof PatientProfile
            ? $patient
            : PatientProfile::query()->find($patient);

        if (! $patientProfile || ! $user->canAccessPatient($patientProfile)) {
            abort(403, 'You do not have access to this patient.');
        }

        return $next($request);
    }
}
