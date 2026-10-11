import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const _channel = MethodChannel('com.gdrm.ecosystem/security');
  static const _prefRegisteredExe = 'gdrm_win_registered_exe';

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
    try {
      final exePath = Platform.resolvedExecutable;
      if (!exePath.toLowerCase().endsWith('.exe')) return;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_prefRegisteredExe) == exePath) return;

      final escapedExe = exePath.replaceAll("'", "''");
      final script = '''
\$exe = '$escapedExe'
\$p = 'HKCU:\\Software\\Classes'
New-Item -Path "\$p\\.gdrm" -Force | Out-Null
Set-ItemProperty -Path "\$p\\.gdrm" -Name '(default)' -Value 'GDRMEcosystemFile'
Set-ItemProperty -Path "\$p\\.gdrm" -Name 'Content Type' -Value 'application/x-gdrm'
New-Item -Path "\$p\\.gdrm\\OpenWithProgids" -Force | Out-Null
Set-ItemProperty -Path "\$p\\.gdrm\\OpenWithProgids" -Name 'GDRMEcosystemFile' -Value ''
New-Item -Path "\$p\\GDRMEcosystemFile\\shell\\open\\command" -Force | Out-Null
Set-ItemProperty -Path "\$p\\GDRMEcosystemFile\\shell\\open\\command" -Name '(default)' -Value ('"' + \$exe + '" "%1"')
New-Item -Path "\$p\\GDRMEcosystemFile\\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "\$p\\GDRMEcosystemFile\\DefaultIcon" -Name '(default)' -Value (\$exe + ',0')
New-Item -Path "\$p\\Applications\\gdrm_ecosystem.exe\\shell\\open\\command" -Force | Out-Null
Set-ItemProperty -Path "\$p\\Applications\\gdrm_ecosystem.exe\\shell\\open\\command" -Name '(default)' -Value ('"' + \$exe + '" "%1"')
New-Item -Path "\$p\\Applications\\GDRM III.exe\\shell\\open\\command" -Force | Out-Null
Set-ItemProperty -Path "\$p\\Applications\\GDRM III.exe\\shell\\open\\command" -Name '(default)' -Value ('"' + \$exe + '" "%1"')
New-Item -Path "\$p\\Applications\\GDRM Ecosystem.exe\\shell\\open\\command" -Force | Out-Null
Set-ItemProperty -Path "\$p\\Applications\\GDRM Ecosystem.exe\\shell\\open\\command" -Name '(default)' -Value ('"' + \$exe + '" "%1"')
New-Item -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.gdrm\\OpenWithProgids' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.gdrm\\OpenWithProgids' -Name 'GDRMEcosystemFile' -Value ''
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ShellNotifyAssoc {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int wEventId, int uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
"@
[ShellNotifyAssoc]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
''';

      await Process.run('powershell', ['-NoProfile', '-NonInteractive', '-Command', script]);
      await prefs.setString(_prefRegisteredExe, exePath);
    } catch (_) {}
  }
}