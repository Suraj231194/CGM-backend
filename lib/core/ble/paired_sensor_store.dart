import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/sensor_serial_parser.dart';

class PairedSensorStore {
  const PairedSensorStore._();

  static const _sensorSnKey = 'optimus_paired_sensor_sn_v1';
  static const _lastConnectedAtKey = 'optimus_paired_sensor_last_connected_v1';

  static Future<String?> loadSensorSn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return normalizeSensorSerial(prefs.getString(_sensorSnKey));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save({
    required String sensorSn,
    DateTime? connectedAt,
  }) async {
    final clean = normalizeSensorSerial(sensorSn);
    if (clean == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sensorSnKey, clean);
      await prefs.setString(
        _lastConnectedAtKey,
        (connectedAt ?? DateTime.now()).toIso8601String(),
      );
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sensorSnKey);
      await prefs.remove(_lastConnectedAtKey);
    } catch (_) {}
  }
}
