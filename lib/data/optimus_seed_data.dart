import '../app/theme.dart';
import '../models/optimus_models.dart';

final _now = DateTime.now();

DateTime minutesAgo(int minutes) => _now.subtract(Duration(minutes: minutes));
DateTime minutesFromNow(int minutes) => _now.add(Duration(minutes: minutes));

const optimusUsers = <OptimusUser>[
  OptimusUser(
    id: 'user-customer-1',
    name: 'Aarav Mehta',
    role: OptimusRole.customer,
    email: 'customer@optimus.test',
    phone: '+91 98765 43210',
  ),
  OptimusUser(
    id: 'user-doctor-1',
    name: 'Dr. Meera Shah',
    role: OptimusRole.doctor,
    email: 'doctor@optimus.test',
    phone: '+91 99887 77665',
  ),
  OptimusUser(
    id: 'user-admin-1',
    name: 'Optimus Support Admin',
    role: OptimusRole.admin,
    email: 'admin@optimus.test',
    phone: '+91 90000 11122',
  ),
];

const optimusPatients = <Patient>[
  Patient(
    id: 'patient-1',
    name: 'Aarav Mehta',
    age: 42,
    gender: 'Male',
    doctorId: 'doctor-1',
    sensorId: 'sensor-1',
    riskLevel: 'stable',
  ),
  Patient(
    id: 'patient-2',
    name: 'Priya Nair',
    age: 36,
    gender: 'Female',
    doctorId: 'doctor-1',
    sensorId: 'sensor-2',
    riskLevel: 'watch',
  ),
  Patient(
    id: 'patient-3',
    name: 'Kabir Sethi',
    age: 51,
    gender: 'Male',
    doctorId: 'doctor-2',
    sensorId: 'sensor-3',
    riskLevel: 'urgent',
  ),
  Patient(
    id: 'patient-4',
    name: 'Nisha Rao',
    age: 29,
    gender: 'Female',
    doctorId: 'doctor-1',
    sensorId: 'sensor-4',
    riskLevel: 'stable',
  ),
];

final optimusSensors = <Sensor>[
  Sensor(
    id: 'sensor-1',
    serialNumber: 'OPT-CGM-14D-001',
    patientId: 'patient-1',
    status: SensorStatus.active,
    activationDate: minutesAgo(9 * 24 * 60),
    expiryDate: minutesFromNow(5 * 24 * 60),
    warmupStartTime: minutesAgo(9 * 24 * 60 + 60),
    warmupEndTime: minutesAgo(9 * 24 * 60),
    batteryStatus: 74,
    connectionStatus: ConnectionStatus.connected,
  ),
  Sensor(
    id: 'sensor-2',
    serialNumber: 'OPT-CGM-14D-002',
    patientId: 'patient-2',
    status: SensorStatus.active,
    activationDate: minutesAgo(12 * 24 * 60),
    expiryDate: minutesFromNow(2 * 24 * 60),
    batteryStatus: 38,
    connectionStatus: ConnectionStatus.weak,
  ),
  Sensor(
    id: 'sensor-3',
    serialNumber: 'OPT-CGM-14D-003',
    patientId: 'patient-3',
    status: SensorStatus.active,
    activationDate: minutesAgo(3 * 24 * 60),
    expiryDate: minutesFromNow(11 * 24 * 60),
    batteryStatus: 86,
    connectionStatus: ConnectionStatus.connected,
  ),
  Sensor(
    id: 'sensor-4',
    serialNumber: 'OPT-CGM-14D-004',
    patientId: 'patient-4',
    status: SensorStatus.warmingUp,
    warmupStartTime: minutesAgo(24),
    warmupEndTime: minutesFromNow(36),
    batteryStatus: 97,
    connectionStatus: ConnectionStatus.nearby,
  ),
];

const defaultConsentPreferences = ConsentPreferences(
  healthData: false,
  sensorData: false,
  aiCoaching: false,
  reportSharing: false,
  termsAccepted: false,
);

const defaultAlertSettings = AlertSettings(
  notificationsEnabled: true,
  lowThreshold: 70,
  highThreshold: 180,
  quietHoursEnabled: false,
  sensorDisconnectReminderMinutes: 15,
);

final optimusMealLogs = <MealLog>[
  MealLog(
    id: 'meal-1',
    patientId: 'patient-1',
    timestamp: minutesAgo(6 * 60),
    type: MealType.breakfast,
    title: 'Oats, eggs, and berries',
    netCarbs: 38,
    protein: 24,
    fiber: 9,
    activityMinutes: 12,
    score: 86,
    note: 'Stable response after a short walk.',
  ),
  MealLog(
    id: 'meal-2',
    patientId: 'patient-1',
    timestamp: minutesAgo(2 * 60),
    type: MealType.lunch,
    title: 'Rice bowl with paneer',
    netCarbs: 58,
    protein: 31,
    fiber: 7,
    activityMinutes: 8,
    score: 72,
    note: 'Higher carb load; pair with more fiber next time.',
  ),
];

const optimusAlerts = <GlucoseAlert>[];

const optimusReportExports = <ReportExport>[];

const optimusAIInterpretations = <AIInterpretation>[];

const optimusSyncLogs = <SensorSyncLog>[];

final optimusOrders = <Order>[
  Order(
    id: 'order-1001',
    patientId: 'patient-1',
    productName: 'Optimus CGM 14-day sensor',
    quantity: 2,
    status: 'delivered',
    shippingAddress: '221 Health Park, Mumbai, Maharashtra 400001',
    createdAt: minutesAgo(21 * 24 * 60),
  ),
  Order(
    id: 'order-1002',
    patientId: 'patient-1',
    productName: 'Optimus CGM 14-day sensor',
    quantity: 1,
    status: 'shipped',
    shippingAddress: '221 Health Park, Mumbai, Maharashtra 400001',
    createdAt: minutesAgo(2 * 24 * 60),
  ),
];

const deviceIntegrations = <DeviceIntegration>[
  DeviceIntegration(
    id: 'optimus-native',
    name: 'Optimus CGM SDK',
    provider: 'Native bridge',
    category: 'cgm',
    status: 'available',
    summary:
        'Android .aar and iOS .xcframework integration path for direct sensor connectivity.',
  ),
  DeviceIntegration(
    id: 'dexcom',
    name: 'Dexcom',
    provider: 'OAuth API',
    category: 'cgm',
    status: 'available',
    summary: 'Cloud glucose import for supported Dexcom accounts.',
  ),
  DeviceIntegration(
    id: 'nightscout',
    name: 'Nightscout',
    provider: 'REST adapter',
    category: 'cgm',
    status: 'available',
    summary: 'Import readings from a Nightscout endpoint for continuity.',
  ),
  DeviceIntegration(
    id: 'apple-health',
    name: 'Apple Health',
    provider: 'HealthKit',
    category: 'health',
    status: 'comingSoon',
    summary: 'iOS lifestyle context for activity, sleep, and vitals.',
  ),
  DeviceIntegration(
    id: 'health-connect',
    name: 'Health Connect',
    provider: 'Android',
    category: 'health',
    status: 'comingSoon',
    summary: 'Android health context once native plugin permissions are added.',
  ),
  DeviceIntegration(
    id: 'watch-widget',
    name: 'Smartwatch widget',
    provider: 'Companion surfaces',
    category: 'watch',
    status: 'available',
    summary: 'Glanceable glucose, freshness, trend arrow, and alert state.',
  ),
];
