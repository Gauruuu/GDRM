import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gdrm_model.dart';

/// Manages the persistent device UUID and derives the device key from it.
class DeviceKeyService {
  static const _prefKey = 'gdrm_device_uuid';
  static String? _cachedKey;

  /// Returns the device key, generating and persisting a UUID on first call.
  static Future<String> getDeviceKey() async {
    if (_cachedKey != null) return _cachedKey!;

    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString(_prefKey);

    if (uuid == null) {
      uuid = _generateUuid();
      await prefs.setString(_prefKey, uuid);
    }

    _cachedKey = GdrmService.buildDeviceKey(uuid);
    return _cachedKey!;
  }

  static String _generateUuid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
