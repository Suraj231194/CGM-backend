import '../app/theme.dart';

enum TrendDirection { risingFast, rising, steady, falling, fallingFast }

enum GlucoseStatus { low, normal, high }

enum SensorStatus { inactive, attached, connecting, warmingUp, active, expired }

enum ConnectionStatus { connected, nearby, weak, offline }

enum ChartDuration {
  oneHour,
  threeHours,
  sixHours,
  twelveHours,
  day,
  week,
  twoWeeks,
}

enum MealType { breakfast, lunch, dinner, snack }

enum AlertSeverity { info, warning, urgent }

class OptimusUser {
  const OptimusUser({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
  });

  final String id;
  final String name;
  final OptimusRole role;
  final String email;
  final String phone;
}

class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.doctorId,
    required this.sensorId,
    required this.riskLevel,
  });

  final String id;
  final String name;
  final int age;
  final String gender;
  final String doctorId;
  final String sensorId;
  final String riskLevel;

  Patient copyWith({String? sensorId}) {
    return Patient(
      id: id,
      name: name,
      age: age,
      gender: gender,
      doctorId: doctorId,
      sensorId: sensorId ?? this.sensorId,
      riskLevel: riskLevel,
    );
  }
}

class Sensor {
  const Sensor({
    required this.id,
    required this.serialNumber,
    required this.patientId,
    required this.status,
    required this.batteryStatus,
    required this.connectionStatus,
    this.activationDate,
    this.expiryDate,
    this.warmupStartTime,
    this.warmupEndTime,
  });

  final String id;
  final String serialNumber;
  final String patientId;
  final SensorStatus status;
  final DateTime? activationDate;
  final DateTime? expiryDate;
  final DateTime? warmupStartTime;
  final DateTime? warmupEndTime;
  final int batteryStatus;
  final ConnectionStatus connectionStatus;

  Sensor copyWith({
    String? serialNumber,
    SensorStatus? status,
    DateTime? activationDate,
    DateTime? expiryDate,
    DateTime? warmupStartTime,
    DateTime? warmupEndTime,
    int? batteryStatus,
    ConnectionStatus? connectionStatus,
  }) {
    return Sensor(
      id: id,
      serialNumber: serialNumber ?? this.serialNumber,
      patientId: patientId,
      status: status ?? this.status,
      activationDate: activationDate ?? this.activationDate,
      expiryDate: expiryDate ?? this.expiryDate,
      warmupStartTime: warmupStartTime ?? this.warmupStartTime,
      warmupEndTime: warmupEndTime ?? this.warmupEndTime,
      batteryStatus: batteryStatus ?? this.batteryStatus,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }
}

class OptimusGlucoseReading {
  const OptimusGlucoseReading({
    required this.id,
    required this.sensorId,
    required this.patientId,
    required this.timestamp,
    required this.value,
    required this.unit,
    required this.trend,
    required this.status,
    this.clientReadingId,
  });

  final String id;
  final String sensorId;
  final String patientId;
  final DateTime timestamp;
  final int value;
  final String unit;
  final TrendDirection trend;
  final GlucoseStatus status;
  final String? clientReadingId;

  OptimusGlucoseReading copyWith({
    String? id,
    String? sensorId,
    String? clientReadingId,
  }) {
    return OptimusGlucoseReading(
      id: id ?? this.id,
      sensorId: sensorId ?? this.sensorId,
      patientId: patientId,
      timestamp: timestamp,
      value: value,
      unit: unit,
      trend: trend,
      status: status,
      clientReadingId: clientReadingId ?? this.clientReadingId,
    );
  }
}

class MealLog {
  const MealLog({
    required this.id,
    required this.patientId,
    required this.timestamp,
    required this.type,
    required this.title,
    required this.netCarbs,
    required this.protein,
    required this.fiber,
    required this.activityMinutes,
    required this.score,
    required this.note,
  });

  final String id;
  final String patientId;
  final DateTime timestamp;
  final MealType type;
  final String title;
  final int netCarbs;
  final int protein;
  final int fiber;
  final int activityMinutes;
  final int score;
  final String note;
}

class ConsentPreferences {
  const ConsentPreferences({
    required this.healthData,
    required this.sensorData,
    required this.aiCoaching,
    required this.reportSharing,
    required this.termsAccepted,
  });

  final bool healthData;
  final bool sensorData;
  final bool aiCoaching;
  final bool reportSharing;
  final bool termsAccepted;

  bool get readyForOnboarding =>
      healthData && sensorData && aiCoaching && termsAccepted;

  ConsentPreferences copyWith({
    bool? healthData,
    bool? sensorData,
    bool? aiCoaching,
    bool? reportSharing,
    bool? termsAccepted,
  }) {
    return ConsentPreferences(
      healthData: healthData ?? this.healthData,
      sensorData: sensorData ?? this.sensorData,
      aiCoaching: aiCoaching ?? this.aiCoaching,
      reportSharing: reportSharing ?? this.reportSharing,
      termsAccepted: termsAccepted ?? this.termsAccepted,
    );
  }
}

class AlertSettings {
  const AlertSettings({
    required this.notificationsEnabled,
    required this.lowThreshold,
    required this.highThreshold,
    required this.quietHoursEnabled,
    required this.sensorDisconnectReminderMinutes,
  });

  final bool notificationsEnabled;
  final int lowThreshold;
  final int highThreshold;
  final bool quietHoursEnabled;
  final int sensorDisconnectReminderMinutes;

  AlertSettings copyWith({
    bool? notificationsEnabled,
    int? lowThreshold,
    int? highThreshold,
    bool? quietHoursEnabled,
    int? sensorDisconnectReminderMinutes,
  }) {
    return AlertSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lowThreshold: lowThreshold ?? this.lowThreshold,
      highThreshold: highThreshold ?? this.highThreshold,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      sensorDisconnectReminderMinutes:
          sensorDisconnectReminderMinutes ??
          this.sensorDisconnectReminderMinutes,
    );
  }
}

class GlucoseAlert {
  const GlucoseAlert({
    required this.id,
    required this.patientId,
    required this.timestamp,
    required this.title,
    required this.message,
    required this.value,
    required this.threshold,
    required this.severity,
    required this.acknowledged,
  });

  final String id;
  final String patientId;
  final DateTime timestamp;
  final String title;
  final String message;
  final int value;
  final int threshold;
  final AlertSeverity severity;
  final bool acknowledged;

  GlucoseAlert copyWith({bool? acknowledged}) {
    return GlucoseAlert(
      id: id,
      patientId: patientId,
      timestamp: timestamp,
      title: title,
      message: message,
      value: value,
      threshold: threshold,
      severity: severity,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }
}

class ReportExport {
  const ReportExport({
    required this.id,
    required this.patientId,
    required this.period,
    required this.generatedAt,
    required this.format,
    required this.status,
    required this.summary,
    this.filePath,
    this.csvPath,
    this.shareLink,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.backendRecordId,
  });

  final String id;
  final String patientId;
  final String period;
  final DateTime generatedAt;
  final String format;
  final String status;
  final String summary;
  final String? filePath;
  final String? csvPath;
  final String? shareLink;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final String? backendRecordId;

  ReportExport copyWith({
    String? period,
    DateTime? generatedAt,
    String? format,
    String? status,
    String? summary,
    String? filePath,
    String? csvPath,
    String? shareLink,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    String? backendRecordId,
  }) {
    return ReportExport(
      id: id,
      patientId: patientId,
      period: period ?? this.period,
      generatedAt: generatedAt ?? this.generatedAt,
      format: format ?? this.format,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      filePath: filePath ?? this.filePath,
      csvPath: csvPath ?? this.csvPath,
      shareLink: shareLink ?? this.shareLink,
      dateRangeStart: dateRangeStart ?? this.dateRangeStart,
      dateRangeEnd: dateRangeEnd ?? this.dateRangeEnd,
      backendRecordId: backendRecordId ?? this.backendRecordId,
    );
  }
}

class NotificationRecord {
  const NotificationRecord({
    required this.id,
    required this.patientId,
    required this.timestamp,
    required this.title,
    required this.message,
    required this.type,
    required this.delivered,
    this.route,
  });

  final String id;
  final String patientId;
  final DateTime timestamp;
  final String title;
  final String message;
  final String type;
  final bool delivered;
  final String? route;
}

class ClinicianNote {
  const ClinicianNote({
    required this.id,
    required this.patientId,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.note,
  });

  final String id;
  final String patientId;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String note;
}

class CareTask {
  const CareTask({
    required this.id,
    required this.patientId,
    required this.title,
    required this.ownerRole,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.dueAt,
    this.completedAt,
  });

  final String id;
  final String patientId;
  final String title;
  final String ownerRole;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime? dueAt;
  final DateTime? completedAt;

  CareTask copyWith({
    String? status,
    String? priority,
    DateTime? dueAt,
    DateTime? completedAt,
  }) {
    return CareTask(
      id: id,
      patientId: patientId,
      title: title,
      ownerRole: ownerRole,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      dueAt: dueAt ?? this.dueAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.actorRole,
    required this.action,
    required this.targetId,
    required this.targetType,
    required this.timestamp,
    required this.details,
  });

  final String id;
  final String actorId;
  final String actorRole;
  final String action;
  final String targetId;
  final String targetType;
  final DateTime timestamp;
  final String details;
}

class AIInterpretation {
  const AIInterpretation({
    required this.id,
    required this.patientId,
    required this.period,
    required this.summary,
    required this.patterns,
    required this.recommendations,
    required this.disclaimer,
    required this.tone,
  });

  final String id;
  final String patientId;
  final String period;
  final String summary;
  final List<String> patterns;
  final List<String> recommendations;
  final String disclaimer;
  final String tone;
}

class SensorSyncLog {
  const SensorSyncLog({
    required this.id,
    required this.sensorId,
    required this.patientId,
    required this.event,
    required this.status,
    required this.timestamp,
    required this.details,
  });

  final String id;
  final String sensorId;
  final String patientId;
  final String event;
  final String status;
  final DateTime timestamp;
  final String details;
}

class Order {
  const Order({
    required this.id,
    required this.patientId,
    required this.productName,
    required this.quantity,
    required this.status,
    required this.shippingAddress,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final String productName;
  final int quantity;
  final String status;
  final String shippingAddress;
  final DateTime createdAt;
}

class DeviceIntegration {
  const DeviceIntegration({
    required this.id,
    required this.name,
    required this.provider,
    required this.category,
    required this.status,
    required this.summary,
    this.lastSync,
  });

  final String id;
  final String name;
  final String provider;
  final String category;
  final String status;
  final String summary;
  final DateTime? lastSync;

  DeviceIntegration copyWith({String? status, DateTime? lastSync}) {
    return DeviceIntegration(
      id: id,
      name: name,
      provider: provider,
      category: category,
      status: status ?? this.status,
      summary: summary,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
