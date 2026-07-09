<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use App\Models\Organization;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureOrganizationAccess
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        $organization = $request->route('organization');

        if (! $user || ! $organization) {
            abort(403, 'Organization access is required.');
        }

        $organizationModel = $organization instanceof Organization
            ? $organization
            : Organization::query()->find($organization);

        if (! $organizationModel) {
            abort(404, 'Organization not found.');
        }

        $hasAccess = $user->hasRole(UserRole::ADMIN)
            || $user->organizationMemberships()
                ->where('organization_id', $organizationModel->id)
                ->exists();

        if (! $hasAccess) {
            abort(403, 'You do not have access to this organization.');
        }

        return $next($request);
    }
}
