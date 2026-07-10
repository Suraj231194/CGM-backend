import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseEnvironment {
  const FirebaseEnvironment._();

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static FirebaseOptions? get current {
    final appId = switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidAppId,
      TargetPlatform.iOS || TargetPlatform.macOS => _iosAppId,
      _ => _webAppId,
    };

    if (_apiKey.isEmpty ||
        _projectId.isEmpty ||
        _messagingSenderId.isEmpty ||
        appId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
    );
  }
}
