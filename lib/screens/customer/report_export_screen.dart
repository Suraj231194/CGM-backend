import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_states.dart';

class ReportExportScreen extends ConsumerStatefulWidget {
  const ReportExportScreen({super.key});

  @override
  ConsumerState<ReportExportScreen> createState() => _ReportExportScreenState();
}

class _ReportExportScreenState extends ConsumerState<ReportExportScreen> {
  String _period = '14 day';
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final readings = ref.watch(selectedReadingsProvider);
    final summary = ref.watch(summaryProvider);
    final meals = ref.watch(selectedMealsProvider);
    final alerts = ref.watch(activeAlertsProvider);
    final exports = ref.watch(selectedReportExportsProvider);
    final consent = ref.watch(
      appControllerProvider.select((state) => state.consentPreferences),
    );
    final controller = ref.read(appControllerProvider.notifier);
    final hasReadings = readings.isNotEmpty;

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Reports',
          title: 'Export and share',
          subtitle:
              'Prepare a clean glucose, meal, alert, and sensor summary for care-team review.',
        ),
        _ReportHero(
          timeInRange: summary.timeInRange,
          average: summary.average,
          meals: meals.length,
          alerts: alerts.length,
          hasReadings: hasReadings,
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report contents',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReportContentRow(
                icon: Icons.show_chart_rounded,
                label: 'CGM summary',
                value: hasReadings
                    ? '${summary.timeInRange}% time in range, ${summary.average} mg/dL average'
                    : 'Waiting for live sensor readings',
              ),
              _ReportContentRow(
                icon: Icons.restaurant_menu_rounded,
                label: 'Meal impact',
                value:
                    '${meals.length} logged meal${meals.length == 1 ? '' : 's'}',
              ),
              _ReportContentRow(
                icon: Icons.notifications_active_outlined,
                label: 'Alerts',
                value:
                    '${alerts.length} active alert${alerts.length == 1 ? '' : 's'}',
              ),
              _ReportContentRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Sharing consent',
                value: consent.reportSharing ? 'Enabled' : 'Disabled',
                color: consent.reportSharing
                    ? AppColors.meadow
                    : AppColors.warning,
                bottomPadding: 0,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _period,
                decoration: const InputDecoration(
                  labelText: 'Date range',
                  prefixIcon: Icon(Icons.date_range_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: '7 day', child: Text('Last 7 days')),
                  DropdownMenuItem(
                    value: '14 day',
                    child: Text('Last 14 days'),
                  ),
                  DropdownMenuItem(
                    value: '30 day',
                    child: Text('Last 30 days'),
                  ),
                ],
                onChanged: _generating
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _period = value);
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: consent.reportSharing && hasReadings && !_generating
                    ? () => _generateReport(controller)
                    : null,
                icon: _generating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(
                  _generating ? 'Generating...' : 'Generate PDF and CSV',
                ),
              ),
              if (!hasReadings) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Reports can be generated after live CGM readings are available.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
              if (!consent.reportSharing) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enable report sharing in Privacy before generating care-team exports.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Generated reports',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (exports.isEmpty)
          const AppEmptyState(
            icon: Icons.description_outlined,
            title: 'No reports generated',
            subtitle:
                'Care-team report exports will appear here after generation.',
          )
        else
          for (final report in exports)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _GeneratedReportCard(
                report: report,
                onShare: () => _shareReport(report),
              ),
            ),
      ],
    );
  }

  Future<void> _generateReport(AppController controller) async {
    setState(() => _generating = true);
    final report = await controller.generateReportExport(period: _period);
    if (!mounted) return;
    setState(() => _generating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          report == null
              ? 'No readings found for $_period.'
              : 'Report saved as PDF and CSV.',
        ),
      ),
    );
  }

  Future<void> _shareReport(ReportExport report) async {
    final files = [
      if ((report.filePath ?? '').isNotEmpty) XFile(report.filePath!),
      if ((report.csvPath ?? '').isNotEmpty) XFile(report.csvPath!),
    ];
    if (files.isEmpty && (report.shareLink ?? '').isEmpty) return;

    await SharePlus.instance.share(
      ShareParams(
        files: files.isEmpty ? null : files,
        text: report.shareLink ?? report.summary,
        subject: '${report.period} Optimus CGM report',
      ),
    );
  }
}

class _GeneratedReportCard extends StatelessWidget {
  const _GeneratedReportCard({required this.report, required this.onShare});

  final ReportExport report;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final shareLink = report.shareLink;
    final hasFiles =
        (report.filePath ?? '').isNotEmpty || (report.csvPath ?? '').isNotEmpty;
    return PremiumCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.description_outlined, color: AppColors.wellness),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${report.period} ${report.format} report',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_reportDateRangeLabel(report)} - ${report.summary}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(
                      label: report.status.toUpperCase(),
                      color: report.status == 'ready'
                          ? AppColors.meadow
                          : AppColors.warning,
                    ),
                    if (report.backendRecordId != null)
                      const StatusPill(
                        label: 'RECORDED',
                        color: AppColors.accentDeep,
                      ),
                    if (hasFiles)
                      OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.ios_share_rounded),
                        label: const Text('Share files'),
                      ),
                  ],
                ),
                if (shareLink != null && shareLink.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SelectableText(
                    shareLink,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _reportDateRangeLabel(ReportExport report) {
  final start = report.dateRangeStart;
  final end = report.dateRangeEnd;
  if (start == null || end == null) return formatShortDate(report.generatedAt);
  return '${formatShortDate(start)} to ${formatShortDate(end)}';
}

class _ReportHero extends StatelessWidget {
  const _ReportHero({
    required this.timeInRange,
    required this.average,
    required this.meals,
    required this.alerts,
    required this.hasReadings,
  });

  final int timeInRange;
  final int average;
  final int meals;
  final int alerts;
  final bool hasReadings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.wellness,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusPill(
            label: 'CARE TEAM READY',
            color: AppColors.mint,
            icon: Icons.ios_share_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Share the signal, not the clutter.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.onDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Reports combine CGM trends, food context, alerts, and sensor status into one review packet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onDarkMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ReportMetric(
                  label: 'Range',
                  value: hasReadings ? '$timeInRange%' : '--',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReportMetric(
                  label: 'Avg',
                  value: hasReadings ? '$average' : '--',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReportMetric(label: 'Meals', value: '$meals'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReportMetric(label: 'Alerts', value: '$alerts'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.onDark.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onDarkMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.onDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportContentRow extends StatelessWidget {
  const _ReportContentRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.wellness,
    this.bottomPadding = AppSpacing.md,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
