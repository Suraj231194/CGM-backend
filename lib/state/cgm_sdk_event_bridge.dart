import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ble/ble_connection_guard.dart';
import '../core/ble/ble_reconnection_policy.dart';
import '../core/ble/ble_state_monitor.dart';
import '../core/lifecycle/app_lifecycle_observer.dart';
import '../services/cgm_sdk_service.dart';
import 'app_state.dart';

final cgmSdkEventBridgeProvider = Provider<void>((ref) {
  final supportedPlatform =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (kIsWeb || !supportedPlatform) {
    return;
  }

  final service = CgmSdkService.instance;
  final controller = ref.read(appControllerProvider.notifier);
  Future<void> refreshNativeState() {
    return _refreshNativeConnectionState(
      service,
      controller,
      ref.read(appControllerProvider),
    );
  }

  final subscription = service.events.listen(
    (event) => _handleSdkEvent(event, controller, ref),
    onError: (Object error, StackTrace stackTrace) {
      controller.setCgmConnectionState(
        status: 'SDK event stream error',
        connected: false,
        connecting: false,
        error: error.toString(),
      );
    },
  );

  final bluetoothPoller = Timer.periodic(
    const Duration(seconds: 20),
    (_) => unawaited(refreshNativeState()),
  );

  ref.listen<AppLifecycleStatus>(appLifecycleProvider, (previous, next) {
    if (next == AppLifecycleStatus.active) {
      unawaited(() async {
        await refreshNativeState();
        _startReconnectIfNeeded(ref);
      }());
      // Check permissions on resume to detect revocation
      unawaited(_checkPermissionsOnResume(ref));
    }
  });

  // Listen to BLE adapter state changes for immediate response
  ref.listen<BleAdapterState>(bleStateProvider, (previous, next) {
    _handleBleAdapterStateChange(previous, next, controller, ref);
  });

  unawaited(
    service.checkAuthorized().then(
      (authorized) => controller.setCgmAuthState(authorized: authorized),
      onError: (_) {},
    ),
  );

  // Restore connection status on startup (#13)
  unawaited(
    service.isConnected().then((isConn) {
      if (isConn) {
        controller.setCgmConnectionState(
          status: 'Sensor connected',
          connected: true,
          connecting: false,
        );
      }
    }, onError: (_) {}),
  );
  unawaited(
    Future<void>.delayed(
      const Duration(seconds: 1),
    ).then((_) => _startReconnectIfNeeded(ref)),
  );

  ref.onDispose(() {
    bluetoothPoller.cancel();
    unawaited(subscription.cancel());
  });
});

void _handleSdkEvent(CgmSdkEvent event, AppController controller, Ref ref) {
  switch (event.type) {
    case 'ready':
      controller.addCgmLog(
        _message(event, fallback: 'Native CGM bridge is ready.'),
      );
    case 'authSuccess':
      controller.setCgmAuthState(authorized: true);
    case 'authError':
      controller.setCgmAuthState(
        authorized: false,
        error: _message(event, fallback: 'SDK authorization failed.'),
      );
    case 'permissions':
      controller.addCgmLog(
        'Permissions: ${event.data['status'] ?? event.data['result'] ?? 'updated'}.',
      );
    case 'connection':
      final previousState = ref.read(appControllerProvider);
      final status = event.data['status']?.toString();
      final connected = _isConnectedEvent(event);
      final failed = _isFailedConnectionStatus(status);
      final message = _message(
        event,
        fallback: _connectionFallback(status, connected: connected),
      );
      controller.setCgmConnectionState(
        status: message,
        connected: connected,
        connecting: _isConnectingStatus(status),
        sensorSn: event.data['sn'] as String?,
        error: failed ? message : null,
      );
      // Handle reconnection logic
      if (connected) {
        ref.read(bleReconnectionProvider.notifier).markConnected();
        ref.read(bleStateProvider.notifier).resetFailures();
        BleConnectionGuard.release();
      } else if (_isDisconnectedStatus(status)) {
        final wasConnected =
            previousState.cgmConnected || previousState.cgmWasEverConnected;
        final sensorSn =
            event.data['sn'] as String? ?? previousState.cgmSensorSn;
        if (wasConnected && sensorSn != null && sensorSn.isNotEmpty) {
          ref
              .read(bleReconnectionProvider.notifier)
              .startReconnection(sensorSn);
        }
        BleConnectionGuard.release();
      } else if (failed) {
        BleConnectionGuard.release();
      }
    case 'heartbeat':
      final status = event.data['status']?.toString().toLowerCase();
      final started = event.data['enabled'] == true || status == 'start';
      controller.addCgmLog('Heartbeat ${started ? 'started' : 'stopped'}.');
    case 'bleState':
      final state = event.data['state']?.toString();
      final poweredOn =
          event.data['poweredOn'] == true || _isPoweredOnBleState(state);
      if (_isUnauthorizedBleState(state)) {
        controller.setCgmConnectionState(
          status: 'Bluetooth unauthorized',
          connected: false,
          connecting: false,
          error:
              'Bluetooth permission is not granted. Please allow Nearby devices.',
        );
        BleConnectionGuard.release();
      } else if (_isPoweredOffBleState(state)) {
        controller.setCgmConnectionState(
          status: 'Bluetooth disabled',
          connected: false,
          connecting: false,
          error: 'Bluetooth is turned off. Please enable Bluetooth.',
        );
        BleConnectionGuard.release();
      } else {
        controller.addCgmLog(
          poweredOn
              ? 'Bluetooth ready.'
              : 'Bluetooth state: ${state ?? 'unknown'}.',
        );
        // Only auto-reconnect on BT re-enable if sensor was previously
        // connected at least once and no manual connection is in progress.
        final appState = ref.read(appControllerProvider);
        if (poweredOn &&
            appState.cgmSensorSn != null &&
            appState.cgmWasEverConnected &&
            !appState.cgmConnected &&
            !appState.cgmConnecting &&
            !BleConnectionGuard.isConnecting) {
          ref
              .read(bleReconnectionProvider.notifier)
              .startReconnection(appState.cgmSensorSn!);
        }
      }
    case 'bindStep':
      controller.addCgmLog('Bind step: ${event.data['step'] ?? 'updated'}.');
    case 'syncProgress':
      final progress = event.data['progress'];
      if (progress is num) {
        controller.setCgmSyncProgress(progress.toInt());
      }
    case 'deviceInfo':
      controller.applyCgmDeviceInfo(event.data);
    case 'glucoseData':
      final rawReadings = event.data['readings'];
      if (rawReadings is List) {
        final readings = rawReadings
            .whereType<Map>()
            .map(CgmBloodSugarReading.fromMap)
            .toList();
        controller.applyCgmReadings(readings);
        // Update sync checkpoint
        if (readings.isNotEmpty) {
          final maxIndex = readings
              .map((r) => r.timeOffset)
              .reduce((a, b) => a > b ? a : b);
          BleSyncCheckpoint.update(
            sensorSn: ref.read(appControllerProvider).cgmSensorSn ?? '',
            lastIndex: maxIndex,
          );
        }
      }
    case 'scanResult':
      final rssi = event.data['rssi'];
      controller.setCgmNearbyDevice(
        name: event.data['name']?.toString(),
        address: event.data['address']?.toString(),
        rssi: rssi is num ? rssi.toInt() : int.tryParse(rssi?.toString() ?? ''),
      );
    case 'sdkError':
    case 'scanFailed':
      controller.setCgmConnectionState(
        status: _message(event, fallback: 'Sensor connection failed.'),
        connected: false,
        connecting: false,
        error: _message(event, fallback: 'Sensor connection failed.'),
      );
      BleConnectionGuard.release();
    case 'log':
      controller.addCgmLog(_message(event, fallback: 'SDK log received.'));
    default:
      controller.addCgmLog('SDK event: ${event.type}.');
  }
}

Future<void> _refreshNativeConnectionState(
  CgmSdkService service,
  AppController controller,
  AppState appState,
) async {
  final hasSensorContext =
      appState.cgmSensorSn != null ||
      appState.cgmConnected ||
      appState.cgmConnecting;
  if (!hasSensorContext) return;

  final permissionStatus = await service.checkBluetoothPermissions();
  if (_isDeniedBluetoothPermissionStatus(permissionStatus)) {
    controller.setCgmConnectionState(
      status: 'Bluetooth unauthorized',
      connected: false,
      connecting: false,
      sensorSn: appState.cgmSensorSn,
      error:
          'Bluetooth permission is not granted. Please allow Nearby devices.',
    );
    return;
  }

  final bluetoothEnabled = await service.isBluetoothEnabled();
  if (!bluetoothEnabled) {
    controller.setCgmConnectionState(
      status: 'Bluetooth disabled',
      connected: false,
      connecting: false,
      sensorSn: appState.cgmSensorSn,
      error: 'Bluetooth is turned off. Please enable Bluetooth.',
    );
    return;
  }

  final isConnected = await service.isConnected();
  if (isConnected) {
    controller.setCgmConnectionState(
      status: 'Sensor connected',
      connected: true,
      connecting: false,
      sensorSn: appState.cgmSensorSn,
    );
    await service.startHeartbeat();
  } else if (appState.cgmConnected || appState.cgmWasEverConnected) {
    controller.setCgmConnectionState(
      status: 'Sensor disconnected',
      connected: false,
      connecting: false,
      sensorSn: appState.cgmSensorSn,
      error: 'Sensor disconnected. Keep the phone near the sensor.',
    );
  }
}

void _startReconnectIfNeeded(Ref ref) {
  final appState = ref.read(appControllerProvider);
  final sensorSn = appState.cgmSensorSn;
  if (sensorSn == null || sensorSn.isEmpty) return;
  if (!appState.cgmWasEverConnected) return;
  if (appState.cgmConnected || appState.cgmConnecting) return;
  if (BleConnectionGuard.isConnecting) return;

  ref.read(bleReconnectionProvider.notifier).startReconnection(sensorSn);
}

String _message(CgmSdkEvent event, {required String fallback}) {
  final mappedMessage =
      _sdkCodeMessage(event.data['code']) ??
      _sdkNameMessage(event.data['name']);
  final rawMessage = event.data['message'] ?? event.data['error'];

  if (rawMessage == null) return mappedMessage ?? fallback;

  final message = rawMessage.toString().trim();
  if (message.isEmpty) return mappedMessage ?? fallback;

  if (_shouldReplaceSdkMessage(message)) {
    return mappedMessage ?? fallback;
  }

  return message;
}

String? _sdkCodeMessage(Object? code) {
  final value = code is num
      ? code.toInt()
      : int.tryParse(code?.toString() ?? '');
  return switch (value) {
    1001 => 'Network error while contacting the CGM service.',
    1002 => 'The CGM service request timed out.',
    1003 => 'The CGM service request failed.',
    1004 => 'A required CGM SDK parameter is invalid.',
    1005 => 'CGM SDK authentication failed.',
    1006 => 'CGM SDK is not authenticated. Please authorize again.',
    1007 =>
      'Sensor not found. Keep the phone close to the sensor and try again.',
    1008 => 'Sensor has expired.',
    1009 => 'CGM SDK authentication expired. Please authorize again.',
    2002 => 'Bluetooth scan failed.',
    2003 => 'Bluetooth scan timed out.',
    2004 => 'Bluetooth connection timed out.',
    2005 => 'Bluetooth connection failed.',
    2006 => 'Bluetooth MTU setup failed.',
    2007 => 'Bluetooth service startup failed.',
    2008 => 'Bluetooth command write failed.',
    2009 => 'Bluetooth response timed out.',
    2010 => 'Bluetooth response status error.',
    3001 => 'Sensor SN was rejected. Check the scanned serial number.',
    3003 => 'Sensor device malfunction reported by SDK.',
    4001 => 'CGM SDK database query error.',
    4002 => 'CGM query was rejected by Bluetooth.',
    400001 => 'Network error while contacting the CGM service.',
    400002 => 'The CGM service response could not be parsed.',
    400003 => 'The CGM service returned invalid data.',
    400004 => 'A required CGM SDK parameter is missing.',
    400005 => 'CGM SDK signature verification failed.',
    400006 => 'The requested CGM record was not found.',
    400007 => 'CGM SDK token was not found.',
    400008 => 'CGM SDK token expired. Please authorize again.',
    500001 => 'Sensor serial number is missing.',
    500002 =>
      'Sensor not found. Keep the phone close to the sensor and try again.',
    500003 => 'Sensor has expired.',
    500004 => 'Bluetooth connection failed.',
    500005 => 'Bluetooth service discovery failed.',
    500006 => 'Bluetooth characteristic discovery failed.',
    500007 => 'Bluetooth communication failed.',
    _ => null,
  };
}

String? _sdkNameMessage(Object? name) {
  final value = name?.toString().toLowerCase();
  if (value == null || value.isEmpty) return null;

  if (value.contains('devicenotfound') ||
      value.contains('nodevice') ||
      value.contains('notfound')) {
    return 'Sensor not found. Keep the phone close to the sensor and try again.';
  }
  if (value.contains('devicesn') ||
      value.contains('snerror') ||
      value.contains('sn_error')) {
    return 'Sensor SN was rejected. Check the scanned serial number.';
  }
  if (value.contains('expired')) return 'Sensor has expired.';
  if (value.contains('sn')) return 'Sensor serial number is missing.';
  if (value.contains('blescantimeout')) return 'Bluetooth scan timed out.';
  if (value.contains('blescan')) return 'Bluetooth scan failed.';
  if (value.contains('bleconnecttimeout')) {
    return 'Bluetooth connection timed out.';
  }
  if (value.contains('bleconnect')) return 'Bluetooth connection failed.';
  if (value.contains('blemtu')) return 'Bluetooth MTU setup failed.';
  if (value.contains('bleserver')) return 'Bluetooth service startup failed.';
  if (value.contains('blewrite')) return 'Bluetooth command write failed.';
  if (value.contains('blenotifytimeout')) {
    return 'Bluetooth response timed out.';
  }
  if (value.contains('blenotifystate')) {
    return 'Bluetooth response status error.';
  }
  if (value.contains('discoverservices')) {
    return 'Bluetooth service discovery failed.';
  }
  if (value.contains('discovercharacteristics')) {
    return 'Bluetooth characteristic discovery failed.';
  }
  if (value.contains('ble') || value.contains('connect')) {
    return 'Bluetooth connection failed.';
  }
  if (value.contains('token')) {
    return 'CGM SDK token error. Please authorize again.';
  }
  if (value.contains('sign')) {
    return 'CGM SDK signature verification failed.';
  }
  if (value.contains('network') || value.contains('api')) {
    return 'Network error while contacting the CGM service.';
  }
  if (value.contains('param')) {
    return 'A required CGM SDK parameter is missing.';
  }
  return null;
}

bool _shouldReplaceSdkMessage(String message) {
  final lower = message.toLowerCase();
  return _containsCjk(message) ||
      _looksMojibake(message) ||
      lower.contains('operation couldn') ||
      lower.contains('operation could not') ||
      lower.contains('localized description');
}

bool _containsCjk(String value) {
  return value.runes.any((codePoint) {
    return (codePoint >= 0x3400 && codePoint <= 0x4DBF) ||
        (codePoint >= 0x4E00 && codePoint <= 0x9FFF) ||
        (codePoint >= 0xF900 && codePoint <= 0xFAFF);
  });
}

bool _looksMojibake(String value) {
  const markerCodePoints = {
    0x00C2, // Latin capital A with circumflex.
    0x00C3, // Latin capital A with tilde.
    0x00E5, // Latin small a with ring above.
    0x00E6, // Latin small ae.
    0x00E7, // Latin small c with cedilla.
    0x00E8, // Latin small e with grave.
    0x00EF, // Latin small i with diaeresis.
    0x0153, // Latin small oe.
    0x20AC, // Euro sign, common in mojibake fragments.
    0xFFFD, // Replacement character.
  };
  return value.runes.any(markerCodePoints.contains);
}

bool _isConnectedEvent(CgmSdkEvent event) {
  final connected = event.data['connected'];
  if (connected is bool) {
    return connected;
  }

  final status = event.data['status']?.toString().toLowerCase();
  return status == 'connected' || status == 'reconnected';
}

bool _isConnectingStatus(String? status) {
  final normalized = status?.toLowerCase();
  return normalized == 'scanning' || normalized == 'connecting';
}

bool _isFailedConnectionStatus(String? status) {
  final normalized = status?.toLowerCase();
  return normalized == 'failed' ||
      normalized == 'timeout' ||
      normalized == 'reconnectfailed';
}

bool _isDisconnectedStatus(String? status) {
  final normalized = status?.toLowerCase();
  return normalized == 'disconnected';
}

bool _isDeniedBluetoothPermissionStatus(String status) {
  return status == 'denied' || status == 'permanentlyDenied';
}

bool _isUnauthorizedBleState(String? state) {
  final normalized = state?.toLowerCase();
  return normalized == 'unauthorized' || normalized == 'denied';
}

bool _isPoweredOnBleState(String? state) {
  final normalized = state?.toLowerCase();
  return normalized == 'poweredon' ||
      normalized == 'powered_on' ||
      normalized == 'on';
}

bool _isPoweredOffBleState(String? state) {
  final normalized = state?.toLowerCase();
  return normalized == 'poweredoff' ||
      normalized == 'powered_off' ||
      normalized == 'off';
}

String _connectionFallback(String? status, {required bool connected}) {
  switch (status?.toLowerCase()) {
    case 'scanning':
      return 'Scanning for sensor.';
    case 'connected':
      return 'Sensor connected.';
    case 'reconnected':
      return 'Sensor reconnected.';
    case 'disconnected':
      return 'Sensor disconnected.';
    case 'timeout':
      return 'Sensor connection timed out.';
    case 'failed':
    case 'reconnectfailed':
      return 'Sensor connection failed.';
    default:
      return connected ? 'Sensor connected.' : 'Sensor disconnected.';
  }
}

/// Handles BLE adapter state changes from the real-time monitor.
void _handleBleAdapterStateChange(
  BleAdapterState? previous,
  BleAdapterState next,
  AppController controller,
  Ref ref,
) {
  if (next == BleAdapterState.poweredOff) {
    controller.setCgmConnectionState(
      status: 'Bluetooth disabled',
      connected: false,
      connecting: false,
      error: 'Bluetooth is turned off. Please enable Bluetooth.',
    );
    ref.read(bleReconnectionProvider.notifier).cancel();
    BleConnectionGuard.forceRelease();
  } else if (next == BleAdapterState.poweredOn &&
      previous == BleAdapterState.poweredOff) {
    controller.addCgmLog('Bluetooth enabled.');
    // Only auto-reconnect if sensor was previously connected at least once
    // and no manual connection is in progress.
    final appState = ref.read(appControllerProvider);
    if (appState.cgmSensorSn != null &&
        appState.cgmWasEverConnected &&
        !appState.cgmConnected &&
        !appState.cgmConnecting &&
        !BleConnectionGuard.isConnecting) {
      ref
          .read(bleReconnectionProvider.notifier)
          .startReconnection(appState.cgmSensorSn!);
    }
  } else if (next == BleAdapterState.unauthorized) {
    controller.setCgmConnectionState(
      status: 'Bluetooth unauthorized',
      connected: false,
      connecting: false,
      error:
          'Bluetooth permission has been revoked. Please re-enable in settings.',
    );
    BleConnectionGuard.forceRelease();
  }
}

/// Check if BLE permissions were revoked while app was in background.
Future<void> _checkPermissionsOnResume(Ref ref) async {
  final service = CgmSdkService.instance;
  try {
    final status = await service.checkBluetoothPermissions();
    if (status == 'denied' || status == 'permanentlyDenied') {
      final controller = ref.read(appControllerProvider.notifier);
      final appState = ref.read(appControllerProvider);
      if (appState.cgmConnected || appState.cgmConnecting) {
        controller.setCgmConnectionState(
          status: 'Bluetooth permission revoked',
          connected: false,
          connecting: false,
          error:
              'Bluetooth permission was revoked. Please re-enable in settings.',
        );
        ref.read(bleReconnectionProvider.notifier).cancel();
        BleConnectionGuard.forceRelease();
      }
    }
  } catch (_) {
    // Ignore - permission check is best-effort
  }
}
