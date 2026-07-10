import '../../models/optimus_models.dart';

class ReportExportService {
  const ReportExportService._();

  static Future<ReportExport> createFiles({
    required ReportExport draft,
    required Patient? patient,
    required Sensor? sensor,
    required List<OptimusGlucoseReading> readings,
    required List<MealLog> meals,
    required List<GlucoseAlert> alerts,
  }) async {
    return draft.copyWith(
      status: 'ready-local',
      shareLink: _shareLink(draft.id),
      backendRecordId: 'local-${draft.id}',
    );
  }

  static Uri shareUri(String reportId) => Uri.parse(_shareLink(reportId));

  static String _shareLink(String reportId) {
    return 'https://app.optimus-cgm.com/reports?id=$reportId';
  }
}
