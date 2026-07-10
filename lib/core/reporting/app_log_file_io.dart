import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AppLogFile {
  AppLogFile._();

  static const _maxLogBytes = 1024 * 1024;
  static File? _file;
  static Future<File?>? _initFuture;
  static Future<void> _pendingWrite = Future.value();

  static Future<void> initialize() async {
    await _ensureFile();
    await info('App log initialized.', source: 'AppLogFile');
  }

  static Future<String?> get logFilePath async => (await _ensureFile())?.path;

  static Future<void> info(String message, {String source = 'app'}) {
    return _enqueue('INFO', source, message);
  }

  static Future<void> error(
    Object error, {
    StackTrace? stackTrace,
    String source = 'app',
  }) {
    final buffer = StringBuffer(error);
    if (stackTrace != null) {
      buffer
        ..writeln()
        ..write(stackTrace);
    }
    return _enqueue('ERROR', source, buffer.toString());
  }

  static Future<void> _enqueue(String level, String source, String message) {
    _pendingWrite = _pendingWrite
        .catchError((_) {})
        .then((_) => _write(level, source, message));
    return _pendingWrite;
  }

  static Future<void> _write(
    String level,
    String source,
    String message,
  ) async {
    try {
      final file = await _ensureFile();
      if (file == null) return;
      await _rotateIfNeeded(file);
      final timestamp = DateTime.now().toIso8601String();
      final safeSource = _singleLine(_redact(source));
      final safeMessage = _redact(message).trimRight();
      await file.writeAsString(
        '[$timestamp] [$level] [$safeSource] $safeMessage\n',
        mode: FileMode.append,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[AppLogFile] write failed: $error');
      }
    }
  }

  static Future<File?> _ensureFile() {
    return _initFuture ??= _createFile();
  }

  static Future<File?> _createFile() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final logDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}logs',
      );
      if (!await logDirectory.exists()) {
        await logDirectory.create(recursive: true);
      }
      _file = File(
        '${logDirectory.path}${Platform.pathSeparator}optimus_cgm.log',
      );
      if (!await _file!.exists()) {
        await _file!.create(recursive: true);
      }
      return _file;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[AppLogFile] init failed: $error');
      }
      return null;
    }
  }

  static Future<void> _rotateIfNeeded(File file) async {
    if (!await file.exists()) return;
    final length = await file.length();
    if (length < _maxLogBytes) return;

    final rotated = File('${file.path}.1');
    if (await rotated.exists()) {
      await rotated.delete();
    }
    await file.rename(rotated.path);
    _file = File(file.path);
    await _file!.create(recursive: true);
  }

  static String _redact(String value) {
    return value
        .replaceAll(
          RegExp(
            r'((?:appSecret|app_secret|secret|token|password)\s*[:=]\s*)[^\s,;}]+',
            caseSensitive: false,
          ),
          r'$1<redacted>',
        )
        .replaceAll(
          RegExp(
            r'((?:authorization|bearer)\s+)[A-Za-z0-9._~+/-]+=*',
            caseSensitive: false,
          ),
          r'$1<redacted>',
        );
  }

  static String _singleLine(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
