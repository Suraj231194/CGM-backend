import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optimus_cgm_flutter/models/optimus_models.dart';
import 'package:optimus_cgm_flutter/core/ble/paired_sensor_store.dart';
import 'package:optimus_cgm_flutter/services/cgm_sdk_service.dart';
import 'package:optimus_cgm_flutter/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppController CGM connection state', () {
    test('starts without seeded glucose readings or reading artifacts', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(appControllerProvider);

      expect(state.readings, isEmpty);
      expect(state.aiInterpretations, isEmpty);
      expect(state.alerts, isEmpty);
      expect(state.reportExports, isEmpty);
      expect(state.syncLogs, isEmpty);
      expect(container.read(selectedPatientReadingsProvider), isEmpty);
      expect(container.read(selectedReadingsProvider), isEmpty);
    });

    test('SDK readings populate live reading providers', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appControllerProvider.notifier).applyCgmReadings([
        const CgmBloodSugarReading(
          originalBloodSugar: 6.5,
          processedBloodSugar: 6.5,
          createTime: 1700000000,
          timeOffset: 0,
          trend: 5,
        ),
      ]);

      final readings = container.read(selectedPatientReadingsProvider);

      expect(readings, hasLength(1));
      expect(readings.single.id, startsWith('sdk:'));
      expect(
        readings.single.clientReadingId,
        'sdk:OPT-CGM-14D-001:1700000000:0',
      );
      expect(readings.single.value, 117);
      expect(readings.single.trend, TrendDirection.rising);
    });

    test('replayed SDK reading is deduplicated by stable identity', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const reading = CgmBloodSugarReading(
        originalBloodSugar: 6.5,
        processedBloodSugar: 6.5,
        createTime: 1700000000,
        timeOffset: 12,
        trend: 5,
      );
      final controller = container.read(appControllerProvider.notifier);

      controller.applyCgmReadings([reading]);
      controller.applyCgmReadings([reading]);

      final readings = container.read(selectedPatientReadingsProvider);
      expect(readings, hasLength(1));
      expect(
        readings.single.clientReadingId,
        'sdk:OPT-CGM-14D-001:1700000000:12',
      );
    });

    test(
      'native scan does not mark the sensor connected before SDK success',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final controller = container.read(appControllerProvider.notifier);
        controller.startSensorActivation();
        controller.attachSensor();
        controller.scanAndConnectSensor(serialNumber: 'D115W66200387');

        final state = container.read(appControllerProvider);
        final sensor = container.read(selectedSensorProvider);

        expect(state.cgmSensorSn, 'D115W66200387');
        expect(state.cgmConnecting, isTrue);
        expect(state.cgmConnected, isFalse);
        expect(state.cgmConnectionStatus, 'Scanning for sensor');
        expect(sensor?.status, SensorStatus.attached);
        expect(sensor?.connectionStatus, ConnectionStatus.nearby);
      },
    );

    test('SDK success starts warm-up and marks connection established', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(appControllerProvider.notifier);
      controller.startSensorActivation();
      controller.attachSensor();
      controller.scanAndConnectSensor(serialNumber: 'D115W66200387');
      controller.setCgmConnectionState(
        status: 'Sensor connected',
        connected: true,
        connecting: false,
        sensorSn: 'D115W66200387',
      );

      final state = container.read(appControllerProvider);
      final sensor = container.read(selectedSensorProvider);

      expect(state.cgmConnecting, isFalse);
      expect(state.cgmConnected, isTrue);
      expect(sensor?.status, SensorStatus.warmingUp);
      expect(sensor?.connectionStatus, ConnectionStatus.connected);
      expect(sensor?.warmupStartTime, isNotNull);
      expect(sensor?.warmupEndTime, isNotNull);
    });

    test('untranslated SDK connection messages are replaced with English', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(appControllerProvider.notifier);
      controller.setCgmConnectionState(
        status: '\u8fde\u63a5\u4e2d',
        connected: false,
        connecting: true,
        error: '\u84dd\u7259\u8fde\u63a5\u5f02\u5e38',
      );

      final state = container.read(appControllerProvider);

      expect(state.cgmConnectionStatus, 'Sensor status updated.');
      expect(state.cgmLastError, 'Sensor connection failed.');
      expect(state.cgmSdkLogs.first, contains('Sensor status updated.'));
    });

    test('untranslated SDK log entries are replaced with English', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(appControllerProvider.notifier);
      controller.addCgmLog('\u8fde\u63a5\u84dd\u7259');

      final state = container.read(appControllerProvider);

      expect(state.cgmSdkLogs.first, contains('SDK event received.'));
    });

    test('sensor disconnect alert is added once while active', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(appControllerProvider.notifier);
      controller.addSensorDisconnectAlert(sensorSn: 'D115W66200387');
      controller.addSensorDisconnectAlert(sensorSn: 'D115W66200387');

      final alerts = container
          .read(appControllerProvider)
          .alerts
          .where((alert) => alert.id.startsWith('sensor-disconnected-'));

      expect(alerts.length, 1);
      expect(alerts.first.title, 'Sensor disconnected');
      expect(alerts.first.value, 0);
      expect(
        container.read(appControllerProvider).notificationHistory,
        isNotEmpty,
      );
    });

    test('urgent low SDK reading creates notification and care task', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      container.read(appControllerProvider.notifier).applyCgmReadings([
        CgmBloodSugarReading(
          originalBloodSugar: 3.0,
          processedBloodSugar: 3.0,
          createTime: nowSeconds,
          timeOffset: 0,
          trend: 10,
        ),
      ]);

      final state = container.read(appControllerProvider);
      final urgentAlert = state.alerts.firstWhere(
        (alert) => alert.title == 'Urgent low glucose alert',
      );

      expect(urgentAlert.severity, AlertSeverity.urgent);
      expect(state.notificationHistory, isNotEmpty);
      expect(
        state.careTasks.where((task) => task.priority == 'urgent'),
        isNotEmpty,
      );
      expect(
        state.auditLogs.where(
          (log) => log.action == 'urgent_glucose_escalated',
        ),
        isNotEmpty,
      );
    });

    test(
      'restores paired sensor serial from local storage for offline reconnect',
      () async {
        SharedPreferences.setMockInitialValues({});
        await PairedSensorStore.save(sensorSn: 'D115W66200387');
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(appControllerProvider.notifier)
            .restorePairedSensor();

        final state = container.read(appControllerProvider);
        final sensor = container.read(selectedSensorProvider);

        expect(state.cgmSensorSn, 'D115W66200387');
        expect(state.cgmWasEverConnected, isTrue);
        expect(state.cgmConnectionStatus, 'Paired sensor saved locally');
        expect(sensor?.serialNumber, 'D115W66200387');
      },
    );
  });
}
