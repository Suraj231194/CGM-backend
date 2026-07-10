<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use App\Models\PatientProfile;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePatientPermission
{
    public function handle(Request $request, Closure $next, string ...$requiredPermissions): Response
    {
        $user = $request->user();
        $patient = $request->route('patient');
        $patient = $patient instanceof PatientProfile
            ? $patient
            : PatientProfile::query()->find($patient);

        if (! $user || ! $patient) {
            abort(403, 'Patient access is required.');
        }

        if (! $user->hasRole(UserRole::DOCTOR)
            || (int) $patient->doctor_id === (int) $user->id
            || $requiredPermissions === []) {
            return $next($request);
        }

        $grant = $patient->dataGrants()
            ->where('doctor_id', $user->id)
            ->where('status', 'accepted')
            ->where(fn ($query) => $query
                ->whereNull('expires_at')
                ->orWhere('expires_at', '>', now()))
            ->first();

        $grantedPermissions = $grant?->permissions ?? [];
        $allowed = in_array('*', $grantedPermissions, true)
            || collect($requiredPermissions)->every(
                fn (string $permission) => in_array($permission, $grantedPermissions, true),
            );

        abort_unless($grant && $allowed, 403, 'The patient has not granted this permission.');

        return $next($request);
    }
}
