class AppLogFile {
  AppLogFile._();

  static Future<void> initialize() async {}

  static Future<String?> get logFilePath async => null;

  static Future<void> info(String message, {String source = 'app'}) async {}

  static Future<void> error(
    Object error, {
    StackTrace? stackTrace,
    String source = 'app',
  }) async {}
}
