import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_notification_service.dart';
import 'app_state.dart';

final sensorDisconnectAlertCoordinatorProvider = Provider<void>((ref) {
  Timer? reminderTimer;
  String? activeSensorSn;
  DateTime? lastReminderAt;
  Duration? activeInterval;

  void cancelReminder() {
    reminderTimer?.cancel();
    reminderTimer = null;
    activeSensorSn = null;
    lastReminderAt = null;
    activeInterval = null;
  }

  bool shouldNotify(AppState state) {
    final sensorSn = state.cgmSensorSn;
    return state.alertSettings.notificationsEnabled &&
        sensorSn != null &&
        sensorSn.isNotEmpty &&
        state.cgmWasEverConnected &&
        !state.cgmConnected &&
        !state.cgmConnecting;
  }

  Future<void> sendReminder(AppState state) async {
    final sensorSn = state.cgmSensorSn;
    if (sensorSn == null || sensorSn.isEmpty) return;
    lastReminderAt = DateTime.now();

    ref
        .read(appControllerProvider.notifier)
        .addSensorDisconnectAlert(sensorSn: sensorSn);
    unawaited(HapticFeedback.heavyImpact());
    await PushNotificationService.instance.notifySensorDisconnected(
      sensorSn: sensorSn,
    );
  }

  void schedule(AppState state) {
    if (!shouldNotify(state)) {
      cancelReminder();
      return;
    }

    final sensorSn = state.cgmSensorSn!;
    final interval = Duration(
      minutes: state.alertSettings.sensorDisconnectReminderMinutes
          .clamp(1, 240)
          .toInt(),
    );
    final sensorChanged = activeSensorSn != sensorSn;
    final intervalChanged = activeInterval != interval;

    if (sensorChanged || intervalChanged) {
      reminderTimer?.cancel();
      reminderTimer = null;
      activeSensorSn = sensorSn;
      activeInterval = interval;
      lastReminderAt = null;
    }

    if (lastReminderAt == null) {
      unawaited(sendReminder(state));
    }

    reminderTimer ??= Timer.periodic(interval, (_) {
      final current = ref.read(appControllerProvider);
      if (!shouldNotify(current)) {
        cancelReminder();
        return;
      }
      unawaited(sendReminder(current));
    });
  }

  ref.listen<AppState>(appControllerProvider, (_, next) => schedule(next));
  schedule(ref.read(appControllerProvider));
  ref.onDispose(cancelReminder);
});
