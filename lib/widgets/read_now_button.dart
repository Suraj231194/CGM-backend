import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ble/ble_connection_guard.dart';
import '../core/ble/ble_reconnection_policy.dart';
import '../services/cgm_sdk_service.dart';
import '../state/app_state.dart';

bool get _isNativeSdkAvailable =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class ReadNowButton extends ConsumerStatefulWidget {
  const ReadNowButton({
    super.key,
    this.filled = false,
    this.label = 'Read now',
  });

  final bool filled;
  final String label;

  @override
  ConsumerState<ReadNowButton> createState() => _ReadNowButtonState();
}

class _ReadNowButtonState extends ConsumerState<ReadNowButton> {
  var _reading = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !_reading;
    final icon = _reading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.refresh_rounded);

    if (widget.filled) {
      return FilledButton.icon(
        onPressed: enabled ? _readNow : null,
        icon: icon,
        label: Text(_reading ? 'Reading...' : widget.label),
      );
    }

    return OutlinedButton.icon(
      onPressed: enabled ? _readNow : null,
      icon: icon,
      label: Text(_reading ? 'Reading...' : widget.label),
    );
  }

  Future<void> _readNow() async {
    final appState = ref.read(appControllerProvider);
    final sensorSn = appState.cgmSensorSn;
    if (sensorSn == null || sensorSn.isEmpty) {
      _showMessage('Connect a sensor before reading now.');
      return;
    }

    if (!_isNativeSdkAvailable) {
      _showMessage('Read Now is available in Android and iOS app builds.');
      return;
    }

    if (!appState.cgmConnected) {
      ref.read(bleReconnectionProvider.notifier).startReconnection(sensorSn);
      _showMessage('Reconnecting to sensor. Keep the phone nearby.');
      return;
    }

    setState(() => _reading = true);
    final controller = ref.read(appControllerProvider.notifier);
    try {
      final startIndex = math.max(
        1,
        BleSyncCheckpoint.resumeIndex(sensorSn) - 1,
      );
      final readings = await CgmSdkService.instance.getHistoryFromIndexStart(
        sensorSn: sensorSn,
        indexStart: startIndex,
      );
      if (readings.isNotEmpty) {
        controller.applyCgmReadings(readings);
        _showMessage('Latest sensor reading updated.');
      } else {
        await CgmSdkService.instance.startHeartbeat();
        controller.addCgmLog('Read Now requested latest sensor data.');
        _showMessage('Listening for the latest sensor reading.');
      }
    } catch (_) {
      controller.setCgmConnectionState(
        status: 'Read Now failed',
        connected: false,
        connecting: false,
        sensorSn: sensorSn,
        error:
            'Could not read from the sensor. Keep the phone nearby and try again.',
      );
      _showMessage('Could not read from the sensor. Try again nearby.');
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
