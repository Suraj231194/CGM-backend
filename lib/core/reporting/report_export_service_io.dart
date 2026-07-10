import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/optimus_models.dart';
import '../../utils/glucose_utils.dart';
import '../env/app_environment.dart';

class ReportExportService {
  const ReportExportService._();

  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  static Future<ReportExport> createFiles({
    required ReportExport draft,
    required Patient? patient,
    required Sensor? sensor,
    required List<OptimusGlucoseReading> readings,
    required List<MealLog> meals,
    required List<GlucoseAlert> alerts,
  }) async {
    final sortedReadings = readings.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final sortedMeals = meals.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final sortedAlerts = alerts.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final directory = await _reportDirectory();
    final baseName = _safeFileName(
      '${patient?.name ?? draft.patientId}_${draft.id}',
    );
    final pdfFile = File(
      '${directory.path}${Platform.pathSeparator}$baseName.pdf',
    );
    final csvFile = File(
      '${directory.path}${Platform.pathSeparator}$baseName.csv',
    );

    await pdfFile.writeAsBytes(
      await _buildPdf(
        draft: draft,
        patient: patient,
        sensor: sensor,
        readings: sortedReadings,
        meals: sortedMeals,
        alerts: sortedAlerts,
      ),
      flush: true,
    );
    await csvFile.writeAsString(
      _buildCsv(
        draft: draft,
        patient: patient,
        sensor: sensor,
        readings: sortedReadings,
        meals: sortedMeals,
        alerts: sortedAlerts,
      ),
      flush: true,
    );

    final shareLink = _shareLink(draft.id);
    final backendRecordId = await _registerBackendReport(
      draft: draft,
      patient: patient,
      sensor: sensor,
      readings: sortedReadings,
      meals: sortedMeals,
      alerts: sortedAlerts,
      pdfFile: pdfFile,
      csvFile: csvFile,
      shareLink: shareLink,
    );

    return draft.copyWith(
      format: 'PDF+CSV',
      status: backendRecordId == null ? 'ready-local' : 'ready',
      filePath: pdfFile.path,
      csvPath: csvFile.path,
      shareLink: shareLink,
      backendRecordId: backendRecordId ?? 'local-${draft.id}',
    );
  }

  static Uri shareUri(String reportId) => Uri.parse(_shareLink(reportId));

  static Future<Directory> _reportDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}optimus_reports',
    );
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  static Future<List<int>> _buildPdf({
    required ReportExport draft,
    required Patient? patient,
    required Sensor? sensor,
    required List<OptimusGlucoseReading> readings,
    required List<MealLog> meals,
    required List<GlucoseAlert> alerts,
  }) async {
    final document = pw.Document();
    final summary = summarizeReadings(readings);
    final latestReadings = readings.reversed.take(18).toList();
    final recentMeals = meals.reversed.take(10).toList();
    final recentAlerts = alerts.take(12).toList();

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        build: (context) => [
          pw.Text(
            'Optimus CGM Care Report',
            style: const pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Generated ${_dateFormat.format(draft.generatedAt)}'),
          pw.SizedBox(height: 16),
          _sectionTitle('Patient and sensor'),
          _keyValue('Patient', patient?.name ?? draft.patientId),
          _keyValue('Report period', _rangeLabel(draft)),
          _keyValue('Sensor', sensor?.serialNumber ?? 'Not available'),
          _keyValue('Sensor status', sensor?.status.name ?? 'unknown'),
          pw.SizedBox(height: 14),
          _sectionTitle('CGM summary'),
          _keyValue('Average glucose', '${summary.average} mg/dL'),
          _keyValue('Time in range', '${summary.timeInRange}%'),
          _keyValue('Time above range', '${summary.timeAbove}%'),
          _keyValue('Time below range', '${summary.timeBelow}%'),
          _keyValue('Min / Max', '${summary.min} / ${summary.max} mg/dL'),
          pw.SizedBox(height: 14),
          _sectionTitle('Recent readings'),
          ...latestReadings.map(
            (reading) => _compactLine(
              '${_dateFormat.format(reading.timestamp)}  '
              '${reading.value} ${reading.unit}  '
              '${trendLabel(reading.trend)}  ${reading.status.name}',
            ),
          ),
          if (latestReadings.isEmpty)
            _compactLine('No readings in this range.'),
          pw.SizedBox(height: 14),
          _sectionTitle('Meal context'),
          ...recentMeals.map(
            (meal) => _compactLine(
              '${_dateFormat.format(meal.timestamp)}  '
              '${meal.type.name}: ${meal.title}  '
              '${meal.netCarbs}g carbs, score ${meal.score}',
            ),
          ),
          if (recentMeals.isEmpty) _compactLine('No meal logs in this range.'),
          pw.SizedBox(height: 14),
          _sectionTitle('Alerts and safety'),
          ...recentAlerts.map(
            (alert) => _compactLine(
              '${_dateFormat.format(alert.timestamp)}  '
              '${alert.title}: ${alert.message}',
            ),
          ),
          if (recentAlerts.isEmpty) _compactLine('No alerts in this range.'),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500),
            ),
            child: pw.Text(
              'Safety note: CGM data supports trend review and is not a substitute '
              'for professional medical advice. Confirm unexpected readings, urgent '
              'highs/lows, or symptoms that do not match CGM values with a finger-prick '
              'blood glucose meter and follow clinician guidance.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static String _buildCsv({
    required ReportExport draft,
    required Patient? patient,
    required Sensor? sensor,
    required List<OptimusGlucoseReading> readings,
    required List<MealLog> meals,
    required List<GlucoseAlert> alerts,
  }) {
    final rows = <List<String>>[
      ['Optimus CGM Care Report'],
      ['Generated', _dateFormat.format(draft.generatedAt)],
      ['Patient', patient?.name ?? draft.patientId],
      ['Report period', _rangeLabel(draft)],
      ['Sensor', sensor?.serialNumber ?? 'Not available'],
      ['Sensor status', sensor?.status.name ?? 'unknown'],
      [],
      ['Readings'],
      ['timestamp', 'value', 'unit', 'trend', 'status'],
      for (final reading in readings)
        [
          reading.timestamp.toIso8601String(),
          '${reading.value}',
          reading.unit,
          trendLabel(reading.trend),
          reading.status.name,
        ],
      [],
      ['Meals'],
      [
        'timestamp',
        'type',
        'title',
        'netCarbs',
        'protein',
        'fiber',
        'activityMinutes',
        'score',
        'note',
      ],
      for (final meal in meals)
        [
          meal.timestamp.toIso8601String(),
          meal.type.name,
          meal.title,
          '${meal.netCarbs}',
          '${meal.protein}',
          '${meal.fiber}',
          '${meal.activityMinutes}',
          '${meal.score}',
          meal.note,
        ],
      [],
      ['Alerts'],
      ['timestamp', 'title', 'message', 'value', 'threshold', 'severity'],
      for (final alert in alerts)
        [
          alert.timestamp.toIso8601String(),
          alert.title,
          alert.message,
          '${alert.value}',
          '${alert.threshold}',
          alert.severity.name,
        ],
      [],
      [
        'Safety note',
        'CGM trend data should be confirmed with a finger-prick BGM when readings or symptoms do not match.',
      ],
    ];

    return rows.map(_csvRow).join('\n');
  }

  static Future<String?> _registerBackendReport({
    required ReportExport draft,
    required Patient? patient,
    required Sensor? sensor,
    required List<OptimusGlucoseReading> readings,
    required List<MealLog> meals,
    required List<GlucoseAlert> alerts,
    required File pdfFile,
    required File csvFile,
    required String shareLink,
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: EnvConfig.current.apiBaseUrl,
          connectTimeout: Duration(
            seconds: EnvConfig.current.connectionTimeoutSeconds,
          ),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final summary = summarizeReadings(readings);
      final response = await dio.post<Map<String, dynamic>>(
        '/patients/${draft.patientId}/reports',
        data: {
          'id': draft.id,
          'period': draft.period,
          'format': 'PDF+CSV',
          'generatedAt': draft.generatedAt.toIso8601String(),
          'dateRangeStart': draft.dateRangeStart?.toIso8601String(),
          'dateRangeEnd': draft.dateRangeEnd?.toIso8601String(),
          'summary': draft.summary,
          'shareLink': shareLink,
          'fileName': pdfFile.uri.pathSegments.last,
          'csvName': csvFile.uri.pathSegments.last,
          'patientName': patient?.name,
          'sensorSerialNumber': sensor?.serialNumber,
          'metrics': {
            'readingCount': readings.length,
            'mealCount': meals.length,
            'alertCount': alerts.length,
            'average': summary.average,
            'timeInRange': summary.timeInRange,
            'timeAbove': summary.timeAbove,
            'timeBelow': summary.timeBelow,
          },
        },
      );
      final data = response.data ?? const {};
      return (data['id'] ?? data['reportId'] ?? data['report_id'])?.toString();
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _sectionTitle(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        value,
        style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _keyValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _compactLine(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static String _rangeLabel(ReportExport draft) {
    final start = draft.dateRangeStart;
    final end = draft.dateRangeEnd;
    if (start == null || end == null) return draft.period;
    return '${_dateFormat.format(start)} to ${_dateFormat.format(end)}';
  }

  static String _csvRow(List<String> cells) {
    return cells
        .map((cell) {
          final needsQuotes =
              cell.contains(',') || cell.contains('"') || cell.contains('\n');
          final escaped = cell.replaceAll('"', '""');
          return needsQuotes ? '"$escaped"' : escaped;
        })
        .join(',');
  }

  static String _safeFileName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return cleaned.isEmpty ? 'optimus_report' : cleaned;
  }

  static String _shareLink(String reportId) {
    return 'https://app.optimus-cgm.com/reports?id=${Uri.encodeQueryComponent(reportId)}';
  }
}
