import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_states.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profiles = ref.watch(patientRiskProfilesProvider);
    final openTasks = ref.watch(openCareTasksProvider);
    final urgent = profiles.where((p) => p.riskLevel == 'urgent').length;
    final watch = profiles.where((p) => p.riskLevel == 'watch').length;
    final stable = profiles.where((p) => p.riskLevel == 'stable').length;

    return AppScreen(
      children: [
        const SectionHeader(
          eyebrow: 'Admin portal',
          title: 'Operations workspace',
          subtitle:
              'Live cohorts, escalations, audit trail, and support health.',
        ),
        ResponsiveGrid(
          minItemWidth: 165,
          children: [
            MetricTile(label: 'Customers', value: '${state.patients.length}'),
            MetricTile(
              label: 'Urgent cohort',
              value: '$urgent',
              color: AppColors.danger,
            ),
            MetricTile(
              label: 'Open tasks',
              value: '${openTasks.length}',
              color: AppColors.warning,
            ),
            MetricTile(
              label: 'Audit events',
              value: '${state.auditLogs.length}',
              color: AppColors.admin,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _AdminSection(
          title: 'Patient cohorts',
          emptyIcon: Icons.groups_2_outlined,
          emptyTitle: 'No cohorts yet',
          emptySubtitle: 'Cohorts populate after patients are loaded.',
          children: [
            _CohortRow(label: 'Urgent', count: urgent, color: AppColors.danger),
            _CohortRow(label: 'Watch', count: watch, color: AppColors.warning),
            _CohortRow(
              label: 'Stable',
              count: stable,
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _AdminSection(
          title: 'Escalation workflow',
          emptyIcon: Icons.assignment_turned_in_outlined,
          emptyTitle: 'No open escalations',
          emptySubtitle: 'Urgent CGM and clinician-created tasks appear here.',
          children: [
            for (final task in openTasks.take(8))
              _TaskAuditRow(
                icon: Icons.priority_high_rounded,
                title: task.title,
                subtitle:
                    '${_patientName(state, task.patientId)} - ${task.priority}',
                trailing: task.status.toUpperCase(),
                color: task.priority == 'urgent'
                    ? AppColors.danger
                    : AppColors.warning,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _AdminSection(
          title: 'Audit logs',
          emptyIcon: Icons.fact_check_outlined,
          emptyTitle: 'No audit events',
          emptySubtitle:
              'Care-team actions and report events will be recorded.',
          children: [
            for (final log in state.auditLogs.take(8))
              _TaskAuditRow(
                icon: Icons.history_rounded,
                title: log.action.replaceAll('_', ' '),
                subtitle:
                    '${log.actorRole} - ${log.details} - ${freshness(log.timestamp)}',
                trailing: log.targetType.toUpperCase(),
                color: AppColors.admin,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _AdminSection(
          title: 'Latest sync logs',
          emptyIcon: Icons.sync_outlined,
          emptyTitle: 'No sync logs',
          emptySubtitle:
              'Sensor, report, and backend sync activity appears here.',
          children: [
            for (final log in state.syncLogs.take(8))
              _TaskAuditRow(
                icon: Icons.sync_rounded,
                title: log.event,
                subtitle: '${log.details} - ${freshness(log.timestamp)}',
                trailing: log.status.toUpperCase(),
                color: log.status == 'success'
                    ? AppColors.success
                    : AppColors.warning,
              ),
          ],
        ),
      ],
    );
  }
}

class _AdminSection extends StatelessWidget {
  const _AdminSection({
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
    final visibleChildren = children
        .where((child) => child is! SizedBox)
        .toList();
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
        if (visibleChildren.isEmpty)
          AppEmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
          )
        else
          ...visibleChildren,
      ],
    );
  }
}

class _CohortRow extends StatelessWidget {
  const _CohortRow({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PremiumCard(
        elevated: false,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            StatusPill(label: label.toUpperCase(), color: color),
            const Spacer(),
            Text(
              '$count patient${count == 1 ? '' : 's'}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskAuditRow extends StatelessWidget {
  const _TaskAuditRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PremiumCard(
        elevated: false,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusPill(label: trailing, color: color),
          ],
        ),
      ),
    );
  }
}

String _patientName(AppState state, String patientId) {
  return state.patients
          .where((patient) => patient.id == patientId)
          .firstOrNull
          ?.name ??
      patientId;
}
