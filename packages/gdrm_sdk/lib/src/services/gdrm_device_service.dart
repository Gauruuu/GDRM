import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Manages unique device identity, hardware binding tokens, and network resolution.
class GdrmDeviceService {
  static String? _cachedDeviceKey;
  static String? _cachedDeviceUuid;

  /// Derive deterministic 48-char device key from a device UUID
  static String deriveDeviceKey(String deviceUuid) {
    final bytes = utf8.encode('GDRM_DEVICE_SALT_v1:$deviceUuid');
    return sha256.convert(bytes).toString().substring(0, 48);
  }

  /// Hashes a password with salt for GDRM password security
  static String hashPassword(String password) {
    final bytes = utf8.encode('GDRM_PASSWORD_SALT_v1:$password');
    return sha256.convert(bytes).toString();
  }

  /// Resolves the current machine's primary IPv4 address
  static Future<String> resolveLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  /// Resolves hardware MAC address where permitted by host OS
  static Future<String> resolveMacAddress() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('getmac', ['/fo', 'csv', '/nh']);
        final lines = (result.stdout as String)
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        if (lines.isNotEmpty) {
          final match = RegExp(r'"([0-9A-Fa-f-]{17})"').firstMatch(lines.first);
          if (match != null) {
            return match.group(1)?.replaceAll('-', ':').toUpperCase() ?? 'LOCAL_DEV';
          }
        }
      }
    } catch (_) {}
    return 'LOCAL_INTERFACE';
  }

  /// Generates a RFC-4122 v4 compliant UUID
  static String generateUuid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Sets or overrides device key in memory
  static void setDeviceKey(String key) {
    _cachedDeviceKey = key;
  }

  /// Sets or overrides device UUID
  static void setDeviceUuid(String uuid) {
    _cachedDeviceUuid = uuid;
    _cachedDeviceKey = deriveDeviceKey(uuid);
  }

  /// Returns active device key (generates a runtime one if not manually supplied)
  static String getActiveDeviceKey() {
    if (_cachedDeviceKey != null) return _cachedDeviceKey!;
    _cachedDeviceUuid ??= generateUuid();
    _cachedDeviceKey = deriveDeviceKey(_cachedDeviceUuid!);
    return _cachedDeviceKey!;
  }
}
