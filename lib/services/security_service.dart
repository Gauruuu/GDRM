import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const _channel = MethodChannel('com.gdrm.ecosystem/security');
  static const _prefRegistered = 'gdrm_win_registered';

  static Future<void> init() async {
    if (Platform.isWindows) {
      await _applyWindowsScreenshotPrevention();
      await _registerWindowsFileAssociation();
    }
    // Android: FLAG_SECURE is set natively in MainActivity.kt — nothing to do here
  }

  static Future<void> _applyWindowsScreenshotPrevention() async {
    try {
      await _channel.invokeMethod('setSecureWindow');
    } catch (_) {}
  }

  static Future<void> _registerWindowsFileAssociation() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefRegistered) == true) return;
    try {
      final exePath = Platform.resolvedExecutable;
      await _reg(r'HKCU\Software\Classes\.gdrm', '', 'GDRMEcosystemFile');
      await _reg(r'HKCU\Software\Classes\.gdrm', 'Content Type', 'application/x-gdrm');
      await _reg(r'HKCU\Software\Classes\GDRMEcosystemFile', '', 'GDRM Protected Document');
      await _reg(r'HKCU\Software\Classes\GDRMEcosystemFile\DefaultIcon', '', '$exePath,0');
      await _reg(r'HKCU\Software\Classes\GDRMEcosystemFile\shell\open\command', '', '"$exePath" "%1"');
      await prefs.setBool(_prefRegistered, true);
    } catch (_) {}
  }

  static Future<void> _reg(String key, String valueName, String data) async {
    final args = ['add', key, '/f'];
    if (valueName.isEmpty) {
      args.addAll(['/ve', '/d', data]);
    } else {
      args.addAll(['/v', valueName, '/d', data]);
    }
    await Process.run('reg', args);
  }
}