<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Http\Resources\CareTaskResource;
use App\Http\Resources\ClinicianNoteResource;
use App\Http\Resources\NotificationRecordResource;
use App\Models\CareTask;
use App\Models\PatientProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DoctorPatientController extends Controller
{
    public function notes(PatientProfile $patient): JsonResponse
    {
        return ApiResponse::success([
            'notes' => ClinicianNoteResource::collection($patient->clinicianNotes()->with('author')->latest()->get()),
        ]);
    }

    public function addNote(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'note' => ['required', 'string', 'max:5000'],
        ]);

        $note = $patient->clinicianNotes()->create([
            'author_id' => $request->user()->id,
            'note' => $data['note'],
        ]);

        return response()->json(new ClinicianNoteResource($note->load('author')), 201);
    }

    public function tasks(PatientProfile $patient): JsonResponse
    {
        return ApiResponse::success([
            'tasks' => CareTaskResource::collection($patient->careTasks()->latest()->get()),
        ]);
    }

    public function assignTask(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'priority' => ['nullable', 'in:routine,warning,urgent'],
            'assigned_to' => ['nullable', 'exists:users,id'],
            'due_at' => ['nullable', 'date'],
        ]);

        $priority = $data['priority'] ?? 'routine';
        $task = $patient->careTasks()->create([
            'title' => $data['title'],
            'priority' => $priority,
            'owner_role' => $request->user()->role->value,
            'assigned_to' => $data['assigned_to'] ?? $request->user()->id,
            'status' => 'open',
            'due_at' => $data['due_at'] ?? now()->addHours($priority === 'urgent' ? 4 : 24),
        ]);

        return response()->json(new CareTaskResource($task), 201);
    }

    public function completeTask(Request $request, CareTask $task): JsonResponse
    {
        abort_unless($request->user()?->canAccessPatient($task->patient), 403);

        $task->update([
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        return response()->json(new CareTaskResource($task->refresh()));
    }

    public function escalate(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'reason' => ['nullable', 'string', 'max:2000'],
        ]);

        $reason = $data['reason'] ?? 'Urgent CGM review requested';
        $task = $patient->careTasks()->create([
            'title' => "Escalation review: {$reason}",
            'owner_role' => 'doctor',
            'status' => 'open',
            'priority' => 'urgent',
            'assigned_to' => $patient->doctor_id,
            'due_at' => now()->addHours(2),
        ]);

        $notification = $patient->notifications()->create([
            'timestamp' => now(),
            'title' => 'Care escalation created',
            'message' => $reason,
            'type' => 'care_escalation',
            'delivered' => true,
            'route' => '/doctor',
        ]);

        return ApiResponse::success([
            'task' => new CareTaskResource($task),
            'notification' => new NotificationRecordResource($notification),
        ], status: 201);
    }
}
