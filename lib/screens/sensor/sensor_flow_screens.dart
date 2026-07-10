import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme.dart';
import '../../core/ble/ble_connection_guard.dart';
import '../../core/ble/ble_reconnection_policy.dart';
import '../../core/ble/ble_state_monitor.dart';
import '../../core/env/app_environment.dart';
import '../../core/network/connectivity_monitor.dart';
import '../../models/optimus_models.dart';
import '../../repositories/cgm_sdk_repository.dart';
import '../../services/cgm_sdk_service.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../utils/sensor_serial_parser.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_states.dart';
import '../../widgets/read_now_button.dart';

bool get _isNativeSdkAvailable =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

bool _canContinueWithPermissionStatus(String status) {
  return status == 'granted' ||
      status == 'ios-managed' ||
      status == 'not-applicable';
}

bool _canContinueWithCameraPermissionStatus(String status) {
  return status == 'granted';
}

bool _isPermissionError(String status) {
  return status == 'error' || status.startsWith('error:');
}

CgmSdkRepository _cgmRepository() {
  return CgmSdkRepository(sdk: CgmSdkServiceAdapter(CgmSdkService.instance));
}

String _bluetoothPermissionMessage(String status) {
  final platformSettings = defaultTargetPlatform == TargetPlatform.iOS
      ? 'iOS Settings'
      : 'Android settings';
  final permissionName = defaultTargetPlatform == TargetPlatform.iOS
      ? 'Bluetooth access'
      : 'Nearby devices/Bluetooth access';

  if (status == 'permanentlyDenied') {
    return 'Bluetooth permissions are permanently denied. Enable $permissionName in $platformSettings and try again.';
  }
  if (_isPermissionError(status)) {
    return 'Could not request Bluetooth permission. Open $platformSettings, enable $permissionName, and try again.';
  }
  return 'Bluetooth permissions were not granted. Please allow $permissionName and try again.';
}

class SensorActivationIntroScreen extends ConsumerStatefulWidget {
  const SensorActivationIntroScreen({super.key});

  @override
  ConsumerState<SensorActivationIntroScreen> createState() =>
      _SensorActivationIntroScreenState();
}

class _SensorActivationIntroScreenState
    extends ConsumerState<SensorActivationIntroScreen> {
  var _authorizing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isNativeSdkAvailable) {
        _autoAuthorizeIfNeeded();
      }
    });
  }

  Future<void> _autoAuthorizeIfNeeded() async {
    final appState = ref.read(appControllerProvider);
    final service = CgmSdkService.instance;
    final isAuthorized =
        appState.cgmAuthorized || await service.checkAuthorized();
    if (!mounted) return;
    if (isAuthorized) {
      if (!appState.cgmAuthorized) {
        ref
            .read(appControllerProvider.notifier)
            .setCgmAuthState(authorized: true);
      }
      return;
    }
    await _authorizeSdk(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final sensor = ref.watch(selectedSensorProvider);
    final appState = ref.watch(appControllerProvider);
    final nativeAvailable = _isNativeSdkAvailable;

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Sensor',
          title: 'Sensor activation',
          subtitle: 'Prepare and activate your CGM sensor.',
        ),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(
                label: sensor?.status.name.toUpperCase() ?? 'NO SENSOR',
                color: AppColors.primary,
                icon: Icons.sensors_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                sensor?.serialNumber ?? 'Prepare a new Optimus CGM sensor',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Follow the guided steps to attach, scan, and activate your continuous glucose monitor.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),

              // SDK Status Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: appState.cgmAuthorized
                      ? AppColors.primarySoft
                      : AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      appState.cgmAuthorized
                          ? Icons.verified_user_rounded
                          : Icons.gpp_bad_rounded,
                      color: appState.cgmAuthorized
                          ? AppColors.primary
                          : AppColors.danger,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.cgmAuthorized
                                ? 'SDK Authenticated'
                                : 'SDK Needs Authentication',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: appState.cgmAuthorized
                                      ? AppColors.primary
                                      : AppColors.danger,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appState.cgmAuthorized
                                ? 'Connected to Eaglenos service using config file credentials.'
                                : nativeAvailable
                                ? 'Failed to authenticate SDK. Please verify config file credentials.'
                                : 'Native SDK authentication runs only in Android and iOS app builds.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (!appState.cgmAuthorized && nativeAvailable)
                      IconButton(
                        onPressed: _authorizing
                            ? null
                            : () => _authorizeSdk(context, ref),
                        icon: _authorizing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        color: AppColors.danger,
                      ),
                  ],
                ),
              ),

              if (!nativeAvailable) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Native sensor connection is available in Android and iOS app builds. Browser preview can show the activation steps but will not connect to a physical sensor.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
              if (appState.cgmLastError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  appState.cgmLastError!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _authorizing
                    ? null
                    : () async {
                        final confirmed = await ConfirmDialog.show(
                          context,
                          title: 'Start sensor activation',
                          content:
                              'This will begin the sensor activation process. Make sure you have a new sensor pack ready.',
                          confirmLabel: 'Start',
                        );
                        if (!confirmed || !context.mounted) return;
                        if (nativeAvailable) {
                          var authorized =
                              appState.cgmAuthorized ||
                              await CgmSdkService.instance.checkAuthorized();
                          if (!context.mounted) return;
                          if (!authorized) {
                            await _authorizeSdk(context, ref);
                            if (!context.mounted) return;
                            authorized =
                                ref.read(appControllerProvider).cgmAuthorized ||
                                await CgmSdkService.instance.checkAuthorized();
                            if (!context.mounted) return;
                            if (!authorized) return;
                          }
                        }
                        ref
                            .read(appControllerProvider.notifier)
                            .startSensorActivation();
                        unawaited(context.push('/sensor/attach'));
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start activation'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _authorizeSdk(BuildContext context, WidgetRef ref) async {
    final env = EnvConfig.current;
    final appId = env.cgmSdkAppId;
    final appSecret = env.cgmSdkAppSecret;
    await ref.read(connectivityProvider.notifier).refresh();
    if (ref.read(connectivityProvider) == ConnectivityStatus.offline) {
      ref
          .read(appControllerProvider.notifier)
          .setCgmAuthState(
            authorized: false,
            error: 'Internet connection is required for SDK authorization.',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connect to the internet before SDK authorization.'),
          ),
        );
      }
      return;
    }
    if (appId.isEmpty || appSecret.isEmpty) {
      ref
          .read(appControllerProvider.notifier)
          .setCgmAuthState(
            authorized: false,
            error: 'SDK appId or appSecret is missing from configuration.',
          );
      return;
    }

    setState(() => _authorizing = true);
    final controller = ref.read(appControllerProvider.notifier);
    try {
      final repository = _cgmRepository();
      final authResult = await repository.authorize(
        appId: appId,
        appSecret: appSecret,
      );
      final authorized = authResult.success;
      controller.setCgmAuthState(
        authorized: authorized,
        error: authorized
            ? null
            : authResult.error ?? 'SDK authorization was not accepted.',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authorized ? 'SDK authorized.' : 'SDK authorization failed.',
            ),
          ),
        );
      }
    } catch (error) {
      controller.setCgmAuthState(authorized: false, error: error.toString());
    } finally {
      if (mounted) setState(() => _authorizing = false);
    }
  }
}

class AttachSensorInstructionsScreen extends ConsumerWidget {
  const AttachSensorInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Step 1',
          title: 'Attach sensor',
          subtitle: 'Follow these steps to attach your sensor correctly.',
        ),
        const _InstructionStep(
          number: '1',
          icon: Icons.sanitizer_outlined,
          title: 'Clean and dry the site',
          detail:
              'Use an alcohol wipe on the back of your upper arm, then let the skin dry fully before applying.',
          color: AppColors.meadow,
        ),
        const _InstructionStep(
          number: '2',
          icon: Icons.ads_click_rounded,
          title: 'Press the applicator flat',
          detail:
              'Place the applicator squarely on the prepared site and press firmly until the sensor is seated.',
          color: AppColors.honey,
        ),
        const _InstructionStep(
          number: '3',
          icon: Icons.task_alt_rounded,
          title: 'Check that the sensor is secure',
          detail:
              'Smooth the adhesive edge and avoid lifting the sensor after placement.',
          color: AppColors.primary,
        ),
        const _InstructionStep(
          number: '4',
          icon: Icons.bluetooth_searching_rounded,
          title: 'Keep phone nearby for pairing',
          detail:
              'Hold the phone close to the sensor, scan the code, and keep Bluetooth on during activation.',
          color: AppColors.accentDeep,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () {
            ref.read(appControllerProvider.notifier).attachSensor();
            context.push('/sensor/scan');
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Sensor attached'),
        ),
      ],
    );
  }
}

class ScanSensorScreen extends ConsumerStatefulWidget {
  const ScanSensorScreen({super.key});

  @override
  ConsumerState<ScanSensorScreen> createState() => _ScanSensorScreenState();
}

class _ScanSensorScreenState extends ConsumerState<ScanSensorScreen> {
  late final TextEditingController _serialController;
  var _connecting = false;
  var _connectionFailed = false;
  var _backgroundReliabilityRequested = false;
  var _elapsedSeconds = 0;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    final sensor = ref.read(selectedSensorProvider);
    final state = ref.read(appControllerProvider);
    _serialController = TextEditingController(
      text: state.cgmSensorSn ?? sensor?.serialNumber ?? '',
    );
  }

  @override
  void dispose() {
    _serialController.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedSeconds = 0;
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  String? _nearbyDeviceLabel(AppState appState) {
    final name = appState.cgmNearbyDeviceName;
    final address = appState.cgmNearbyDeviceAddress;
    final hasUsefulName =
        name != null && name.isNotEmpty && name.toLowerCase() != 'unknown';
    final label = hasUsefulName ? name : address ?? name;
    if (label == null || label.isEmpty) return null;

    final rssi = appState.cgmNearbyDeviceRssi;
    return rssi == null ? 'Found: $label' : 'Found: $label ($rssi dBm)';
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final nativeAvailable = _isNativeSdkAvailable;
    final nearbyDeviceLabel = _nearbyDeviceLabel(appState);

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Step 2',
          title: 'Scan and connect',
          subtitle: 'Hold your phone near the sensor to pair.',
        ),
        PremiumCard(
          child: Column(
            children: [
              const Icon(
                Icons.bluetooth_searching_rounded,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Ready to scan',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                nativeAvailable
                    ? 'Hold your phone near the sensor to scan and establish a Bluetooth connection.'
                    : 'Enter a serial number to preview the activation flow. Physical Bluetooth connection requires Android or iOS.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _serialController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Sensor serial number',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _connecting
                      ? null
                      : () => unawaited(
                          _scanQrAndConnect(context, ref, nativeAvailable),
                        ),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan sensor code'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (appState.cgmConnectionStatus.isNotEmpty)
                StatusPill(
                  label: appState.cgmConnected
                      ? 'CONNECTED'
                      : appState.cgmConnecting || _connecting
                      ? 'CONNECTING'
                      : appState.cgmConnectionStatus.toUpperCase(),
                  color: appState.cgmConnected
                      ? AppColors.success
                      : appState.cgmLastError == null
                      ? AppColors.primary
                      : AppColors.danger,
                  icon: appState.cgmConnected
                      ? Icons.bluetooth_connected_rounded
                      : Icons.bluetooth_searching_rounded,
                ),
              if (appState.cgmLastError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  appState.cgmLastError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
              if (_connecting) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Searching for sensor... ${_elapsedSeconds}s / 30s',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                if (nearbyDeviceLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    nearbyDeviceLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  child: LinearProgressIndicator(
                    value: _elapsedSeconds / 30.0,
                    minHeight: 4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _connecting
                          ? null
                          : () =>
                                _scanAndConnect(context, ref, nativeAvailable),
                      icon: _connecting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.radar_rounded),
                      label: Text(
                        _connectionFailed ? 'Retry' : 'Connect sensor',
                      ),
                    ),
                  ),
                  if (_connecting) ...[
                    const SizedBox(width: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _cancelConnection,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _cancelConnection() {
    _stopElapsedTimer();
    BleConnectionGuard.forceRelease();
    CgmSdkService.instance.disconnect();
    final controller = ref.read(appControllerProvider.notifier);
    controller.setCgmConnectionState(
      status: 'Connection cancelled',
      connected: false,
      connecting: false,
      sensorSn: _serialController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _connecting = false;
        _connectionFailed = true;
      });
    }
  }

  Future<void> _scanQrAndConnect(
    BuildContext context,
    WidgetRef ref,
    bool nativeAvailable,
  ) async {
    if (nativeAvailable) {
      final cameraStatus = await CgmSdkService.instance
          .requestCameraPermission();
      if (!_canContinueWithCameraPermissionStatus(cameraStatus)) {
        if (!context.mounted) return;
        final message = cameraStatus == 'permanentlyDenied'
            ? 'Camera permission is permanently denied. Enable camera access in settings and try again.'
            : 'Camera permission is required to scan the sensor code.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        if (cameraStatus == 'permanentlyDenied' || cameraStatus == 'error') {
          await _showPermissionSettingsDialog(
            context,
            title: 'Camera permission required',
            message:
                'Open app settings and allow camera access for Optimus CGM.',
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    final rawScan = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _SensorQrScannerSheet(),
    );
    if (!context.mounted || rawScan == null) return;

    final serial = parseSensorSerialFromQr(rawScan);
    if (serial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code scanned, but no sensor serial number was found.'),
        ),
      );
      return;
    }

    _serialController.text = serial;
    ref
        .read(appControllerProvider.notifier)
        .addCgmLog('QR scan captured sensor serial.');
    await _scanAndConnect(context, ref, nativeAvailable);
  }

  Future<void> _scanAndConnect(
    BuildContext context,
    WidgetRef ref,
    bool nativeAvailable,
  ) async {
    final serial = parseSensorSerialFromQr(_serialController.text);
    if (serial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter or scan a valid sensor serial number.'),
        ),
      );
      return;
    }
    _serialController.text = serial;

    final controller = ref.read(appControllerProvider.notifier);
    final service = CgmSdkService.instance;
    final repository = _cgmRepository();

    if (nativeAvailable) {
      // Debounce: prevent multiple simultaneous connection attempts
      if (!BleConnectionGuard.tryAcquire()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A connection attempt is already in progress. Please wait.',
              ),
            ),
          );
        }
        return;
      }

      final permissionStatus = await repository.requestBluetoothPermissions();
      if (!mounted) {
        BleConnectionGuard.release();
        return;
      }
      if (!_canContinueWithPermissionStatus(permissionStatus)) {
        BleConnectionGuard.release();
        final message = _bluetoothPermissionMessage(permissionStatus);
        controller.setCgmConnectionState(
          status: 'Bluetooth permission required',
          connected: false,
          connecting: false,
          sensorSn: serial,
          error: message,
        );
        setState(() => _connectionFailed = true);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          if (permissionStatus == 'permanentlyDenied' ||
              permissionStatus == 'error') {
            await _showPermissionSettingsDialog(
              context,
              title: 'Bluetooth permission required',
              message:
                  'Open app settings and allow Bluetooth access for Optimus CGM.',
            );
          }
        }
        return;
      }

      await ref.read(bleStateProvider.notifier).refresh();
      if (!mounted) {
        BleConnectionGuard.release();
        return;
      }

      // Verify Bluetooth is powered on after permission is confirmed.
      final bleState = ref.read(bleStateProvider);
      if (bleState == BleAdapterState.unauthorized) {
        BleConnectionGuard.release();
        const message =
            'Bluetooth permission is not granted. Please allow Nearby devices and try again.';
        controller.setCgmConnectionState(
          status: 'Bluetooth permission required',
          connected: false,
          connecting: false,
          sensorSn: serial,
          error: message,
        );
        setState(() => _connectionFailed = true);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text(message)));
        }
        return;
      }
      if (bleState == BleAdapterState.poweredOff) {
        BleConnectionGuard.release();
        controller.setCgmConnectionState(
          status: 'Bluetooth is off',
          connected: false,
          connecting: false,
          sensorSn: serial,
          error:
              'Bluetooth is turned off. Please enable Bluetooth and try again.',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable Bluetooth before connecting.'),
            ),
          );
          await CgmSdkService.instance.openBluetoothSettings();
        }
        return;
      }

      // BLE stack health check
      final bleNotifier = ref.read(bleStateProvider.notifier);
      if (bleNotifier.isStackUnhealthy) {
        BleConnectionGuard.release();
        if (context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Bluetooth Issue Detected'),
              content: const Text(
                'Multiple Bluetooth failures have been detected. '
                'Try toggling Bluetooth off and on in your device settings, '
                'or restart your device if the issue persists.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    unawaited(CgmSdkService.instance.openBluetoothSettings());
                  },
                  child: const Text('Bluetooth settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final appState = ref.read(appControllerProvider);
      final authorized =
          appState.cgmAuthorized || await repository.checkAuthorized();
      if (!authorized) {
        BleConnectionGuard.release();
        controller.setCgmConnectionState(
          status: 'SDK authorization required',
          connected: false,
          connecting: false,
          sensorSn: serial,
          error: 'Authorize the CGM SDK with appId and appSecret first.',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authorize the SDK before connecting the sensor.'),
            ),
          );
        }
        return;
      }
      if (!appState.cgmAuthorized) {
        controller.setCgmAuthState(authorized: true);
      }
    }

    // Cancel any active reconnection since user is manually connecting
    ref.read(bleReconnectionProvider.notifier).cancel();
    if (nativeAvailable) {
      await service.stopHeartbeat();
    }

    controller.scanAndConnectSensor(
      serialNumber: serial,
      previewOnly: !nativeAvailable,
    );

    if (!nativeAvailable) {
      if (context.mounted) unawaited(context.push('/sensor/warmup'));
      return;
    }

    setState(() {
      _connecting = true;
      _connectionFailed = false;
    });
    _startElapsedTimer();
    try {
      final connectResult = await repository.connect(sensorSn: serial);
      final connected = connectResult.success;

      _stopElapsedTimer();
      if (connected) {
        BleConnectionGuard.release();
        ref.read(bleStateProvider.notifier).resetFailures();
        unawaited(HapticFeedback.mediumImpact());
        controller.setCgmConnectionState(
          status: 'Sensor connected',
          connected: true,
          connecting: false,
          sensorSn: serial,
        );
        controller.addCgmLog('Bluetooth connected. Sensor connected.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bluetooth connected. Sensor connected successfully.',
              ),
            ),
          );
        }
        await service.startHeartbeat();
        unawaited(_requestBackgroundBleReliability(repository, controller));
        await controller.registerConnectedSensor(serialNumber: serial);
        try {
          // Resume from last sync checkpoint if available
          final resumeIndex = BleSyncCheckpoint.resumeIndex(serial);
          final history = await service.getHistoryFromIndexStart(
            sensorSn: serial,
            indexStart: resumeIndex,
          );
          if (history.isNotEmpty) {
            controller.applyCgmReadings(history);
            // Update checkpoint with latest synced index
            final maxIndex = history
                .map((r) => r.timeOffset)
                .reduce((a, b) => a > b ? a : b);
            BleSyncCheckpoint.update(sensorSn: serial, lastIndex: maxIndex);
          }
        } catch (_) {
          controller.addCgmLog(
            'History sync will continue from SDK callbacks.',
          );
        }
        if (context.mounted) unawaited(context.push('/sensor/warmup'));
      } else {
        BleConnectionGuard.release();
        ref.read(bleStateProvider.notifier).recordFailure();
        final latestError = ref.read(appControllerProvider).cgmLastError;
        // Connection returned false: sensor not found or timed out.
        controller.setCgmConnectionState(
          status: 'Connection failed',
          connected: false,
          connecting: false,
          sensorSn: serial,
          error:
              latestError ??
              connectResult.error ??
              'Could not connect to sensor. Ensure the sensor is nearby, powered on, and Bluetooth is enabled.',
        );
        if (mounted) setState(() => _connectionFailed = true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Connection failed. Check sensor proximity and try again.',
              ),
            ),
          );
        }
      }
    } catch (_) {
      _stopElapsedTimer();
      BleConnectionGuard.release();
      const message =
          'Sensor connection failed. Keep the phone close to the sensor and try again.';
      controller.setCgmConnectionState(
        status: 'Sensor connection failed',
        connected: false,
        connecting: false,
        sensorSn: serial,
        error: message,
      );
      if (mounted) setState(() => _connectionFailed = true);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(message)));
      }
    } finally {
      _stopElapsedTimer();
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _requestBackgroundBleReliability(
    CgmSdkRepository repository,
    AppController controller,
  ) async {
    if (_backgroundReliabilityRequested) return;
    _backgroundReliabilityRequested = true;

    try {
      final backgroundStatus = await repository
          .requestBleAndBackgroundPermissions();
      controller.addCgmLog('Background BLE permission: $backgroundStatus.');

      final batteryStatus = await repository.requestIgnoreBatteryOptimization();
      controller.addCgmLog('Battery optimization: $batteryStatus.');
    } catch (error) {
      controller.addCgmLog('Background BLE reliability setup skipped: $error');
    }
  }

  Future<void> _showPermissionSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(CgmSdkService.instance.openAppPermissionSettings());
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }
}

class _SensorQrScannerSheet extends StatefulWidget {
  const _SensorQrScannerSheet();

  @override
  State<_SensorQrScannerSheet> createState() => _SensorQrScannerSheetState();
}

class _SensorQrScannerSheetState extends State<_SensorQrScannerSheet> {
  late final MobileScannerController _controller;
  var _handledScan = false;
  var _cameraReady = false;
  var _checkingCamera = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      // CGM packaging commonly uses GS1 DataMatrix rather than QR.
      // Leaving formats unset lets ML Kit detect any supported barcode.
    );
    _controller.addListener(_onControllerStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onControllerStateChanged() {
    if (!mounted) return;
    final state = _controller.value;
    if (state.isRunning && !_cameraReady) {
      setState(() {
        _checkingCamera = false;
        _cameraReady = true;
        _errorText = null;
      });
    } else if (state.error != null && _checkingCamera) {
      setState(() {
        _checkingCamera = false;
        _cameraReady = false;
        _errorText =
            state.error!.errorDetails?.message ??
            'Camera could not start. Ensure camera permission is granted and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.86,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Scan sensor code',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: _handleDetect,
                        errorBuilder: (context, error) {
                          return ColoredBox(
                            color: Colors.black,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Text(
                                  error.errorDetails?.message ??
                                      error.errorCode.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (!_cameraReady)
                        ColoredBox(
                          color: Colors.black,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_checkingCamera)
                                    const SizedBox.square(
                                      dimension: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.no_photography_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    _errorText ?? 'Starting camera...',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (!_checkingCamera) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    FilledButton(
                                      onPressed: () => unawaited(
                                        CgmSdkService.instance
                                            .openAppPermissionSettings(),
                                      ),
                                      child: const Text('Open settings'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          height: 232,
                          width: 232,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            border: Border.all(
                              color: AppColors.onDark,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: AppSpacing.lg,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              _errorText ??
                                  'Align the sensor code inside the frame.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cameraReady
                          ? () => unawaited(_controller.toggleTorch())
                          : null,
                      icon: const Icon(Icons.flash_on_rounded),
                      label: const Text('Torch'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cameraReady
                          ? () => unawaited(_controller.switchCamera())
                          : null,
                      icon: const Icon(Icons.cameraswitch_rounded),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_handledScan) return;

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        rawValue = value;
        break;
      }
    }
    if (rawValue == null) return;

    final serial = parseSensorSerialFromQr(rawValue);
    if (serial == null) {
      if (mounted) {
        setState(
          () => _errorText =
              'Code detected, but no sensor serial number was found.',
        );
      }
      return;
    }

    _handledScan = true;
    unawaited(HapticFeedback.selectionClick());
    Navigator.of(context).pop(rawValue);
  }
}

class WarmupCountdownScreen extends ConsumerWidget {
  const WarmupCountdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensor = ref.watch(selectedSensorProvider);
    final minutes = warmupMinutesRemaining(sensor);

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Step 3',
          title: 'Warm-up',
          subtitle: 'Your sensor is calibrating for accurate readings.',
        ),
        PremiumCard(
          color: AppColors.warningSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill(
                label: 'WARMING UP',
                color: AppColors.warning,
                icon: Icons.hourglass_top_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '$minutes min',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.warning,
                ),
              ),
              Text(
                'Keep the phone near the sensor while first readings become available.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: minutes == 0
                        ? () {
                            ref
                                .read(appControllerProvider.notifier)
                                .finishWarmupNow();
                            context.push('/sensor/status');
                          }
                        : null,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      minutes == 0 ? 'Complete warm-up' : 'Warming up',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/sensor/status'),
                    icon: const Icon(Icons.info_outline_rounded),
                    label: const Text('Status'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SensorStatusScreen extends ConsumerWidget {
  const SensorStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensor = ref.watch(selectedSensorProvider);
    final appState = ref.watch(appControllerProvider);
    final daysLeft = sensorDaysRemaining(sensor);
    final batteryLevel = sensor?.batteryStatus ?? 100;
    final statusColor = sensor?.status == SensorStatus.active
        ? AppColors.success
        : sensor?.status == SensorStatus.warmingUp
        ? AppColors.warning
        : AppColors.primary;

    return AppScreen(
      children: [
        // Battery low warning
        if (batteryLevel < 20)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.battery_alert_rounded,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Sensor battery low ($batteryLevel%). Consider replacing soon.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SectionHeader(
          showBack: true,
          eyebrow: 'Sensor',
          title: 'Sensor status',
          subtitle: 'Current sensor health and connection details.',
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.wellness,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.wellness.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(
                label: sensor?.status.name.toUpperCase() ?? 'UNKNOWN',
                color: statusColor,
                icon: Icons.sensors_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                sensor?.serialNumber ?? '--',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                appState.cgmConnectionStatus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onDarkMuted,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final metrics = [
                    _SensorMetric(
                      label: 'Battery',
                      value: '${sensor?.batteryStatus ?? 0}%',
                    ),
                    _SensorMetric(label: 'Life', value: '${daysLeft}d'),
                    _SensorMetric(
                      label: 'Signal',
                      value: sensor?.connectionStatus.name ?? 'offline',
                    ),
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: metrics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: compact ? 1 : 3,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      mainAxisExtent: 72,
                    ),
                    itemBuilder: (context, index) =>
                        _SensorMetricCard(metric: metrics[index]),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Readiness checklist',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReadinessRow(
                icon: Icons.bluetooth_connected_rounded,
                label: 'Connection',
                value: sensor?.connectionStatus.name ?? 'offline',
                ready: sensor?.connectionStatus == ConnectionStatus.connected,
              ),
              _ReadinessRow(
                icon: Icons.hourglass_top_rounded,
                label: 'Warm-up',
                value: '${warmupMinutesRemaining(sensor)} min remaining',
                ready: warmupMinutesRemaining(sensor) == 0,
              ),
              _ReadinessRow(
                icon: Icons.monitor_heart_rounded,
                label: 'Data stream',
                value: appState.cgmConnected
                    ? 'Live readings'
                    : 'Waiting for readings',
                ready: appState.cgmConnected,
                bottomPadding: 0,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Expanded(child: ReadNowButton(filled: true)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.go('/readings'),
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text('Open readings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Spacer(),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/devices'),
                      icon: const Icon(Icons.hub_outlined),
                      label: const Text('Devices'),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SensorMetric {
  const _SensorMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _SensorMetricCard extends StatelessWidget {
  const _SensorMetricCard({required this.metric});

  final _SensorMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.onDark.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.onDark.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onDarkMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.onDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ready,
    this.bottomPadding = AppSpacing.md,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ready;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final color = ready ? AppColors.success : AppColors.warning;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          StatusPill(
            label: ready ? 'READY' : 'CHECK',
            color: color,
            icon: ready
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  final String number;
  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumCard(
        elevated: false,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 104,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: color.withValues(alpha: 0.12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Icon(icon, color: AppColors.onDark, size: 30),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      number,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        detail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
