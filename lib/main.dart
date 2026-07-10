import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/ble/ble_permission_monitor.dart';
import 'core/ble/ble_state_monitor.dart';
import 'core/error/app_error_handler.dart';
import 'core/env/firebase_environment.dart';
import 'core/lifecycle/app_lifecycle_observer.dart';
import 'core/observers/app_provider_observer.dart';
import 'core/reporting/app_log_file.dart';
import 'core/reporting/crash_reporter.dart';
import 'core/security/inactivity_detector.dart';
import 'services/analytics_service.dart';
import 'services/push_notification_service.dart';
import 'repositories/repository_providers.dart';
import 'state/app_state.dart';
import 'state/cgm_sdk_event_bridge.dart';
import 'state/sensor_disconnect_alerts.dart';

void main() {
  runAppGuarded(
    ProviderScope(
      observers: [AppProviderObserver()],
      child: const OptimusCgmApp(),
    ),
    beforeRun: initializeRuntimeServices,
  );
}

Future<void> initializeRuntimeServices() async {
  try {
    if (Firebase.apps.isEmpty) {
      final options = FirebaseEnvironment.current;
      await Firebase.initializeApp(options: options);
    }
  } catch (error, stackTrace) {
    AppErrorHandler.report(error, stackTrace, 'Firebase.initializeApp');
  }

  await AppLogFile.initialize();
  await CrashReporter.initialize();
  await AnalyticsService.instance.initialize();
  await PushNotificationService.instance.initialize();
}

class OptimusCgmApp extends ConsumerWidget {
  const OptimusCgmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PushNotificationService.instance.configureApiClient(
      ref.watch(apiDioProvider),
    );
    ref.watch(persistentReadingBootstrapProvider);
    ref.watch(backendBootstrapProvider);
    ref.watch(pairedSensorBootstrapProvider);
    ref.watch(cgmSdkEventBridgeProvider);
    ref.watch(sensorDisconnectAlertCoordinatorProvider);
    ref.watch(appLifecycleProvider);
    ref.watch(bleStateProvider);
    ref.watch(blePermissionWatcherProvider);
    final router = ref.watch(appRouterProvider);
    final isAuthenticated = ref.watch(
      appControllerProvider.select((s) => s.isAuthenticated),
    );
    final authBypass = ref.watch(authBypassProvider);
    final themeMode = ref.watch(
      appControllerProvider.select((s) => s.themeMode),
    );

    return InactivityDetector(
      enabled: isAuthenticated && !authBypass,
      onTimeout: () {
        ref.read(appControllerProvider.notifier).signOut();
      },
      child: MaterialApp.router(
        title: 'Optimus CGM',
        debugShowCheckedModeBanner: false,
        theme: buildOptimusTheme(),
        darkTheme: buildOptimusDarkTheme(),
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
