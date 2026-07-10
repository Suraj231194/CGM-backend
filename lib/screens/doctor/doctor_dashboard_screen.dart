import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_states.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final profiles = ref
        .watch(patientRiskProfilesProvider)
        .where((profile) => profile.patient.doctorId == 'doctor-1')
        .toList();
    final reviewQueue =
        profiles.where((profile) => profile.needsReview).toList()
          ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    final patientIds = profiles.map((profile) => profile.patient.id).toSet();
    final openTasks =
        state.careTasks
            .where(
              (task) =>
                  patientIds.contains(task.patientId) &&
                  task.status != 'completed',
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final notes =
        state.clinicianNotes
            .where((note) => patientIds.contains(note.patientId))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return AppScreen(
      children: [
        const SectionHeader(
          eyebrow: 'Doctor portal',
          title: 'Clinical workspace',
          subtitle: 'Live CGM risk, review queue, notes, and assigned work.',
        ),
        ResponsiveGrid(
          minItemWidth: 165,
          children: [
            MetricTile(label: 'Patients', value: '${profiles.length}'),
            MetricTile(
              label: 'Urgent',
              value: '${profiles.where((p) => p.riskLevel == 'urgent').length}',
              color: AppColors.danger,
            ),
            MetricTile(
              label: 'Watch list',
              value: '${reviewQueue.length}',
              color: AppColors.warning,
            ),
            MetricTile(
              label: 'Open tasks',
              value: '${openTasks.length}',
              color: AppColors.accentDeep,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Review queue',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (reviewQueue.isEmpty)
          const AppEmptyState(
            icon: Icons.verified_user_outlined,
            title: 'No patients need review',
            subtitle: 'Live CGM risk scoring has no active review items.',
          )
        else
          for (final profile in reviewQueue)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RiskProfileCard(
                profile: profile,
                onOpen: () {
                  controller.selectPatient(profile.patient.id);
                  context.go('/readings');
                },
                onNote: () async {
                  final note = await _promptText(
                    context,
                    title: 'Add clinician note',
                    label: 'Note',
                  );
                  if (note == null) return;
                  controller.addClinicianNote(
                    patientId: profile.patient.id,
                    note: note,
                  );
                },
                onTask: () async {
                  final task = await _promptText(
                    context,
                    title: 'Assign care task',
                    label: 'Task',
                  );
                  if (task == null) return;
                  controller.assignCareTask(
                    patientId: profile.patient.id,
                    title: task,
                    priority: profile.riskLevel == 'urgent'
                        ? 'urgent'
                        : 'routine',
                  );
                },
                onEscalate: () {
                  controller.escalatePatient(
                    patientId: profile.patient.id,
                    reason: profile.reason,
                  );
                },
              ),
            ),
        const SizedBox(height: AppSpacing.lg),
        _DoctorSection(
          title: 'Assigned tasks',
          emptyIcon: Icons.task_alt_rounded,
          emptyTitle: 'No open tasks',
          emptySubtitle: 'Tasks assigned from reviews will appear here.',
          children: [
            for (final task in openTasks.take(6))
              _TaskRow(
                task: task,
                patientName: _patientName(state, task.patientId),
                onComplete: () => controller.completeCareTask(task.id),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DoctorSection(
          title: 'Clinician notes',
          emptyIcon: Icons.note_alt_outlined,
          emptyTitle: 'No notes yet',
          emptySubtitle: 'Notes added during patient reviews will appear here.',
          children: [
            for (final note in notes.take(5))
              _NoteRow(
                note: note,
                patientName: _patientName(state, note.patientId),
              ),
          ],
        ),
      ],
    );
  }
}

class _RiskProfileCard extends StatelessWidget {
  const _RiskProfileCard({
    required this.profile,
    required this.onOpen,
    required this.onNote,
    required this.onTask,
    required this.onEscalate,
  });

  final PatientRiskProfile profile;
  final VoidCallback onOpen;
  final VoidCallback onNote;
  final VoidCallback onTask;
  final VoidCallback onEscalate;

  @override
  Widget build(BuildContext context) {
    final latest = profile.latestReading;
    return PremiumCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _riskColor(
                  profile.riskLevel,
                ).withValues(alpha: 0.12),
                foregroundColor: _riskColor(profile.riskLevel),
                child: Text(profile.patient.name.substring(0, 1)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.patient.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      latest == null
                          ? profile.reason
                          : '${latest.value} mg/dL, ${trendLabel(latest.trend)} - ${profile.reason}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: profile.riskLevel.toUpperCase(),
                color: _riskColor(profile.riskLevel),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.show_chart_rounded),
                label: const Text('Readings'),
              ),
              OutlinedButton.icon(
                onPressed: onNote,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Note'),
              ),
              OutlinedButton.icon(
                onPressed: onTask,
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Task'),
              ),
              FilledButton.icon(
                onPressed: onEscalate,
                icon: const Icon(Icons.priority_high_rounded),
                label: const Text('Escalate'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorSection extends StatelessWidget {
  const _DoctorSection({
    required this.title,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.children,
  });

  final String title;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (children.isEmpty)
          AppEmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
          )
        else
          ...children,
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.patientName,
    required this.onComplete,
  });

  final CareTask task;
  final String patientName;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PremiumCard(
        elevated: false,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            StatusPill(
              label: task.priority.toUpperCase(),
              color: task.priority == 'urgent'
                  ? AppColors.danger
                  : AppColors.accentDeep,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '$patientName - ${freshness(task.createdAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Complete task',
              onPressed: onComplete,
              icon: const Icon(Icons.check_circle_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.patientName});

  final ClinicianNote note;
  final String patientName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PremiumCard(
        elevated: false,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patientName,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(note.note, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${note.authorName} - ${freshness(note.createdAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  required String label,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

String _patientName(AppState state, String patientId) {
  return state.patients
          .where((patient) => patient.id == patientId)
          .firstOrNull
          ?.name ??
      patientId;
}

Color _riskColor(String riskLevel) {
  return switch (riskLevel) {
    'urgent' => AppColors.danger,
    'watch' => AppColors.warning,
    _ => AppColors.success,
  };
}
