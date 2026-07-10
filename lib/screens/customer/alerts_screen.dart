import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_states.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final activeAlerts = ref.watch(activeAlertsProvider);
    final notificationHistory = ref.watch(selectedNotificationHistoryProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final settings = state.alertSettings;

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Alerts',
          title: 'Glucose alert center',
          subtitle:
              'Configure low/high thresholds and review important glucose events.',
        ),
        _AlertSummary(activeCount: activeAlerts.length),
        const SizedBox(height: AppSpacing.lg),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification rules',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.wellness,
                  ),
                  title: const Text('Enable glucose alerts'),
                  subtitle: const Text(
                    'Show in-app alerts for low/high readings.',
                  ),
                  value: settings.notificationsEnabled,
                  onChanged: (value) => controller.updateAlertSettings(
                    settings.copyWith(notificationsEnabled: value),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.bedtime_outlined,
                    color: AppColors.wellness,
                  ),
                  title: const Text('Quiet hours'),
                  subtitle: const Text(
                    'Keep non-urgent coaching quiet overnight.',
                  ),
                  value: settings.quietHoursEnabled,
                  onChanged: (value) => controller.updateAlertSettings(
                    settings.copyWith(quietHoursEnabled: value),
                  ),
                ),
              ),
              _ThresholdSlider(
                label: 'Sensor disconnect reminder',
                value: settings.sensorDisconnectReminderMinutes,
                min: 5,
                max: 60,
                divisions: 11,
                suffix: 'min',
                color: AppColors.primary,
                onChanged: (value) => controller.updateAlertSettings(
                  settings.copyWith(
                    sensorDisconnectReminderMinutes: value.round(),
                  ),
                ),
              ),
              _ThresholdSlider(
                label: 'Low threshold',
                value: settings.lowThreshold,
                min: 55,
                max: 90,
                color: AppColors.danger,
                onChanged: (value) => controller.updateAlertSettings(
                  settings.copyWith(lowThreshold: value.round()),
                ),
              ),
              _ThresholdSlider(
                label: 'High threshold',
                value: settings.highThreshold,
                min: 140,
                max: 240,
                color: AppColors.honey,
                onChanged: (value) => controller.updateAlertSettings(
                  settings.copyWith(highThreshold: value.round()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Active alerts',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (activeAlerts.isEmpty)
          const AppEmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No active alerts',
            subtitle: 'Low and high glucose events will appear here.',
          )
        else
          for (final alert in activeAlerts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AlertCard(
                alert: alert,
                onAcknowledge: () => controller.acknowledgeAlert(alert.id),
              ),
            ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Notification history',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (notificationHistory.isEmpty)
          const AppEmptyState(
            icon: Icons.history_rounded,
            title: 'No notifications yet',
            subtitle:
                'Delivered glucose and sensor notifications will appear here.',
          )
        else
          for (final record in notificationHistory.take(10))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _NotificationHistoryCard(record: record),
            ),
      ],
    );
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: activeCount == 0 ? AppColors.wellness : AppColors.clay,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.onDark,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeCount == 0
                      ? 'All clear'
                      : '$activeCount alert${activeCount == 1 ? '' : 's'} need review',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Use these alerts as a review prompt, not emergency or treatment guidance.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onDarkMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  const _ThresholdSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
    this.divisions,
    this.suffix = 'mg/dL',
  });

  final String label;
  final int value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '$value $suffix',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Slider(
            min: min,
            max: max,
            divisions: divisions ?? (max - min).round(),
            value: value.toDouble().clamp(min, max),
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onAcknowledge});

  final GlucoseAlert alert;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      AlertSeverity.info => AppColors.primary,
      AlertSeverity.warning => AppColors.honey,
      AlertSeverity.urgent => AppColors.danger,
    };
    final valueLabel = alert.value > 0 ? '${alert.value} mg/dL' : 'SENSOR';

    return PremiumCard(
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: valueLabel,
                color: color,
                icon: Icons.monitor_heart_rounded,
              ),
              const Spacer(),
              Text(
                formatTime(alert.timestamp),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            alert.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            alert.message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onAcknowledge,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }
}

class _NotificationHistoryCard extends StatelessWidget {
  const _NotificationHistoryCard({required this.record});

  final NotificationRecord record;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            record.delivered
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: record.delivered ? AppColors.accentDeep : AppColors.muted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  record.message,
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
          Text(
            freshness(record.timestamp),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
