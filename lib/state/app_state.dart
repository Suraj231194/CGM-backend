import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/ble/paired_sensor_store.dart';
import '../core/cache/glucose_reading_cache.dart';
import '../core/env/app_environment.dart';
import '../core/reporting/app_log_file.dart';
import '../core/reporting/report_export_service.dart';
import '../data/optimus_seed_data.dart';
import '../models/optimus_models.dart';
import '../repositories/contracts/patient_repository.dart';
import '../repositories/repository_providers.dart';
import '../services/cgm_sdk_service.dart';
import '../services/push_notification_service.dart';
import '../utils/glucose_utils.dart';
import '../utils/sensor_serial_parser.dart';

final authBypassProvider = Provider<bool>((ref) {
  return EnvConfig.current.bypassAuthentication;
});

class AppState {
  const AppState({
    required this.isAuthenticated,
    required this.onboardingComplete,
    required this.currentUser,
    required this.activeRole,
    required this.activePatientId,
    required this.selectedPatientId,
    required this.patients,
    required this.sensors,
    required this.readings,
    required this.meals,
    required this.aiInterpretations,
    required this.orders,
    required this.syncLogs,
    required this.integrations,
    required this.consentPreferences,
    required this.alertSettings,
    required this.alerts,
    required this.reportExports,
    required this.notificationHistory,
    required this.clinicianNotes,
    required this.careTasks,
    required this.auditLogs,
    required this.chartDuration,
    required this.readingFilter,
    required this.themeMode,
    required this.cgmAuthorized,
    required this.cgmConnecting,
    required this.cgmConnected,
    required this.cgmWasEverConnected,
    required this.cgmConnectionStatus,
    required this.cgmSensorSn,
    required this.cgmLastError,
    required this.cgmSyncProgress,
    required this.cgmSdkLogs,
    required this.cgmNearbyDeviceName,
    required this.cgmNearbyDeviceAddress,
    required this.cgmNearbyDeviceRssi,
  });

  final bool isAuthenticated;
  final bool onboardingComplete;
  final OptimusUser? currentUser;
  final OptimusRole activeRole;
  final String activePatientId;
  final String selectedPatientId;
  final List<Patient> patients;
  final List<Sensor> sensors;
  final List<OptimusGlucoseReading> readings;
  final List<MealLog> meals;
  final List<AIInterpretation> aiInterpretations;
  final List<Order> orders;
  final List<SensorSyncLog> syncLogs;
  final List<DeviceIntegration> integrations;
  final ConsentPreferences consentPreferences;
  final AlertSettings alertSettings;
  final List<GlucoseAlert> alerts;
  final List<ReportExport> reportExports;
  final List<NotificationRecord> notificationHistory;
  final List<ClinicianNote> clinicianNotes;
  final List<CareTask> careTasks;
  final List<AuditLogEntry> auditLogs;
  final ChartDuration chartDuration;
  final GlucoseStatus? readingFilter;
  final ThemeMode themeMode;
  final bool cgmAuthorized;
  final bool cgmConnecting;
  final bool cgmConnected;

  /// True once a BLE connection has succeeded at least once for the current sensor.
  final bool cgmWasEverConnected;
  final String cgmConnectionStatus;
  final String? cgmSensorSn;
  final String? cgmLastError;
  final int cgmSyncProgress;
  final List<String> cgmSdkLogs;
  final String? cgmNearbyDeviceName;
  final String? cgmNearbyDeviceAddress;
  final int? cgmNearbyDeviceRssi;

  AppState copyWith({
    bool? isAuthenticated,
    bool? onboardingComplete,
    OptimusUser? currentUser,
    OptimusRole? activeRole,
    String? activePatientId,
    String? selectedPatientId,
    List<Patient>? patients,
    List<Sensor>? sensors,
    List<OptimusGlucoseReading>? readings,
    List<MealLog>? meals,
    List<AIInterpretation>? aiInterpretations,
    List<Order>? orders,
    List<SensorSyncLog>? syncLogs,
    List<DeviceIntegration>? integrations,
    ConsentPreferences? consentPreferences,
    AlertSettings? alertSettings,
    List<GlucoseAlert>? alerts,
    List<ReportExport>? reportExports,
    List<NotificationRecord>? notificationHistory,
    List<ClinicianNote>? clinicianNotes,
    List<CareTask>? careTasks,
    List<AuditLogEntry>? auditLogs,
    ChartDuration? chartDuration,
    GlucoseStatus? readingFilter,
    ThemeMode? themeMode,
    bool? cgmAuthorized,
    bool? cgmConnecting,
    bool? cgmConnected,
    bool? cgmWasEverConnected,
    String? cgmConnectionStatus,
    String? cgmSensorSn,
    String? cgmLastError,
    int? cgmSyncProgress,
    List<String>? cgmSdkLogs,
    String? cgmNearbyDeviceName,
    String? cgmNearbyDeviceAddress,
    int? cgmNearbyDeviceRssi,
    bool clearReadingFilter = false,
    bool clearCurrentUser = false,
    bool clearCgmLastError = false,
    bool clearCgmNearbyDevice = false,
  }) {
    final effectiveConnected = cgmConnected ?? this.cgmConnected;
    return AppState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      activeRole: activeRole ?? this.activeRole,
      activePatientId: activePatientId ?? this.activePatientId,
      selectedPatientId: selectedPatientId ?? this.selectedPatientId,
      patients: patients ?? this.patients,
      sensors: sensors ?? this.sensors,
      readings: readings ?? this.readings,
      meals: meals ?? this.meals,
      aiInterpretations: aiInterpretations ?? this.aiInterpretations,
      orders: orders ?? this.orders,
      syncLogs: syncLogs ?? this.syncLogs,
      integrations: integrations ?? this.integrations,
      consentPreferences: consentPreferences ?? this.consentPreferences,
      alertSettings: alertSettings ?? this.alertSettings,
      alerts: alerts ?? this.alerts,
      reportExports: reportExports ?? this.reportExports,
      notificationHistory: notificationHistory ?? this.notificationHistory,
      clinicianNotes: clinicianNotes ?? this.clinicianNotes,
      careTasks: careTasks ?? this.careTasks,
      auditLogs: auditLogs ?? this.auditLogs,
      chartDuration: chartDuration ?? this.chartDuration,
      readingFilter: clearReadingFilter
          ? null
          : readingFilter ?? this.readingFilter,
      themeMode: themeMode ?? this.themeMode,
      cgmAuthorized: cgmAuthorized ?? this.cgmAuthorized,
      cgmConnecting: cgmConnecting ?? this.cgmConnecting,
      cgmConnected: effectiveConnected,
      cgmWasEverConnected:
          cgmWasEverConnected ??
          (effectiveConnected ? true : this.cgmWasEverConnected),
      cgmConnectionStatus: cgmConnectionStatus ?? this.cgmConnectionStatus,
      cgmSensorSn: cgmSensorSn ?? this.cgmSensorSn,
      cgmLastError: clearCgmLastError
          ? null
          : cgmLastError ?? this.cgmLastError,
      cgmSyncProgress: cgmSyncProgress ?? this.cgmSyncProgress,
      cgmSdkLogs: cgmSdkLogs ?? this.cgmSdkLogs,
      cgmNearbyDeviceName: clearCgmNearbyDevice
          ? null
          : cgmNearbyDeviceName ?? this.cgmNearbyDeviceName,
      cgmNearbyDeviceAddress: clearCgmNearbyDevice
          ? null
          : cgmNearbyDeviceAddress ?? this.cgmNearbyDeviceAddress,
      cgmNearbyDeviceRssi: clearCgmNearbyDevice
          ? null
          : cgmNearbyDeviceRssi ?? this.cgmNearbyDeviceRssi,
    );
  }
}

class AppController extends Notifier<AppState> {
  bool _persistentReadingsRestored = false;
  bool _backendBootstrapStarted = false;
  final Set<String> _backendSyncedReadingIds = <String>{};
  final Map<String, String> _backendSensorIdsBySerial = <String, String>{};

  @override
  AppState build() {
    final bypassAuthentication = ref.read(authBypassProvider);
    final previewUser = bypassAuthentication
        ? optimusUsers.firstWhere((user) => user.role == OptimusRole.customer)
        : null;

    return AppState(
      isAuthenticated: bypassAuthentication,
      onboardingComplete: bypassAuthentication,
      currentUser: previewUser,
      activeRole: OptimusRole.customer,
      activePatientId: 'patient-1',
      selectedPatientId: 'patient-1',
      patients: optimusPatients,
      sensors: optimusSensors,
      readings: const [],
      meals: optimusMealLogs,
      aiInterpretations: const [],
      orders: optimusOrders,
      syncLogs: const [],
      integrations: deviceIntegrations,
      consentPreferences: defaultConsentPreferences,
      alertSettings: defaultAlertSettings,
      alerts: const [],
      reportExports: const [],
      notificationHistory: const [],
      clinicianNotes: const [],
      careTasks: const [],
      auditLogs: const [],
      chartDuration: ChartDuration.day,
      readingFilter: null,
      themeMode: ThemeMode.light,
      cgmAuthorized: false,
      cgmConnecting: false,
      cgmConnected: false,
      cgmWasEverConnected: false,
      cgmConnectionStatus: 'Not connected',
      cgmSensorSn: null,
      cgmLastError: null,
      cgmSyncProgress: 0,
      cgmSdkLogs: const [],
      cgmNearbyDeviceName: null,
      cgmNearbyDeviceAddress: null,
      cgmNearbyDeviceRssi: null,
    );
  }

  Future<void> bootstrapBackend({bool force = false}) async {
    if (!ref.read(backendSyncEnabledProvider)) return;
    if (_backendBootstrapStarted && !force) return;
    _backendBootstrapStarted = true;

    try {
      final session = await ref.read(backendSessionProvider).ensureSession();
      final patientRepository = ref.read(patientRepositoryProvider);
      final alertRepository = ref.read(alertRepositoryProvider);
      final patients = await patientRepository.getPatients();
      if (patients.isEmpty) return;

      final activeRole = session?.role ?? state.activeRole;
      final activeUser = session?.user ?? state.currentUser;
      final selectedPatient = _preferredBackendPatient(patients);
      final patientId = selectedPatient.id;
      final sensors = await patientRepository.getSensors(patientId: patientId);
      final readings = await _loadBackendReadings(
        patientRepository,
        patientId: patientId,
      );
      final meals = await patientRepository.getMeals(patientId: patientId);
      final interpretations = await patientRepository.getInterpretations(
        patientId: patientId,
      );
      final orders = await patientRepository.getOrders(patientId: patientId);
      final alerts = await alertRepository.getAlerts(patientId: patientId);
      final alertSettings = await alertRepository.getAlertSettings(
        patientId: patientId,
      );
      final reports = await alertRepository.getReports(patientId: patientId);

      state = state.copyWith(
        isAuthenticated: true,
        onboardingComplete: true,
        currentUser: activeUser,
        activeRole: activeRole,
        activePatientId: patientId,
        selectedPatientId: patientId,
        patients: patients,
        sensors: _replacePatientScopedSensors(sensors, patientId),
        readings: _replacePatientScopedReadings(readings, patientId),
        meals: _replacePatientScopedMeals(meals, patientId),
        aiInterpretations: _replacePatientScopedInterpretations(
          interpretations,
          patientId,
        ),
        orders: _replacePatientScopedOrders(orders, patientId),
        alerts: _replacePatientScopedAlerts(alerts, patientId),
        alertSettings: alertSettings,
        reportExports: _replacePatientScopedReports(reports, patientId),
        syncLogs: [
          SensorSyncLog(
            id: 'sync-backend-${DateTime.now().millisecondsSinceEpoch}',
            sensorId: sensors.firstOrNull?.id ?? selectedPatient.sensorId,
            patientId: patientId,
            event: 'Backend sync',
            status: 'success',
            timestamp: DateTime.now(),
            details:
                'Loaded ${readings.length} reading(s), ${meals.length} meal(s), and ${alerts.length} alert(s) from backend.',
          ),
          ...state.syncLogs,
        ].take(120).toList(),
        cgmSdkLogs: _prependLog('Backend data synced.'),
        clearReadingFilter: true,
      );
      if (activeUser != null) {
        unawaited(
          PushNotificationService.instance.registerToken(activeUser.id),
        );
        unawaited(
          PushNotificationService.instance.subscribeToPatient(patientId),
        );
      }
    } catch (error) {
      _recordBackendSyncFailure('Backend bootstrap', error);
    }
  }

  void signIn(String email, {OptimusRole? role}) {
    final selectedRole = role ?? _inferRole(email);
    final user = _userForRole(selectedRole);
    final patient = _patientForRole(selectedRole);
    state = state.copyWith(
      isAuthenticated: true,
      currentUser: user,
      activeRole: selectedRole,
      activePatientId: patient.id,
      selectedPatientId: patient.id,
      onboardingComplete: selectedRole != OptimusRole.customer,
    );
    unawaited(PushNotificationService.instance.registerToken(user.id));
    unawaited(PushNotificationService.instance.subscribeToPatient(patient.id));
  }

  void signOut() {
    final patientId = state.selectedPatientId;
    unawaited(
      PushNotificationService.instance.unsubscribeFromPatient(patientId),
    );
    if (ref.read(authBypassProvider)) {
      final user = _userForRole(OptimusRole.customer);
      final patient = _patientForRole(OptimusRole.customer);
      state = state.copyWith(
        isAuthenticated: true,
        onboardingComplete: true,
        currentUser: user,
        activeRole: OptimusRole.customer,
        activePatientId: patient.id,
        selectedPatientId: patient.id,
        clearReadingFilter: true,
      );
      return;
    }
    state = state.copyWith(isAuthenticated: false, clearCurrentUser: true);
  }

  void switchRole(OptimusRole role) {
    final user = _userForRole(role);
    final patient = _patientForRole(role);
    state = state.copyWith(
      activeRole: role,
      currentUser: user,
      activePatientId: patient.id,
      selectedPatientId: patient.id,
      clearReadingFilter: true,
    );
    unawaited(PushNotificationService.instance.registerToken(user.id));
    unawaited(PushNotificationService.instance.subscribeToPatient(patient.id));
  }

  void selectPatient(String patientId) {
    state = state.copyWith(selectedPatientId: patientId);
    unawaited(_refreshBackendPatientData(patientId));
  }

  void setChartDuration(ChartDuration duration) {
    state = state.copyWith(chartDuration: duration);
  }

  void setReadingFilter(GlucoseStatus? status) {
    state = state.copyWith(
      readingFilter: status,
      clearReadingFilter: status == null,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleDarkMode(bool enabled) {
    setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingComplete: true);
  }

  void updateConsent(ConsentPreferences preferences) {
    state = state.copyWith(consentPreferences: preferences);
  }

  void addMealLog({
    required MealType type,
    required String title,
    required int netCarbs,
    required int protein,
    required int fiber,
    required int activityMinutes,
    required String note,
  }) {
    final now = DateTime.now();
    final score = mealScore(
      netCarbs: netCarbs,
      protein: protein,
      fiber: fiber,
      activityMinutes: activityMinutes,
    );
    final label = title.trim().isEmpty ? _mealTypeLabel(type) : title.trim();
    final meal = MealLog(
      id: 'meal-${now.millisecondsSinceEpoch}',
      patientId: state.selectedPatientId,
      timestamp: now,
      type: type,
      title: label,
      netCarbs: netCarbs,
      protein: protein,
      fiber: fiber,
      activityMinutes: activityMinutes,
      score: score,
      note: note.trim(),
    );
    state = state.copyWith(meals: [meal, ...state.meals]);
    unawaited(_syncBackendMeal(meal));
  }

  void updateAlertSettings(AlertSettings settings) {
    final latestAlerts = _alertsForReadings(
      selectedReadings.takeLast(40),
      settings,
    );
    final newAlerts = latestAlerts.where(
      (alert) => !state.alerts.any((existing) => existing.id == alert.id),
    );
    final merged = <String, GlucoseAlert>{
      for (final alert in state.alerts) alert.id: alert,
      for (final alert in latestAlerts) alert.id: alert,
    };
    state = state.copyWith(
      alertSettings: settings,
      alerts: merged.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      notificationHistory: _mergeNotificationHistory(
        state.notificationHistory,
        _notificationRecordsForAlerts(newAlerts),
      ),
    );
    unawaited(_syncBackendAlertSettings(settings));
  }

  void acknowledgeAlert(String alertId) {
    state = state.copyWith(
      alerts: state.alerts
          .map(
            (alert) => alert.id == alertId
                ? alert.copyWith(acknowledged: true)
                : alert,
          )
          .toList(),
    );
    unawaited(_syncBackendAlertAcknowledgement(alertId));
  }

  void addClinicianNote({required String patientId, required String note}) {
    final cleanNote = note.trim();
    if (cleanNote.isEmpty) return;

    final now = DateTime.now();
    final user = state.currentUser;
    final noteRecord = ClinicianNote(
      id: 'note-${now.microsecondsSinceEpoch}',
      patientId: patientId,
      authorId: user?.id ?? 'doctor',
      authorName: user?.name ?? 'Clinician',
      createdAt: now,
      note: cleanNote,
    );
    state = state.copyWith(
      clinicianNotes: [noteRecord, ...state.clinicianNotes].take(100).toList(),
      auditLogs: _prependAudit(
        state.auditLogs,
        action: 'clinician_note_added',
        targetId: patientId,
        targetType: 'patient',
        details: 'Clinician note added for patient review.',
      ),
    );
  }

  void assignCareTask({
    required String patientId,
    required String title,
    String priority = 'routine',
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;

    final now = DateTime.now();
    final task = CareTask(
      id: 'task-${now.microsecondsSinceEpoch}',
      patientId: patientId,
      title: cleanTitle,
      ownerRole: state.currentUser?.role.name ?? 'doctor',
      status: 'open',
      priority: priority,
      createdAt: now,
      dueAt: now.add(
        priority == 'urgent'
            ? const Duration(hours: 4)
            : const Duration(days: 1),
      ),
    );
    state = state.copyWith(
      careTasks: [task, ...state.careTasks].take(120).toList(),
      auditLogs: _prependAudit(
        state.auditLogs,
        action: 'care_task_assigned',
        targetId: patientId,
        targetType: 'patient',
        details: 'Assigned $priority care task: $cleanTitle',
      ),
    );
  }

  void escalatePatient({required String patientId, required String reason}) {
    final cleanReason = reason.trim().isEmpty
        ? 'Urgent CGM review requested'
        : reason.trim();
    final now = DateTime.now();
    final task = CareTask(
      id: 'task-escalation-${now.microsecondsSinceEpoch}',
      patientId: patientId,
      title: 'Escalation review: $cleanReason',
      ownerRole: 'doctor',
      status: 'open',
      priority: 'urgent',
      createdAt: now,
      dueAt: now.add(const Duration(hours: 2)),
    );
    final notification = NotificationRecord(
      id: 'notification-escalation-${now.microsecondsSinceEpoch}',
      patientId: patientId,
      timestamp: now,
      title: 'Care escalation created',
      message: cleanReason,
      type: 'care_escalation',
      delivered: true,
      route: '/doctor',
    );
    state = state.copyWith(
      careTasks: [task, ...state.careTasks].take(120).toList(),
      notificationHistory: _mergeNotificationHistory(
        state.notificationHistory,
        [notification],
      ),
      auditLogs: _prependAudit(
        state.auditLogs,
        action: 'patient_escalated',
        targetId: patientId,
        targetType: 'patient',
        details: cleanReason,
      ),
    );
  }

  void completeCareTask(String taskId) {
    final now = DateTime.now();
    final task = state.careTasks.where((item) => item.id == taskId).firstOrNull;
    if (task == null) return;
    state = state.copyWith(
      careTasks: state.careTasks
          .map(
            (item) => item.id == taskId
                ? item.copyWith(status: 'completed', completedAt: now)
                : item,
          )
          .toList(),
      auditLogs: _prependAudit(
        state.auditLogs,
        action: 'care_task_completed',
        targetId: task.patientId,
        targetType: 'patient',
        details: 'Completed care task: ${task.title}',
      ),
    );
  }

  Future<ReportExport?> generateReportExport({
    String period = '14 day',
    String format = 'PDF',
  }) async {
    final now = DateTime.now();
    final patientId = state.selectedPatientId;
    final start = now.subtract(Duration(days: _periodDays(period)));
    final readings =
        state.readings
            .where(
              (reading) =>
                  reading.patientId == patientId &&
                  !_isDemoGlucoseReading(reading) &&
                  !reading.timestamp.isBefore(start) &&
                  !reading.timestamp.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (readings.isEmpty) return null;

    final summary = summarizeReadings(readings);
    final meals = state.meals
        .where(
          (meal) =>
              meal.patientId == patientId &&
              !meal.timestamp.isBefore(start) &&
              !meal.timestamp.isAfter(now),
        )
        .toList();
    final alerts = state.alerts
        .where(
          (alert) =>
              alert.patientId == patientId &&
              !alert.timestamp.isBefore(start) &&
              !alert.timestamp.isAfter(now),
        )
        .toList();
    final draft = ReportExport(
      id: 'report-${now.millisecondsSinceEpoch}',
      patientId: patientId,
      period: period,
      generatedAt: now,
      format: format,
      status: 'generating',
      summary:
          '${summary.timeInRange}% time in range, ${summary.average} mg/dL average, ${meals.length} meal log(s), and ${alerts.length} alert(s).',
      dateRangeStart: start,
      dateRangeEnd: now,
    );
    final report = await ReportExportService.createFiles(
      draft: draft,
      patient: selectedPatient,
      sensor: selectedSensor,
      readings: readings,
      meals: meals,
      alerts: alerts,
    );
    state = state.copyWith(
      reportExports: [report, ...state.reportExports],
      syncLogs: [
        SensorSyncLog(
          id: 'sync-report-${now.millisecondsSinceEpoch}',
          sensorId: selectedSensor?.id ?? 'sensor',
          patientId: patientId,
          event: 'Report export',
          status: report.status,
          timestamp: now,
          details:
              'Saved ${report.format} report for $period and registered ${report.backendRecordId ?? 'local record'}.',
        ),
        ...state.syncLogs,
      ],
      auditLogs: _prependAudit(
        state.auditLogs,
        action: 'report_generated',
        targetId: report.id,
        targetType: 'report',
        details: 'Generated ${report.format} care report for $period.',
      ),
    );
    unawaited(_syncBackendReport(report));
    return report;
  }

  void startSensorActivation() {
    state = state.copyWith(
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          status: SensorStatus.inactive,
          batteryStatus: 100,
          connectionStatus: ConnectionStatus.offline,
        ),
      ),
    );
  }

  void attachSensor() {
    state = state.copyWith(
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          status: SensorStatus.attached,
          connectionStatus: ConnectionStatus.nearby,
        ),
      ),
    );
  }

  void scanAndConnectSensor({String? serialNumber, bool previewOnly = false}) {
    final now = DateTime.now();
    final cleanSerial = _cleanSerial(serialNumber);
    final patient = selectedPatient;
    final sensorChanged =
        cleanSerial != null &&
        state.cgmSensorSn != null &&
        cleanSerial != state.cgmSensorSn;

    if (!previewOnly) {
      state = state.copyWith(
        cgmSensorSn: cleanSerial,
        cgmConnecting: true,
        cgmConnected: false,
        cgmWasEverConnected: sensorChanged ? false : state.cgmWasEverConnected,
        cgmConnectionStatus: 'Scanning for sensor',
        clearCgmLastError: true,
        clearCgmNearbyDevice: true,
        sensors: _updateActiveSensor(
          (sensor) => sensor.copyWith(
            serialNumber: cleanSerial ?? sensor.serialNumber,
            status: sensor.status == SensorStatus.inactive
                ? SensorStatus.attached
                : sensor.status,
            connectionStatus: ConnectionStatus.nearby,
          ),
        ),
        syncLogs: [
          SensorSyncLog(
            id: 'sync-${now.millisecondsSinceEpoch}',
            sensorId: patient?.sensorId ?? 'sensor-1',
            patientId: state.selectedPatientId,
            event: 'Sensor scan',
            status: 'pending',
            timestamp: now,
            details: 'Scanning for the sensor via the native CGM SDK.',
          ),
          ...state.syncLogs,
        ],
      );
      return;
    }

    final warmupEnd = now.add(const Duration(hours: 1));
    state = state.copyWith(
      cgmSensorSn: cleanSerial,
      cgmConnecting: false,
      cgmConnected: false,
      cgmConnectionStatus: 'Browser preview only',
      clearCgmLastError: true,
      clearCgmNearbyDevice: true,
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          serialNumber: cleanSerial ?? sensor.serialNumber,
          status: SensorStatus.warmingUp,
          warmupStartTime: now,
          warmupEndTime: warmupEnd,
          connectionStatus: ConnectionStatus.nearby,
        ),
      ),
      syncLogs: [
        SensorSyncLog(
          id: 'sync-${now.millisecondsSinceEpoch}',
          sensorId: patient?.sensorId ?? 'sensor-1',
          patientId: state.selectedPatientId,
          event: 'Sensor scan',
          status: 'success',
          timestamp: now,
          details:
              'Browser preview started the activation flow without native sensor connection.',
        ),
        ...state.syncLogs,
      ],
    );
  }

  void setCgmAuthState({required bool authorized, String? error}) {
    final safeError = error == null
        ? null
        : _englishOrDefault(error, 'SDK authorization failed.');
    if (safeError == null) {
      unawaited(AppLogFile.info('SDK authorization completed.', source: 'CGM'));
    } else {
      unawaited(AppLogFile.error(safeError, source: 'CGM authorization'));
    }
    state = state.copyWith(
      cgmAuthorized: authorized,
      cgmLastError: safeError,
      clearCgmLastError: safeError == null,
      cgmSdkLogs: _prependLog(
        authorized
            ? 'SDK authorization completed.'
            : 'SDK authorization failed.',
      ),
    );
  }

  void setCgmConnectionState({
    required String status,
    bool? connected,
    bool? connecting,
    String? sensorSn,
    String? error,
  }) {
    final isConnected = connected ?? state.cgmConnected;
    final now = DateTime.now();
    final cleanSerial = _cleanSerial(sensorSn);
    final safeStatus = _englishOrDefault(status, 'Sensor status updated.');
    final safeError = error == null
        ? null
        : _englishOrDefault(error, 'Sensor connection failed.');
    if (safeError == null) {
      unawaited(AppLogFile.info(safeStatus, source: 'CGM connection'));
    } else {
      unawaited(
        AppLogFile.error(safeError, source: 'CGM connection: $safeStatus'),
      );
    }
    if (isConnected && cleanSerial != null) {
      unawaited(PairedSensorStore.save(sensorSn: cleanSerial));
    }
    state = state.copyWith(
      cgmConnected: isConnected,
      cgmConnecting: connecting ?? false,
      cgmConnectionStatus: safeStatus,
      cgmSensorSn: cleanSerial ?? state.cgmSensorSn,
      cgmLastError: safeError,
      clearCgmLastError: safeError == null,
      cgmSdkLogs: _prependLog(safeStatus),
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          serialNumber: cleanSerial ?? sensor.serialNumber,
          status: isConnected
              ? sensor.status == SensorStatus.active
                    ? SensorStatus.active
                    : SensorStatus.warmingUp
              : sensor.status,
          warmupStartTime: isConnected
              ? sensor.warmupStartTime ?? now
              : sensor.warmupStartTime,
          warmupEndTime: isConnected
              ? sensor.warmupEndTime ?? now.add(const Duration(hours: 1))
              : sensor.warmupEndTime,
          connectionStatus: isConnected
              ? ConnectionStatus.connected
              : sensor.connectionStatus,
        ),
      ),
    );
  }

  void setCgmSyncProgress(int progress) {
    state = state.copyWith(cgmSyncProgress: progress.clamp(0, 100));
  }

  void addCgmLog(String message) {
    final safeMessage = _englishOrDefault(message, 'SDK event received.');
    unawaited(AppLogFile.info(safeMessage, source: 'CGM SDK'));
    state = state.copyWith(cgmSdkLogs: _prependLog(safeMessage));
  }

  void addSensorDisconnectAlert({String? sensorSn}) {
    if (!state.alertSettings.notificationsEnabled) return;

    final now = DateTime.now();
    final cleanSerial = _cleanSerial(sensorSn) ?? state.cgmSensorSn;
    final sensorLabel = cleanSerial == null ? 'sensor' : 'sensor $cleanSerial';
    final activeDisconnectAlert = state.alerts.any(
      (alert) =>
          alert.id.startsWith('sensor-disconnected-') && !alert.acknowledged,
    );
    if (activeDisconnectAlert) return;

    final alert = GlucoseAlert(
      id: 'sensor-disconnected-${cleanSerial ?? state.selectedPatientId}-${now.millisecondsSinceEpoch}',
      patientId: state.selectedPatientId,
      timestamp: now,
      title: 'Sensor disconnected',
      message:
          'Your $sensorLabel is not connected. Keep the phone nearby and make sure Bluetooth is on.',
      value: 0,
      threshold: 0,
      severity: AlertSeverity.warning,
      acknowledged: false,
    );
    state = state.copyWith(
      alerts: [alert, ...state.alerts],
      notificationHistory: _mergeNotificationHistory(
        state.notificationHistory,
        _notificationRecordsForAlerts([alert]),
      ),
      auditLogs: _prependAudit(
        state.auditLogs,
        action: 'sensor_disconnect_alert',
        targetId: state.selectedPatientId,
        targetType: 'patient',
        details: alert.message,
      ),
    );
  }

  void setCgmNearbyDevice({String? name, String? address, int? rssi}) {
    final cleanName = _englishOrNull(name);
    final cleanAddress = _englishOrNull(address);
    state = state.copyWith(
      cgmNearbyDeviceName: cleanName == null || cleanName.isEmpty
          ? null
          : cleanName,
      cgmNearbyDeviceAddress: cleanAddress == null || cleanAddress.isEmpty
          ? null
          : cleanAddress,
      cgmNearbyDeviceRssi: rssi,
    );
  }

  void applyCgmDeviceInfo(Map<String, dynamic> info) {
    final now = DateTime.now();
    final sdkSensorState = info['sensorState'] is num
        ? (info['sensorState'] as num).toInt()
        : null;
    final isExpired =
        info['isExpired'] == true ||
        sdkSensorState == 3 ||
        sdkSensorState == 4 ||
        sdkSensorState == 5;
    final isPreheating = info['isPreheating'] == true || sdkSensorState == 1;
    final isInUse = info['isInUse'] == true || sdkSensorState == 2;
    final battery = info['battery'] is num
        ? (info['battery'] as num).toInt().clamp(0, 100)
        : null;
    final activationTimestamp = _firstIntValue([
      info['deviceActivateTimestamp'],
      info['sensorStartTime'],
    ]);
    final activationDate =
        activationTimestamp == null || activationTimestamp <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(activationTimestamp * 1000);

    state = state.copyWith(
      cgmConnected: isInUse || state.cgmConnected,
      cgmConnecting: false,
      cgmConnectionStatus: isExpired
          ? 'Sensor expired'
          : isPreheating
          ? 'Sensor warming up'
          : isInUse
          ? 'Sensor active'
          : state.cgmConnectionStatus,
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          status: isExpired
              ? SensorStatus.expired
              : isPreheating
              ? SensorStatus.warmingUp
              : isInUse
              ? SensorStatus.active
              : sensor.status,
          batteryStatus: battery ?? sensor.batteryStatus,
          activationDate: activationDate ?? sensor.activationDate,
          expiryDate:
              activationDate?.add(const Duration(days: 14)) ??
              sensor.expiryDate,
          warmupStartTime: isPreheating
              ? sensor.warmupStartTime ?? now
              : sensor.warmupStartTime,
          warmupEndTime: isPreheating
              ? sensor.warmupEndTime ?? now.add(const Duration(hours: 1))
              : sensor.warmupEndTime,
          connectionStatus: isInUse || state.cgmConnected
              ? ConnectionStatus.connected
              : sensor.connectionStatus,
        ),
      ),
    );
    _appendSafetyAlerts();
  }

  void applyCgmReadings(List<CgmBloodSugarReading> sdkReadings) {
    if (sdkReadings.isEmpty) return;

    final patient = selectedPatient ?? state.patients.first;
    final sensor = state.sensors.firstWhere(
      (item) => item.id == patient.sensorId,
      orElse: () => state.sensors.first,
    );
    final sensorSerial =
        _cleanSerial(state.cgmSensorSn ?? sensor.serialNumber) ??
        sensor.serialNumber;
    final converted = sdkReadings.map((reading) {
      final value = _sdkGlucoseToMgDl(reading.processedBloodSugar);
      final clientReadingId =
          'sdk:$sensorSerial:${reading.createTime}:${reading.timeOffset}';
      return OptimusGlucoseReading(
        id: clientReadingId,
        clientReadingId: clientReadingId,
        sensorId: sensor.id,
        patientId: patient.id,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          reading.createTime * 1000,
        ),
        value: value,
        unit: 'mg/dL',
        trend: _sdkTrend(reading.trend),
        status: statusFromValue(value),
      );
    }).toList();

    final byId = <String, OptimusGlucoseReading>{
      for (final reading in state.readings)
        if (!_isDemoGlucoseReading(reading)) reading.id: reading,
      for (final reading in converted) reading.id: reading,
    };
    final merged = byId.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final incomingAlerts = _alertsForReadings(converted, state.alertSettings);
    final urgentTasks = _careTasksForUrgentAlerts(
      incomingAlerts,
      state.careTasks,
    );
    var auditLogs = state.auditLogs;
    for (final task in urgentTasks) {
      auditLogs = _prependAudit(
        auditLogs,
        action: 'urgent_glucose_escalated',
        targetId: task.patientId,
        targetType: 'patient',
        details: task.title,
      );
    }

    state = state.copyWith(
      readings: merged,
      alerts: _mergeAlerts(state.alerts, incomingAlerts),
      notificationHistory: _mergeNotificationHistory(
        state.notificationHistory,
        _notificationRecordsForAlerts(incomingAlerts),
      ),
      careTasks: [...urgentTasks, ...state.careTasks].take(120).toList(),
      auditLogs: auditLogs,
      cgmConnected: true,
      cgmConnecting: false,
      cgmConnectionStatus: 'Live glucose data received',
      sensors: _updateActiveSensor(
        (item) => item.copyWith(
          status: SensorStatus.active,
          connectionStatus: ConnectionStatus.connected,
        ),
      ),
      syncLogs: [
        SensorSyncLog(
          id: 'sync-sdk-${DateTime.now().millisecondsSinceEpoch}',
          sensorId: sensor.id,
          patientId: patient.id,
          event: 'SDK reading sync',
          status: 'success',
          timestamp: DateTime.now(),
          details: '${sdkReadings.length} live SDK reading(s) received.',
        ),
        ...state.syncLogs,
      ],
    );
    _appendSafetyAlerts();
    unawaited(_persistLiveReadings());
    unawaited(_syncBackendReadings(converted));
  }

  Future<void> restorePersistentReadings() async {
    if (_persistentReadingsRestored) return;
    _persistentReadingsRestored = true;

    final cached = await PersistentGlucoseReadingCache.load();
    if (cached.isEmpty) return;

    final byId = <String, OptimusGlucoseReading>{
      for (final reading in state.readings)
        if (!_isDemoGlucoseReading(reading)) reading.id: reading,
      for (final reading in cached) reading.id: reading,
    };
    final merged = byId.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    state = state.copyWith(
      readings: merged,
      cgmSdkLogs: _prependLog(
        'Offline glucose cache restored (${cached.length} reading${cached.length == 1 ? '' : 's'}).',
      ),
    );
    _appendSafetyAlerts();
  }

  Future<void> restorePairedSensor() async {
    if (state.cgmSensorSn != null) return;

    final sensorSn = await PairedSensorStore.loadSensorSn();
    if (sensorSn == null) return;

    state = state.copyWith(
      cgmSensorSn: sensorSn,
      cgmWasEverConnected: true,
      cgmConnectionStatus: 'Paired sensor saved locally',
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          serialNumber: sensorSn,
          connectionStatus: ConnectionStatus.nearby,
        ),
      ),
      cgmSdkLogs: _prependLog('Paired sensor restored for offline reconnect.'),
    );
    _appendSafetyAlerts();
  }

  void finishWarmupNow() {
    final now = DateTime.now();
    state = state.copyWith(
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          status: SensorStatus.active,
          activationDate: now,
          expiryDate: now.add(const Duration(days: 14)),
          warmupEndTime: now,
          connectionStatus: ConnectionStatus.connected,
        ),
      ),
    );
  }

  void placeReorder(int quantity, String shippingAddress) {
    final now = DateTime.now();
    final order = Order(
      id: 'order-${now.millisecondsSinceEpoch}',
      patientId: state.activePatientId,
      productName: 'Optimus CGM 14-day sensor',
      quantity: quantity,
      status: 'placed',
      shippingAddress: shippingAddress,
      createdAt: now,
    );
    state = state.copyWith(orders: [order, ...state.orders]);
    unawaited(_syncBackendOrder(order));
  }

  void connectIntegration(String integrationId) {
    state = state.copyWith(
      integrations: state.integrations
          .map(
            (integration) => integration.id == integrationId
                ? integration.copyWith(
                    status: 'connected',
                    lastSync: DateTime.now(),
                  )
                : integration,
          )
          .toList(),
    );
  }

  Patient _preferredBackendPatient(List<Patient> patients) {
    return patients.firstWhere(
      (patient) => patient.id == state.selectedPatientId,
      orElse: () => patients.first,
    );
  }

  Future<void> _refreshBackendPatientData(String patientId) async {
    if (!ref.read(backendSyncEnabledProvider)) return;

    try {
      await ref.read(backendSessionProvider).ensureSession();
      final patientRepository = ref.read(patientRepositoryProvider);
      final alertRepository = ref.read(alertRepositoryProvider);
      final sensors = await patientRepository.getSensors(patientId: patientId);
      final readings = await _loadBackendReadings(
        patientRepository,
        patientId: patientId,
      );
      final meals = await patientRepository.getMeals(patientId: patientId);
      final interpretations = await patientRepository.getInterpretations(
        patientId: patientId,
      );
      final orders = await patientRepository.getOrders(patientId: patientId);
      final alerts = await alertRepository.getAlerts(patientId: patientId);
      final alertSettings = await alertRepository.getAlertSettings(
        patientId: patientId,
      );
      final reports = await alertRepository.getReports(patientId: patientId);

      state = state.copyWith(
        sensors: _replacePatientScopedSensors(sensors, patientId),
        readings: _replacePatientScopedReadings(readings, patientId),
        meals: _replacePatientScopedMeals(meals, patientId),
        aiInterpretations: _replacePatientScopedInterpretations(
          interpretations,
          patientId,
        ),
        orders: _replacePatientScopedOrders(orders, patientId),
        alerts: _replacePatientScopedAlerts(alerts, patientId),
        alertSettings: alertSettings,
        reportExports: _replacePatientScopedReports(reports, patientId),
      );
    } catch (error) {
      _recordBackendSyncFailure('Patient data refresh', error);
    }
  }

  Future<void> _syncBackendReadings(
    List<OptimusGlucoseReading> readings,
  ) async {
    if (!ref.read(backendSyncEnabledProvider) || readings.isEmpty) return;

    final pending = readings
        .where(
          (reading) =>
              !_backendSyncedReadingIds.contains(_readingIdentity(reading)),
        )
        .toList();
    if (pending.isEmpty) return;

    final pendingIds = pending.map(_readingIdentity).toList();
    _backendSyncedReadingIds.addAll(pendingIds);

    try {
      await ref.read(backendSessionProvider).ensureSession();
      var uploadReadings = pending;
      final sensorSerial = _cleanSerial(state.cgmSensorSn);
      if (sensorSerial != null) {
        final backendSensor = await _registerBackendSensor(sensorSerial);
        uploadReadings = pending
            .map((reading) => reading.copyWith(sensorId: backendSensor.id))
            .toList();
      }
      final savedReadings = await ref
          .read(patientRepositoryProvider)
          .addReadings(
            patientId: uploadReadings.first.patientId,
            readings: uploadReadings,
          );
      if (savedReadings.isNotEmpty) {
        state = state.copyWith(
          readings: _replacePatientScopedReadings(
            savedReadings,
            uploadReadings.first.patientId,
          ),
        );
        unawaited(_persistLiveReadings());
      }
      await _refreshBackendAlerts(pending.first.patientId);
    } catch (error) {
      _backendSyncedReadingIds.removeAll(pendingIds);
      _recordBackendSyncFailure('Reading upload', error);
    }
  }

  Future<Sensor?> registerConnectedSensor({
    required String serialNumber,
  }) async {
    if (!ref.read(backendSyncEnabledProvider)) return selectedSensor;

    try {
      return await _registerBackendSensor(serialNumber);
    } catch (error) {
      _recordBackendSyncFailure('Sensor registration', error);
      return null;
    }
  }

  Future<Sensor> _registerBackendSensor(String serialNumber) async {
    final normalized = _cleanSerial(serialNumber);
    if (normalized == null) {
      throw ArgumentError.value(
        serialNumber,
        'serialNumber',
        'Invalid sensor serial',
      );
    }

    final cachedId = _backendSensorIdsBySerial[normalized];
    final cachedSensor = cachedId == null
        ? null
        : state.sensors.where((sensor) => sensor.id == cachedId).firstOrNull;
    if (cachedSensor != null) return cachedSensor;

    await ref.read(backendSessionProvider).ensureSession();
    final patientId = state.selectedPatientId;
    final sensor = await ref
        .read(patientRepositoryProvider)
        .registerSensor(patientId: patientId, serialNumber: normalized);
    _backendSensorIdsBySerial[normalized] = sensor.id;

    state = state.copyWith(
      patients: state.patients
          .map(
            (patient) => patient.id == patientId
                ? patient.copyWith(sensorId: sensor.id)
                : patient,
          )
          .toList(),
      sensors: [sensor, ...state.sensors.where((item) => item.id != sensor.id)],
      cgmSensorSn: normalized,
    );
    return sensor;
  }

  Future<List<OptimusGlucoseReading>> _loadBackendReadings(
    PatientRepository repository, {
    required String patientId,
  }) async {
    const pageSize = 1000;
    final from = DateTime.now().subtract(const Duration(days: 14));
    final readings = <OptimusGlucoseReading>[];
    var offset = 0;

    while (true) {
      final page = await repository.getReadings(
        patientId: patientId,
        from: from,
        limit: pageSize,
        offset: offset,
      );
      readings.addAll(page);
      if (page.length < pageSize) break;
      offset += page.length;
    }

    return readings;
  }

  Future<void> _syncBackendMeal(MealLog meal) async {
    if (!ref.read(backendSyncEnabledProvider)) return;

    try {
      await ref.read(backendSessionProvider).ensureSession();
      final saved = await ref.read(patientRepositoryProvider).addMeal(meal);
      state = state.copyWith(
        meals: [
          saved,
          ...state.meals.where(
            (item) => item.id != meal.id && item.id != saved.id,
          ),
        ],
      );
    } catch (error) {
      _recordBackendSyncFailure('Meal upload', error);
    }
  }

  Future<void> _syncBackendOrder(Order order) async {
    if (!ref.read(backendSyncEnabledProvider)) return;

    try {
      await ref.read(backendSessionProvider).ensureSession();
      final saved = await ref.read(patientRepositoryProvider).placeOrder(order);
      state = state.copyWith(
        orders: [
          saved,
          ...state.orders.where(
            (item) => item.id != order.id && item.id != saved.id,
          ),
        ],
      );
    } catch (error) {
      _recordBackendSyncFailure('Order upload', error);
    }
  }

  Future<void> _syncBackendAlertSettings(AlertSettings settings) async {
    if (!ref.read(backendSyncEnabledProvider)) return;

    try {
      await ref.read(backendSessionProvider).ensureSession();
      await ref
          .read(alertRepositoryProvider)
          .updateAlertSettings(
            patientId: state.selectedPatientId,
            settings: settings,
          );
    } catch (error) {
      _recordBackendSyncFailure('Alert settings upload', error);
    }
  }

  Future<void> _syncBackendAlertAcknowledgement(String alertId) async {
    if (!ref.read(backendSyncEnabledProvider)) return;

    try {
      await ref.read(backendSessionProvider).ensureSession();
      await ref.read(alertRepositoryProvider).acknowledgeAlert(alertId);
    } catch (error) {
      _recordBackendSyncFailure('Alert acknowledgement upload', error);
    }
  }

  Future<void> _syncBackendReport(ReportExport report) async {
    if (!ref.read(backendSyncEnabledProvider)) return;

    try {
      await ref.read(backendSessionProvider).ensureSession();
      final saved = await ref
          .read(alertRepositoryProvider)
          .generateReport(
            patientId: report.patientId,
            period: report.period,
            format: report.format,
          );
      state = state.copyWith(
        reportExports: state.reportExports.map((item) {
          if (item.id != report.id) return item;
          return item.copyWith(
            backendRecordId: saved.backendRecordId ?? saved.id,
            shareLink: saved.shareLink ?? item.shareLink,
          );
        }).toList(),
      );
    } catch (error) {
      _recordBackendSyncFailure('Report registration', error);
    }
  }

  Future<void> _refreshBackendAlerts(String patientId) async {
    final alertRepository = ref.read(alertRepositoryProvider);
    final alerts = await alertRepository.getAlerts(patientId: patientId);
    final settings = await alertRepository.getAlertSettings(
      patientId: patientId,
    );
    state = state.copyWith(
      alerts: _replacePatientScopedAlerts(alerts, patientId),
      alertSettings: settings,
    );
  }

  void _recordBackendSyncFailure(String event, Object error) {
    final now = DateTime.now();
    state = state.copyWith(
      syncLogs: [
        SensorSyncLog(
          id: 'sync-backend-error-${now.microsecondsSinceEpoch}',
          sensorId: selectedSensor?.id ?? 'sensor',
          patientId: state.selectedPatientId,
          event: event,
          status: 'failed',
          timestamp: now,
          details: error.toString(),
        ),
        ...state.syncLogs,
      ].take(120).toList(),
      cgmSdkLogs: _prependLog('$event failed.'),
    );
  }

  List<Sensor> _replacePatientScopedSensors(
    List<Sensor> incoming,
    String patientId,
  ) {
    if (incoming.isEmpty) return state.sensors;
    return [
      ...incoming,
      ...state.sensors.where((item) => item.patientId != patientId),
    ];
  }

  List<OptimusGlucoseReading> _replacePatientScopedReadings(
    List<OptimusGlucoseReading> incoming,
    String patientId,
  ) {
    final byIdentity = <String, OptimusGlucoseReading>{
      for (final reading in state.readings.where(
        (item) => item.patientId != patientId,
      ))
        _readingIdentity(reading): reading,
      for (final reading in state.readings.where(
        (item) => item.patientId == patientId,
      ))
        _readingIdentity(reading): reading,
      for (final reading in incoming) _readingIdentity(reading): reading,
    };
    final readings = byIdentity.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return readings;
  }

  String _readingIdentity(OptimusGlucoseReading reading) {
    final clientReadingId = reading.clientReadingId;
    return clientReadingId == null || clientReadingId.isEmpty
        ? reading.id
        : clientReadingId;
  }

  List<MealLog> _replacePatientScopedMeals(
    List<MealLog> incoming,
    String patientId,
  ) {
    return [
      ...incoming,
      ...state.meals.where((item) => item.patientId != patientId),
    ];
  }

  List<AIInterpretation> _replacePatientScopedInterpretations(
    List<AIInterpretation> incoming,
    String patientId,
  ) {
    return [
      ...incoming,
      ...state.aiInterpretations.where((item) => item.patientId != patientId),
    ];
  }

  List<Order> _replacePatientScopedOrders(
    List<Order> incoming,
    String patientId,
  ) {
    return [
      ...incoming,
      ...state.orders.where((item) => item.patientId != patientId),
    ];
  }

  List<GlucoseAlert> _replacePatientScopedAlerts(
    List<GlucoseAlert> incoming,
    String patientId,
  ) {
    return [
      ...incoming,
      ...state.alerts.where((item) => item.patientId != patientId),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<ReportExport> _replacePatientScopedReports(
    List<ReportExport> incoming,
    String patientId,
  ) {
    return [
      ...incoming,
      ...state.reportExports.where((item) => item.patientId != patientId),
    ]..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
  }

  List<Sensor> _updateActiveSensor(Sensor Function(Sensor sensor) updater) {
    final patient = selectedPatient ?? state.patients.first;
    return state.sensors
        .map(
          (sensor) => sensor.id == patient.sensorId ? updater(sensor) : sensor,
        )
        .toList();
  }

  List<String> _prependLog(String message) {
    final time = DateTime.now();
    final stamp =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return ['$stamp  $message', ...state.cgmSdkLogs].take(20).toList();
  }

  String? _cleanSerial(String? value) {
    return normalizeSensorSerial(value);
  }

  int _sdkGlucoseToMgDl(double value) {
    final mgDl = value > 25 ? value : value * 18.0182;
    return mgDl.round().clamp(0, 500);
  }

  int? _firstIntValue(List<Object?> values) {
    for (final value in values) {
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  TrendDirection _sdkTrend(int trend) {
    return switch (trend) {
      15 => TrendDirection.risingFast,
      5 => TrendDirection.rising,
      20 => TrendDirection.fallingFast,
      10 => TrendDirection.falling,
      _ => TrendDirection.steady,
    };
  }

  OptimusRole _inferRole(String email) {
    return optimusUsers
        .firstWhere(
          (user) => user.email.toLowerCase() == email.trim().toLowerCase(),
          orElse: () => optimusUsers.first,
        )
        .role;
  }

  OptimusUser _userForRole(OptimusRole role) {
    return optimusUsers.firstWhere((user) => user.role == role);
  }

  Patient _patientForRole(OptimusRole role) {
    if (role == OptimusRole.doctor) {
      return state.patients.firstWhere(
        (patient) => patient.doctorId == 'doctor-1',
      );
    }
    return state.patients.first;
  }

  Patient? get selectedPatient => state.patients
      .where((patient) => patient.id == state.selectedPatientId)
      .firstOrNull;

  Sensor? get selectedSensor {
    final patient = selectedPatient;
    if (patient == null) return null;
    return state.sensors
        .where((sensor) => sensor.id == patient.sensorId)
        .firstOrNull;
  }

  List<OptimusGlucoseReading> get selectedReadings {
    return state.readings
        .where(
          (reading) =>
              reading.patientId == state.selectedPatientId &&
              !_isDemoGlucoseReading(reading),
        )
        .toList();
  }

  String _mealTypeLabel(MealType type) {
    return switch (type) {
      MealType.breakfast => 'Breakfast',
      MealType.lunch => 'Lunch',
      MealType.dinner => 'Dinner',
      MealType.snack => 'Snack',
    };
  }

  int _periodDays(String period) {
    final match = RegExp(r'\d+').firstMatch(period);
    final days = int.tryParse(match?.group(0) ?? '') ?? 14;
    return days.clamp(1, 90).toInt();
  }

  List<AuditLogEntry> _prependAudit(
    List<AuditLogEntry> existing, {
    required String action,
    required String targetId,
    required String targetType,
    required String details,
  }) {
    final now = DateTime.now();
    final user = state.currentUser;
    return [
      AuditLogEntry(
        id: 'audit-${now.microsecondsSinceEpoch}',
        actorId: user?.id ?? 'system',
        actorRole: user?.role.name ?? 'system',
        action: action,
        targetId: targetId,
        targetType: targetType,
        timestamp: now,
        details: details,
      ),
      ...existing,
    ].take(120).toList();
  }

  void _appendSafetyAlerts() {
    final safetyAlerts = _safetyAlertsForState(state);
    if (safetyAlerts.isEmpty) return;

    final urgentTasks = _careTasksForUrgentAlerts(
      safetyAlerts,
      state.careTasks,
    );
    var auditLogs = state.auditLogs;
    for (final alert in safetyAlerts) {
      auditLogs = _prependAudit(
        auditLogs,
        action: 'safety_alert_created',
        targetId: alert.patientId,
        targetType: 'patient',
        details: alert.title,
      );
    }
    for (final task in urgentTasks) {
      auditLogs = _prependAudit(
        auditLogs,
        action: 'urgent_alert_escalated',
        targetId: task.patientId,
        targetType: 'patient',
        details: task.title,
      );
    }

    state = state.copyWith(
      alerts: _mergeAlerts(state.alerts, safetyAlerts),
      notificationHistory: _mergeNotificationHistory(
        state.notificationHistory,
        _notificationRecordsForAlerts(safetyAlerts),
      ),
      careTasks: [...urgentTasks, ...state.careTasks].take(120).toList(),
      auditLogs: auditLogs,
    );
  }

  List<GlucoseAlert> _safetyAlertsForState(AppState source) {
    if (!source.alertSettings.notificationsEnabled) return const [];

    final now = DateTime.now();
    final patient = source.patients
        .where((item) => item.id == source.selectedPatientId)
        .firstOrNull;
    if (patient == null) return const [];

    final sensor = source.sensors
        .where((item) => item.id == patient.sensorId)
        .firstOrNull;
    final patientReadings =
        source.readings
            .where(
              (reading) =>
                  reading.patientId == patient.id &&
                  !_isDemoGlucoseReading(reading),
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final alerts = <GlucoseAlert>[];

    if (sensor != null) {
      final expiry = sensor.expiryDate;
      final expired =
          sensor.status == SensorStatus.expired ||
          (expiry != null && !expiry.isAfter(now));
      final expiresSoon =
          expiry != null &&
          expiry.isAfter(now) &&
          expiry.difference(now).inHours <= 24;
      final prefix = 'sensor-expiry-${sensor.id}';
      if ((expired || expiresSoon) &&
          !_hasOpenAlertWithPrefix(source.alerts, patient.id, prefix)) {
        alerts.add(
          GlucoseAlert(
            id: '$prefix-${now.millisecondsSinceEpoch}',
            patientId: patient.id,
            timestamp: now,
            title: expired ? 'Sensor expired' : 'Sensor expires soon',
            message: expired
                ? 'Replace the sensor to keep glucose readings current.'
                : 'This sensor expires within 24 hours. Keep a replacement ready.',
            value: 0,
            threshold: 0,
            severity: expired ? AlertSeverity.urgent : AlertSeverity.warning,
            acknowledged: false,
          ),
        );
      }
    }

    if (source.cgmWasEverConnected &&
        !source.cgmConnecting &&
        patientReadings.isNotEmpty) {
      final latest = patientReadings.last;
      final staleMinutes = now.difference(latest.timestamp).inMinutes;
      final threshold = source.alertSettings.sensorDisconnectReminderMinutes;
      const prefix = 'stale-reading';
      if (staleMinutes >= threshold &&
          !_hasOpenAlertWithPrefix(
            source.alerts,
            patient.id,
            '$prefix-${patient.id}',
          )) {
        alerts.add(
          GlucoseAlert(
            id: '$prefix-${patient.id}-${latest.timestamp.millisecondsSinceEpoch}',
            patientId: patient.id,
            timestamp: now,
            title: 'Stale glucose reading',
            message:
                'No new CGM reading has arrived for $staleMinutes minutes. Check sensor connection and confirm with a finger-prick reading if needed.',
            value: latest.value,
            threshold: threshold,
            severity: AlertSeverity.warning,
            acknowledged: false,
          ),
        );
      }
    }

    if (patientReadings.length >= 2 && isRapidGlucoseChange(patientReadings)) {
      final latest = patientReadings.last;
      final prefix = 'rapid-change-${patient.id}-${latest.id}';
      if (!_hasOpenAlertWithPrefix(source.alerts, patient.id, prefix)) {
        alerts.add(
          GlucoseAlert(
            id: '$prefix-${now.millisecondsSinceEpoch}',
            patientId: patient.id,
            timestamp: latest.timestamp,
            title: 'Rapid glucose change',
            message:
                'Glucose is changing quickly. Review trend context and confirm with BGM if symptoms do not match.',
            value: latest.value,
            threshold: 45,
            severity: AlertSeverity.warning,
            acknowledged: false,
          ),
        );
      }
    }

    return alerts;
  }

  bool _hasOpenAlertWithPrefix(
    List<GlucoseAlert> alerts,
    String patientId,
    String prefix,
  ) {
    return alerts.any(
      (alert) =>
          alert.patientId == patientId &&
          alert.id.startsWith(prefix) &&
          !alert.acknowledged,
    );
  }

  List<NotificationRecord> _notificationRecordsForAlerts(
    Iterable<GlucoseAlert> alerts,
  ) {
    return alerts
        .map(
          (alert) => NotificationRecord(
            id: 'notification-${alert.id}',
            patientId: alert.patientId,
            timestamp: alert.timestamp,
            title: alert.title,
            message: alert.message,
            type: alert.id.startsWith('sensor-expiry-')
                ? 'sensor_expiry'
                : alert.id.startsWith('stale-reading-') ||
                      alert.id.startsWith('sensor-disconnected-')
                ? 'sensor_status'
                : 'glucose_alert',
            delivered: true,
            route: alert.id.startsWith('sensor-') ? '/sensor' : '/alerts',
          ),
        )
        .toList();
  }

  List<NotificationRecord> _mergeNotificationHistory(
    List<NotificationRecord> existing,
    Iterable<NotificationRecord> incoming,
  ) {
    final byId = <String, NotificationRecord>{
      for (final record in existing) record.id: record,
      for (final record in incoming) record.id: record,
    };
    final records = byId.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records.take(120).toList();
  }

  List<CareTask> _careTasksForUrgentAlerts(
    Iterable<GlucoseAlert> alerts,
    List<CareTask> existing,
  ) {
    final existingIds = existing.map((task) => task.id).toSet();
    return alerts
        .where((alert) => alert.severity == AlertSeverity.urgent)
        .map((alert) {
          final id = 'task-${alert.id}';
          if (existingIds.contains(id)) return null;
          final valueText = alert.value > 0 ? ' (${alert.value} mg/dL)' : '';
          return CareTask(
            id: id,
            patientId: alert.patientId,
            title: 'Urgent review: ${alert.title}$valueText',
            ownerRole: 'doctor',
            status: 'open',
            priority: 'urgent',
            createdAt: alert.timestamp,
            dueAt: alert.timestamp.add(const Duration(hours: 2)),
          );
        })
        .whereType<CareTask>()
        .toList();
  }

  List<GlucoseAlert> _mergeAlerts(
    List<GlucoseAlert> existing,
    List<GlucoseAlert> incoming,
  ) {
    final byId = <String, GlucoseAlert>{
      for (final alert in existing) alert.id: alert,
      for (final alert in incoming) alert.id: alert,
    };
    return byId.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<GlucoseAlert> _alertsForReadings(
    Iterable<OptimusGlucoseReading> readings,
    AlertSettings settings,
  ) {
    if (!settings.notificationsEnabled) return const [];

    return readings
        .where((reading) {
          final high = reading.value >= settings.highThreshold;
          final low = reading.value <= settings.lowThreshold;
          final urgent = reading.value <= 55 || reading.value >= 250 || low;
          if (settings.quietHoursEnabled &&
              _isQuietHour(reading.timestamp) &&
              high &&
              !urgent) {
            return false;
          }
          return low || high;
        })
        .map((reading) {
          final high = reading.value >= settings.highThreshold;
          final urgentHigh = reading.value >= 250;
          final urgentLow = reading.value <= 55;
          final urgent = !high || urgentHigh;
          return GlucoseAlert(
            id: 'alert-${reading.id}',
            patientId: reading.patientId,
            timestamp: reading.timestamp,
            title: high
                ? urgentHigh
                      ? 'Urgent high glucose alert'
                      : 'High glucose alert'
                : urgentLow
                ? 'Urgent low glucose alert'
                : 'Low glucose alert',
            message: high
                ? urgentHigh
                      ? 'Glucose is very high. Follow your clinician-approved safety plan and confirm with a finger-prick meter if needed.'
                      : 'Glucose crossed ${settings.highThreshold} mg/dL. Review food, activity, and care-team guidance.'
                : 'Glucose dropped below ${settings.lowThreshold} mg/dL. Follow your clinician-approved safety plan.',
            value: reading.value,
            threshold: high ? settings.highThreshold : settings.lowThreshold,
            severity: urgent ? AlertSeverity.urgent : AlertSeverity.warning,
            acknowledged: false,
          );
        })
        .toList();
  }

  bool _isQuietHour(DateTime timestamp) {
    final hour = timestamp.toLocal().hour;
    return hour >= 22 || hour < 7;
  }

  Future<void> _persistLiveReadings() {
    return PersistentGlucoseReadingCache.save(
      state.readings.where(_isSdkGlucoseReading),
    );
  }
}

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

final backendBootstrapProvider = Provider<void>((ref) {
  if (!ref.watch(backendSyncEnabledProvider)) return;
  final controller = ref.read(appControllerProvider.notifier);
  unawaited(controller.bootstrapBackend());
});

final persistentReadingBootstrapProvider = Provider<void>((ref) {
  final controller = ref.read(appControllerProvider.notifier);
  unawaited(controller.restorePersistentReadings());
});

final pairedSensorBootstrapProvider = Provider<void>((ref) {
  final controller = ref.read(appControllerProvider.notifier);
  unawaited(controller.restorePairedSensor());
});

final selectedPatientProvider = Provider<Patient?>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.patients
      .where((patient) => patient.id == state.selectedPatientId)
      .firstOrNull;
});

final selectedSensorProvider = Provider<Sensor?>((ref) {
  final state = ref.watch(appControllerProvider);
  final patient = ref.watch(selectedPatientProvider);
  return state.sensors
      .where((sensor) => sensor.id == patient?.sensorId)
      .firstOrNull;
});

bool _isDemoGlucoseReading(OptimusGlucoseReading reading) {
  return reading.id.startsWith('opt-reading-');
}

bool _isSdkGlucoseReading(OptimusGlucoseReading reading) {
  return reading.id.startsWith('sdk:') ||
      reading.id.startsWith('sdk-') ||
      reading.clientReadingId?.startsWith('sdk:') == true;
}

final selectedPatientReadingsProvider = Provider<List<OptimusGlucoseReading>>((
  ref,
) {
  final state = ref.watch(appControllerProvider);
  final patientId = state.selectedPatientId;
  final byIdentity = <String, OptimusGlucoseReading>{};
  for (final reading in state.readings) {
    if (reading.patientId != patientId || _isDemoGlucoseReading(reading)) {
      continue;
    }
    final clientReadingId = reading.clientReadingId;
    final identity = clientReadingId == null || clientReadingId.isEmpty
        ? reading.id
        : clientReadingId;
    byIdentity[identity] = reading;
  }
  final readings = byIdentity.values.toList();
  return readings..sort((a, b) => a.timestamp.compareTo(b.timestamp));
});

final selectedReadingsProvider = Provider<List<OptimusGlucoseReading>>((ref) {
  final state = ref.watch(appControllerProvider);
  final readings = ref.watch(selectedPatientReadingsProvider);
  final filtered = filterReadingsByDuration(readings, state.chartDuration);
  final status = state.readingFilter;
  if (status == null) return filtered;
  return filtered.where((reading) => reading.status == status).toList();
});

final latestReadingProvider = Provider<OptimusGlucoseReading?>((ref) {
  final readings = ref.watch(selectedReadingsProvider);
  return readings.isEmpty ? null : readings.last;
});

final summaryProvider = Provider((ref) {
  final readings = ref.watch(selectedReadingsProvider);
  return summarizeReadings(readings);
});

final selectedMealsProvider = Provider<List<MealLog>>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.meals
      .where((meal) => meal.patientId == state.selectedPatientId)
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

final activeAlertsProvider = Provider<List<GlucoseAlert>>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.alerts
      .where(
        (alert) =>
            alert.patientId == state.selectedPatientId && !alert.acknowledged,
      )
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

final selectedReportExportsProvider = Provider<List<ReportExport>>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.reportExports
      .where((report) => report.patientId == state.selectedPatientId)
      .toList()
    ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
});

final selectedNotificationHistoryProvider = Provider<List<NotificationRecord>>((
  ref,
) {
  final state = ref.watch(appControllerProvider);
  return state.notificationHistory
      .where((record) => record.patientId == state.selectedPatientId)
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

class PatientRiskProfile {
  const PatientRiskProfile({
    required this.patient,
    required this.sensor,
    required this.latestReading,
    required this.activeAlerts,
    required this.riskScore,
    required this.riskLevel,
    required this.reason,
    required this.needsReview,
  });

  final Patient patient;
  final Sensor? sensor;
  final OptimusGlucoseReading? latestReading;
  final List<GlucoseAlert> activeAlerts;
  final int riskScore;
  final String riskLevel;
  final String reason;
  final bool needsReview;
}

final patientRiskProfilesProvider = Provider<List<PatientRiskProfile>>((ref) {
  final state = ref.watch(appControllerProvider);
  final now = DateTime.now();

  return state.patients.map((patient) {
    final sensor = state.sensors
        .where((item) => item.id == patient.sensorId)
        .firstOrNull;
    final readings =
        state.readings
            .where(
              (reading) =>
                  reading.patientId == patient.id &&
                  !_isDemoGlucoseReading(reading),
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final latestReading = readings.isEmpty ? null : readings.last;
    final activeAlerts =
        state.alerts
            .where(
              (alert) => alert.patientId == patient.id && !alert.acknowledged,
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    var score = 0;
    final reasons = <String>[];
    final urgentAlerts = activeAlerts
        .where((alert) => alert.severity == AlertSeverity.urgent)
        .length;
    final warningAlerts = activeAlerts
        .where((alert) => alert.severity == AlertSeverity.warning)
        .length;
    if (urgentAlerts > 0) {
      score += urgentAlerts * 35;
      reasons.add('$urgentAlerts urgent alert${urgentAlerts == 1 ? '' : 's'}');
    }
    if (warningAlerts > 0) {
      score += warningAlerts * 12;
      reasons.add(
        '$warningAlerts warning alert${warningAlerts == 1 ? '' : 's'}',
      );
    }

    if (latestReading != null) {
      if (latestReading.status == GlucoseStatus.low) {
        score += 30;
        reasons.add('latest low ${latestReading.value} mg/dL');
      } else if (latestReading.status == GlucoseStatus.high) {
        score += latestReading.value >= 250 ? 30 : 14;
        reasons.add('latest high ${latestReading.value} mg/dL');
      }
      final staleMinutes = now.difference(latestReading.timestamp).inMinutes;
      if (staleMinutes >= state.alertSettings.sensorDisconnectReminderMinutes) {
        score += 12;
        reasons.add('reading stale ${staleMinutes}m');
      }
      if (isRapidGlucoseChange(readings)) {
        score += 12;
        reasons.add('rapid glucose movement');
      }
    } else if (sensor?.status == SensorStatus.active) {
      score += 10;
      reasons.add('active sensor without live readings');
    }

    if (sensor != null) {
      if (sensor.status == SensorStatus.expired) {
        score += 35;
        reasons.add('sensor expired');
      }
      if (sensor.connectionStatus == ConnectionStatus.offline) {
        score += 18;
        reasons.add('sensor offline');
      } else if (sensor.connectionStatus == ConnectionStatus.weak) {
        score += 8;
        reasons.add('weak sensor connection');
      }
      final expiry = sensor.expiryDate;
      if (expiry != null &&
          expiry.isAfter(now) &&
          expiry.difference(now).inHours <= 24) {
        score += 8;
        reasons.add('sensor expires within 24h');
      }
    }

    final riskLevel = score >= 45 || urgentAlerts > 0
        ? 'urgent'
        : score >= 15
        ? 'watch'
        : 'stable';
    return PatientRiskProfile(
      patient: patient,
      sensor: sensor,
      latestReading: latestReading,
      activeAlerts: activeAlerts,
      riskScore: score.clamp(0, 100).toInt(),
      riskLevel: riskLevel,
      reason: reasons.isEmpty ? 'Live CGM status stable' : reasons.join(', '),
      needsReview: riskLevel != 'stable',
    );
  }).toList()..sort((a, b) => b.riskScore.compareTo(a.riskScore));
});

final reviewQueueProvider = Provider<List<PatientRiskProfile>>((ref) {
  return ref
      .watch(patientRiskProfilesProvider)
      .where((profile) => profile.needsReview)
      .toList()
    ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
});

final openCareTasksProvider = Provider<List<CareTask>>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.careTasks.where((task) => task.status != 'completed').toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
});

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension TakeLast<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}

String _englishOrDefault(String value, String fallback) {
  final text = value.trim();
  if (text.isEmpty || _containsCjk(text) || _looksMojibake(text)) {
    return fallback;
  }
  return text;
}

String? _englishOrNull(String? value) {
  final text = value?.trim();
  if (text == null ||
      text.isEmpty ||
      _containsCjk(text) ||
      _looksMojibake(text)) {
    return null;
  }
  return text;
}

bool _containsCjk(String value) {
  return value.runes.any((codePoint) {
    return (codePoint >= 0x3000 && codePoint <= 0x303F) ||
        (codePoint >= 0x3040 && codePoint <= 0x30FF) ||
        (codePoint >= 0x3400 && codePoint <= 0x4DBF) ||
        (codePoint >= 0x4E00 && codePoint <= 0x9FFF) ||
        (codePoint >= 0xAC00 && codePoint <= 0xD7AF) ||
        (codePoint >= 0xF900 && codePoint <= 0xFAFF);
  });
}

bool _looksMojibake(String value) {
  const markerCodePoints = {
    0x00C2,
    0x00C3,
    0x00E2,
    0x00E5,
    0x00E6,
    0x00E7,
    0x00E8,
    0x00EF,
    0x0153,
    0x20AC,
    0xFFFD,
  };
  return value.runes.any(markerCodePoints.contains);
}
