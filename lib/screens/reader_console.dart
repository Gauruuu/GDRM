import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/gdrm_model.dart';
import '../services/device_key_service.dart';
import '../services/content_uri_service.dart';
import '../services/printing_service.dart';
import '../services/piracy_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/dynamic_watermark.dart';
import 'piracy_screen.dart';
import 'chrono_lock_screen.dart';
import 'snail_trail_screen.dart';
import 'global_auth_screen.dart';

class ReaderConsole extends StatefulWidget {
  const ReaderConsole({super.key});

  @override
  ReaderConsoleState createState() => ReaderConsoleState();
}

class ReaderConsoleState extends State<ReaderConsole> {
  final PdfViewerController _ctrl = PdfViewerController();
  final FocusNode _viewerFocusNode = FocusNode();
  String? _loadedPdfPath;
  String? _loadedGdrmPath;
  int _currentPage = 1;
  int _totalPages = 0;

  DateTime? _openTimestamp;

  // ── RiggedFile Live Countdown States ──
  Timer? _meltTimer;
  Duration _timeBombRemaining = Duration.zero;

  // Device network credentials for watermarked printing
  String _deviceIp = 'Local Workstation';
  String _deviceMac = 'Local Device';

  @override
  void initState() {
    super.initState();
    _resolveNetworkInfo();
  }

  @override
  void dispose() {
    _timerCancel();
    _writeCloseTrailLog();
    _viewerFocusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _resolveNetworkInfo() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            _deviceIp = addr.address;
            break;
          }
        }
      }
    } catch (_) {}

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
            _deviceMac = match.group(1)?.replaceAll('-', ':').toUpperCase() ?? 'Local Device';
          }
        }
      }
    } catch (_) {}
  }

  void _timerCancel() {
    _meltTimer?.cancel();
  }

  void _startLiveMeltTimer(DateTime expiry, String filePath) {
    _meltTimer?.cancel();
    _updateRemainingTime(expiry, filePath);

    _meltTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime(expiry, filePath);
    });
  }

  void _updateRemainingTime(DateTime expiry, String filePath) async {
    final now = DateTime.now().toUtc();
    final diff = expiry.difference(now);

    if (!mounted) return;

    if (diff.isNegative || diff == Duration.zero) {
      _meltTimer?.cancel();
      setState(() {
        _timeBombRemaining = Duration.zero;
        _loadedPdfPath = null;
      });

      try {
        final corrupted = GdrmService.deployedTerminalSelfDestruct();
        await GdrmService.writeFile(filePath, corrupted);
      } catch (_) {}

      _showError(
          'CRITICAL RIGGED MELT TRIGGERED:\nThis file lifespan timing has ended! View closed and local file asset data destroyed.');
    } else {
      setState(() {
        _timeBombRemaining = diff;
      });
    }
  }

  void _writeCloseTrailLog() async {
    if (_loadedGdrmPath == null || _openTimestamp == null) return;
    try {
      final state = context.read<AppState>();
      final deviceKey = await DeviceKeyService.getDeviceKey();
      final currentBytes = await File(_loadedGdrmPath!).readAsBytes();
      final activeSeconds = DateTime.now().difference(_openTimestamp!).inSeconds;
      final details = 'Session closed. Duration: ${activeSeconds}s, ExitPage: $_currentPage (IP: $_deviceIp)';

      final closedBytes = GdrmService.appendTrailLog(
        rawFileBytes: currentBytes,
        action: 'CLOSED',
        deviceKey: deviceKey,
        details: details,
      );
      await GdrmService.writeFile(_loadedGdrmPath!, closedBytes);

      // Record in cloud database snail trail
      if (state.manifest.fingerprint != '---') {
        PiracyService.recordDatabaseSnailTrail(
          fingerprint: state.manifest.fingerprint,
          action: 'CLOSED',
          deviceKey: deviceKey,
          details: details,
          senderUsername: state.manifest.senderUsername,
          activeUsername: state.cloudUsername,
          ipAddress: _deviceIp,
          macAddress: _deviceMac,
        );
      }
    } catch (_) {}
  }

  Future<void> openFileFromPath(String pathOrUri) async {
    try {
      Uint8List bytes;
      if (pathOrUri.startsWith('content://')) {
        bytes = await ContentUriService.readContentUri(pathOrUri);
        await _processBytes(bytes, null);
        return;
      } else if (pathOrUri.startsWith('file://')) {
        final uri = Uri.parse(pathOrUri);
        final filePath = uri.toFilePath();
        bytes = await File(filePath).readAsBytes();
        await _processBytes(bytes, filePath);
      } else {
        bytes = await File(pathOrUri).readAsBytes();
        await _processBytes(bytes, pathOrUri);
      }
    } catch (e) {
      _showError('Failed to open file:\n$e');
    }
  }

  Future<void> _openFilePicker() async {
    if (Platform.isAndroid) {
      final sdk = await _androidSdkInt();
      if (sdk < 33) {
        final s = await Permission.storage.request();
        if (!s.isGranted && mounted) {
          _showError('Storage permission denied.\nGrant it in Settings → Apps → GDRM → Permissions.');
          return;
        }
      }
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Open GDRM File',
      );
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      if (!filePath.toLowerCase().endsWith('.gdrm')) {
        _showError('Invalid file type.\nPlease select a .gdrm file.');
        return;
      }

      final bytes = await File(filePath).readAsBytes();
      await _processBytes(bytes, filePath);
    } catch (e) {
      _showError('Failed to open file:\n$e');
    }
  }

  Future<void> _processBytes(Uint8List bytes, String? filePath) async {
    _writeCloseTrailLog();
    _meltTimer?.cancel();

    final state = context.read<AppState>();
    final initialHeader = String.fromCharCodes(bytes.take(30));
    final deviceKey = await DeviceKeyService.getDeviceKey();

    if (initialHeader.contains('GDRM_RIPPED')) {
      _showError(
          'CRITICAL FAULT: Container Corrupted.\nThis asset has self-destructed due to security configuration parameters.');
      return;
    }
    if (!initialHeader.startsWith('GDRM_V1')) {
      _showError('Invalid file format.\nThis does not appear to be a valid .gdrm file container.');
      return;
    }

    GdrmParseResult parsed;
    try {
      parsed = GdrmService.parse(bytes);
    } catch (e) {
      _showError(e.toString());
      return;
    }

    var meta = parsed.metadata;

    // ── RiggedFile Static Lifespan Check ──
    if (meta.isTimeBombed) {
      final alertReason = 'Lifespan Expired Breach: Attempted opening file past expiration date (${meta.riggedExpiry}).';
      PiracyService.reportPiracyAttempt(
        manifest: meta,
        pirateDeviceKey: deviceKey,
        pirateIp: _deviceIp,
        pirateMac: _deviceMac,
        pirateUsername: state.cloudUsername ?? 'Anonymous Guest',
        fileName: filePath != null ? filePath.split(Platform.pathSeparator).last : 'Document.gdrm',
        reason: alertReason,
      );

      if (filePath != null) {
        final corrupted = GdrmService.deployedTerminalSelfDestruct();
        await GdrmService.writeFile(filePath, corrupted);
      }
      _showError('CRITICAL MELT DETECTED:\nThis file lifespan timeline has ended. Content destroyed permanently.');
      return;
    }

    // ── RiggedFile Static Opening Counters Ceiling Check ──
    if (meta.hasOpenLimit && meta.isOpenCeilingExceeded) {
      final alertReason = 'Opening Limit Breach: Attempted opening file beyond allowed ${meta.maxOpens} views.';
      PiracyService.reportPiracyAttempt(
        manifest: meta,
        pirateDeviceKey: deviceKey,
        pirateIp: _deviceIp,
        pirateMac: _deviceMac,
        pirateUsername: state.cloudUsername ?? 'Anonymous Guest',
        fileName: filePath != null ? filePath.split(Platform.pathSeparator).last : 'Document.gdrm',
        reason: alertReason,
      );

      if (filePath != null) {
        final corrupted = GdrmService.deployedTerminalSelfDestruct();
        await GdrmService.writeFile(filePath, corrupted);
      }
      _showError('CRITICAL LIMIT VIOLATION:\nMaximum allowed viewing count threshold exceeded. Container destroyed.');
      return;
    }

    // ── GDRM Members Only Lock Verification ──
    if (meta.hasMembersOnlyLock && !state.isCloudAuthenticated) {
      final alertReason = 'Unauthenticated Access Attempt: Anonymous guest tried to open container restricted to registered GDRM Ecosystem members.';
      
      var piracyBytes = GdrmService.appendTrailLog(
        rawFileBytes: bytes,
        action: 'MEMBER_AUTH_REQUIRED',
        deviceKey: deviceKey,
        details: '$alertReason (IP: $_deviceIp, MAC: $_deviceMac, OS: ${Platform.operatingSystem})',
      );

      if (filePath != null) {
        try {
          await GdrmService.writeFile(filePath, piracyBytes);
        } catch (_) {}
      }

      PiracyService.recordDatabaseSnailTrail(
        fingerprint: meta.fingerprint,
        action: 'AUTH_REQUIRED',
        deviceKey: deviceKey,
        details: alertReason,
        senderUsername: meta.senderUsername,
        activeUsername: 'Guest / Anonymous',
        ipAddress: _deviceIp,
        macAddress: _deviceMac,
      );

      _showMembersOnlyRequiredDialog();
      return;
    }

    // ── Firebase Recipient Username Lock Verification ──
    if (meta.hasCloudLock) {
      final targetUser = meta.targetUsername.toLowerCase();
      final currentUser = state.cloudUsername?.toLowerCase();

      // If the current user is not the intended recipient, strictly block, log piracy and alert sender
      if (currentUser != targetUser) {
        final alertReason = 'Unauthorized Recipient: User @${state.cloudUsername ?? "Guest"} tried to open file locked for @$targetUser.';
        var piracyBytes = GdrmService.appendTrailLog(
          rawFileBytes: bytes,
          action: 'PIRACY_ALERT',
          deviceKey: deviceKey,
          details: '$alertReason (IP: $_deviceIp, MAC: $_deviceMac, OS: ${Platform.operatingSystem})',
        );

        if (filePath != null) {
          try {
            await GdrmService.writeFile(filePath, piracyBytes);
          } catch (_) {}
        }

        // Report to Firestore and notify sender
        PiracyService.reportPiracyAttempt(
          manifest: meta,
          pirateDeviceKey: deviceKey,
          pirateIp: _deviceIp,
          pirateMac: _deviceMac,
          pirateUsername: state.cloudUsername ?? 'Anonymous Guest',
          fileName: filePath != null ? filePath.split(Platform.pathSeparator).last : 'Document.gdrm',
          reason: alertReason,
        );

        _showUnauthorizedRecipientDialog(meta.targetUsername, state.cloudUsername);
        return;
      }
    }

    // ── FileRip Shield Password Prompt ──
    if (meta.hasPassword) {
      final inputPassword =
          await _promptPasswordDialog(meta.maxAttempts - meta.currentAttempts);
      if (inputPassword == null) return;

      final hashedInput = GdrmService.hashPassword(inputPassword);
      if (hashedInput != meta.passwordHash) {
        var alteredBytes = GdrmService.registerFailedAttempt(bytes, meta);
        final isLastAttempt = (meta.currentAttempts + 1) >= meta.maxAttempts;
        final alertReason = isLastAttempt
            ? 'FileRip Triggered: Password failed ${meta.currentAttempts + 1}/${meta.maxAttempts} times. File container shredded.'
            : 'Failed password attempt: ${meta.currentAttempts + 1}/${meta.maxAttempts}';

        alteredBytes = GdrmService.appendTrailLog(
          rawFileBytes: alteredBytes,
          action: isLastAttempt ? 'FILERIP_TRIGGERED' : 'FAILED_AUTH',
          deviceKey: deviceKey,
          details: '$alertReason (IP: $_deviceIp, MAC: $_deviceMac)',
        );

        if (filePath != null) {
          try {
            await GdrmService.writeFile(filePath, alteredBytes);
          } catch (_) {}
        }

        if (isLastAttempt) {
          PiracyService.reportPiracyAttempt(
            manifest: meta,
            pirateDeviceKey: deviceKey,
            pirateIp: _deviceIp,
            pirateMac: _deviceMac,
            pirateUsername: state.cloudUsername ?? 'Anonymous Guest',
            fileName: filePath != null ? filePath.split(Platform.pathSeparator).last : 'Document.gdrm',
            reason: alertReason,
          );
        }

        // Sync failed auth attempt to database snail trail
        PiracyService.recordDatabaseSnailTrail(
          fingerprint: meta.fingerprint,
          action: isLastAttempt ? 'FILERIP_TRIGGERED' : 'FAILED_AUTH',
          deviceKey: deviceKey,
          details: alertReason,
          senderUsername: meta.senderUsername,
          activeUsername: state.cloudUsername,
          ipAddress: _deviceIp,
          macAddress: _deviceMac,
        );

        _showError('ACCESS DENIED: Invalid password credential.');
        return;
      }
    }

    // ── ChronoLock Check ──
    if (meta.hasChronoLock && meta.isTimeLocked) {
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChronoLockScreen(unlockAtUtc: meta.openAtDateTime!),
          ),
        );
      }
      return;
    }

    final drmResult =
        GdrmService.checkDrm(rawFileBytes: bytes, parsed: parsed, deviceKey: deviceKey);

    switch (drmResult.status) {
      case DrmStatus.piracyDetected:
        final fileNameStr = filePath != null ? filePath.split(Platform.pathSeparator).last : 'Document.gdrm';
        final alertReason = 'Hardware Piracy Breach: Device mismatch detected. Attempted opening file bound to another hardware profile.';
        
        // 1. Record in local .gdrm file snail trail
        final piracyBytes = GdrmService.appendTrailLog(
          rawFileBytes: bytes,
          action: 'PIRACY_ALERT',
          deviceKey: deviceKey,
          details: '$alertReason (IP: $_deviceIp, MAC: $_deviceMac, User: ${state.cloudUsername ?? "Anonymous"}, OS: ${Platform.operatingSystem})',
        );
        if (filePath != null) {
          try {
            await GdrmService.writeFile(filePath, piracyBytes);
          } catch (_) {}
        }

        // 2. Report to Firestore database and notify sender in real-time
        PiracyService.reportPiracyAttempt(
          manifest: meta,
          pirateDeviceKey: deviceKey,
          pirateIp: _deviceIp,
          pirateMac: _deviceMac,
          pirateUsername: state.cloudUsername ?? 'Anonymous / Unknown',
          fileName: fileNameStr,
          reason: alertReason,
        );

        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PiracyScreen()),
          );
        }
        return;

      case DrmStatus.boundNow:
        var updated = drmResult.updatedBytes!;
        updated = GdrmService.appendTrailLog(
          rawFileBytes: updated,
          action: 'DEVICE_BOUND',
          deviceKey: deviceKey,
          details: 'Container locked cleanly to host hardware mapping (IP: $_deviceIp, MAC: $_deviceMac).',
        );
        if (filePath != null) {
          try {
            await GdrmService.writeFile(filePath, updated);
          } catch (_) {}
        }
        parsed = GdrmService.parseFromList(updated);
        
        // Record in cloud database snail trail
        PiracyService.recordDatabaseSnailTrail(
          fingerprint: meta.fingerprint,
          action: 'DEVICE_BOUND',
          deviceKey: deviceKey,
          details: 'Container locked cleanly to host hardware (User: @${state.cloudUsername ?? "Guest"})',
          senderUsername: meta.senderUsername,
          activeUsername: state.cloudUsername,
          ipAddress: _deviceIp,
          macAddress: _deviceMac,
        );

        _showBindSnackbar();
        break;

      default:
        break;
    }

    // ── Log Stamps, Open Counter Write, and Live Countdown Provisioning ──
    var finalWriteBytes = bytes;
    if (filePath != null) {
      try {
        finalWriteBytes = await File(filePath).readAsBytes();
      } catch (_) {}
    }

    if (meta.hasOpenLimit) {
      finalWriteBytes =
          GdrmService.incrementOpeningCounter(finalWriteBytes, meta.currentOpens);
    }

    final openDetails = meta.hasOpenLimit
        ? 'Access verified. View: ${meta.currentOpens + 1} / ${meta.maxOpens}'
        : 'Decryption verified (IP: $_deviceIp, MAC: $_deviceMac).';

    finalWriteBytes = GdrmService.appendTrailLog(
      rawFileBytes: finalWriteBytes,
      action: 'OPENED',
      deviceKey: deviceKey,
      details: openDetails,
    );

    if (filePath != null) {
      try {
        await GdrmService.writeFile(filePath, finalWriteBytes);
        _loadedGdrmPath = filePath;
      } catch (_) {}
    }

    // Sync open event to Firestore database snail trail
    PiracyService.recordDatabaseSnailTrail(
      fingerprint: meta.fingerprint,
      action: 'OPENED',
      deviceKey: deviceKey,
      details: openDetails,
      senderUsername: meta.senderUsername,
      activeUsername: state.cloudUsername,
      ipAddress: _deviceIp,
      macAddress: _deviceMac,
    );

    parsed = GdrmService.parse(finalWriteBytes);
    _openTimestamp = DateTime.now();

    if (parsed.metadata.hasTimeBomb && filePath != null) {
      final expiryTime = DateTime.parse(parsed.metadata.riggedExpiry).toUtc();
      _startLiveMeltTimer(expiryTime, filePath);
    }

    if (!mounted) return;
    await state.loadGdrm(parsed);

    setState(() {
      _loadedPdfPath = state.tempPdfPath;
      _currentPage = 1;
      _totalPages = 0;
    });
  }

  Future<void> _handleSecurePrint() async {
    if (_loadedPdfPath == null) return;

    final state = context.read<AppState>();

    // ── Check Physical Print Permission Policy ──
    if (!state.manifest.allowPrint) {
      final activeUser = state.cloudUsername ?? 'Authorized_User';
      final deviceKey = await DeviceKeyService.getDeviceKey();

      // Record unauthorized print attempt in Snail Trail & Firestore
      if (state.manifest.fingerprint != '---') {
        PiracyService.recordDatabaseSnailTrail(
          fingerprint: state.manifest.fingerprint,
          action: 'PRINT_DENIED',
          deviceKey: deviceKey,
          details: 'Physical print request BLOCKED. Author has restricted physical printing for this container.',
          senderUsername: state.manifest.senderUsername,
          activeUsername: activeUser,
          ipAddress: _deviceIp,
          macAddress: _deviceMac,
        );
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.bgGlassPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.redAccent),
          ),
          title: const Row(
            children: [
              Icon(Icons.print_disabled_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Printing Restricted',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'The author has disabled physical printing permission for this document.\n\nHardware print spooling and virtual printer export are prohibited by cryptographic container policy.',
            style: TextStyle(color: AppTheme.fgLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('DISMISS', style: TextStyle(color: AppTheme.colorCyan)),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final activeUser = state.cloudUsername ?? 'Authorized_User';
      final pdfBytes = await File(_loadedPdfPath!).readAsBytes();

      if (!mounted) return;

      await PrintingService.printDocument(
        context: context,
        originalPdfBytes: pdfBytes,
        manifest: state.manifest,
        activeUsername: activeUser,
        ipAddress: _deviceIp,
        macAddress: _deviceMac,
      );
    } catch (e) {
      _showError('Failed to initiate secure print:\n$e');
    }
  }

  Future<String?> _promptPasswordDialog(int attemptsLeft) async {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgGlassPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.colorMagenta),
        ),
        title: const Row(
          children: [
            Icon(Icons.gpp_maybe_rounded, color: AppTheme.colorMagenta),
            SizedBox(width: 10),
            Text(
              'Input Security Token',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.fgLight,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This file container utilizes active FileRip protection.',
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              'WARNING: $attemptsLeft attempts remaining before asset data self-destructs.',
              style: const TextStyle(
                color: AppTheme.colorAmber,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: AppTheme.fgLight, fontSize: 13),
              decoration: const InputDecoration(hintText: 'Secret container keyphrase'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('CANCEL',
                style: TextStyle(color: AppTheme.fgMuted, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: const Text('DECRYPT',
                style: TextStyle(color: AppTheme.colorCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBindSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.bgGlassPanel,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppTheme.colorCyan),
        ),
        content: const Row(
          children: [
            Icon(Icons.lock_rounded, color: AppTheme.colorCyan, size: 16),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'File activated on this device. Sharing it will trigger piracy protection.',
                style: TextStyle(color: AppTheme.fgLight, fontSize: 12),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _closeFile() {
    _timerCancel();
    _writeCloseTrailLog();
    setState(() {
      _loadedPdfPath = null;
      _loadedGdrmPath = null;
      _currentPage = 1;
      _totalPages = 0;
      _openTimestamp = null;
      _timeBombRemaining = Duration.zero;
    });
    context.read<AppState>().unloadGdrm();
  }

  void _showMembersOnlyRequiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.bgGlassSidebar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppTheme.colorCyan, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.groups_rounded, color: AppTheme.colorCyan, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'GDRM MEMBER ACCOUNT REQUIRED',
                style: TextStyle(
                  color: AppTheme.fgLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This document is restricted to authenticated members of the GDRM Ecosystem.',
              style: TextStyle(
                color: AppTheme.colorCyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You must be signed in with a registered GDRM account to decrypt and access this protected container.',
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 11, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.fgMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colorCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.login_rounded, size: 15),
            label: const Text('SIGN IN / REGISTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GlobalAuthScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUnauthorizedRecipientDialog(String targetUsername, String? currentUsername) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.bgGlassSidebar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppTheme.colorAmber, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.gpp_bad_rounded, color: AppTheme.colorAmber, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'UNINTENDED RECEIVER WARNING',
                style: TextStyle(
                  color: AppTheme.fgLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ACCESS BLOCKED: You are not the intended recipient of this .gdrm document.',
              style: TextStyle(
                color: AppTheme.colorAmber,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgGlassPanel,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderGlass),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Intended Recipient: ',
                        style: TextStyle(color: AppTheme.fgMuted, fontSize: 11),
                      ),
                      Text(
                        '@$targetUsername',
                        style: const TextStyle(
                          color: AppTheme.colorCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'Your Current User: ',
                        style: TextStyle(color: AppTheme.fgMuted, fontSize: 11),
                      ),
                      Text(
                        currentUsername != null ? '@$currentUsername' : 'Not Logged In',
                        style: TextStyle(
                          color: currentUsername != null ? Colors.redAccent : AppTheme.fgMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'This document is cryptographically encrypted and locked to the recipient\'s unique username identity. Unauthorized users cannot decrypt or view its contents.',
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 11, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colorCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK, UNDERSTOOD',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgGlassPanel,
        title: const Text('System Status Notice',
            style: TextStyle(color: AppTheme.fgLight, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
            child: Text(msg, style: const TextStyle(color: AppTheme.fgMuted, fontSize: 13))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.colorCyan)),
          ),
        ],
      ),
    );
  }

  Future<int> _androidSdkInt() async {
    try {
      final r = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(r.stdout.toString().trim()) ?? 30;
    } catch (_) {
      return 30;
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    return Column(
      children: [
        _buildToolbar(isWide),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(isWide ? 20 : 10),
            child: _loadedPdfPath == null ? _buildEmptyState() : _buildPdfView(),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isWide) {
    final state = context.watch<AppState>();
    final hasMelt = state.isFileLoaded && state.manifest.hasTimeBomb;

    if (isWide) {
      return Container(
        height: 60,
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgGlassSidebar,
          border: Border.all(color: AppTheme.borderGlass),
          borderRadius: BorderRadius.circular(6),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _toolBtn('Open GDRM File', _openFilePicker,
                  fg: AppTheme.colorCyan, icon: Icons.folder_open_outlined),
              const SizedBox(width: 8),
              _toolBtn('◀', () => _ctrl.previousPage()),
              const SizedBox(width: 4),
              _toolBtn('▶', () => _ctrl.nextPage()),
              const SizedBox(width: 8),
              _toolBtn('Zoom +',
                  () => setState(() => _ctrl.zoomLevel = (_ctrl.zoomLevel * 1.2).clamp(1.0, 6.0))),
              const SizedBox(width: 4),
              _toolBtn('Zoom –',
                  () => setState(() => _ctrl.zoomLevel = (_ctrl.zoomLevel / 1.2).clamp(1.0, 6.0))),
              const SizedBox(width: 4),
              _toolBtn('Reset', () => setState(() => _ctrl.zoomLevel = 1.0)),
              if (_loadedPdfPath != null) ...[
                const SizedBox(width: 8),
                _toolBtn(
                  'Audit Trail',
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SnailTrailScreen(
                          logs: state.manifest.trailLogs,
                          fileFingerprint: state.manifest.fingerprint,
                        ),
                      ),
                    );
                  },
                  fg: AppTheme.colorAmber,
                  icon: Icons.analytics_outlined,
                ),
                const SizedBox(width: 8),
                _toolBtn(
                  state.manifest.allowPrint ? 'Secure Print' : 'Print Prohibited',
                  _handleSecurePrint,
                  fg: state.manifest.allowPrint ? AppTheme.colorCyan : Colors.redAccent.withOpacity(0.8),
                  icon: state.manifest.allowPrint ? Icons.print_rounded : Icons.print_disabled_rounded,
                ),
                const SizedBox(width: 8),
                _toolBtn(
                  'Close File',
                  _closeFile,
                  fg: Colors.redAccent.withOpacity(0.9),
                  icon: Icons.close_rounded,
                ),
              ],
              const SizedBox(width: 16),
              if (hasMelt && _timeBombRemaining > Duration.zero) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_10_rounded, color: Colors.redAccent, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'MELT IN: ${_formatDuration(_timeBombRemaining)}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
              ],
              if (_loadedPdfPath != null) ...[
                _drmBadge(),
                const SizedBox(width: 12),
              ],
              Text(
                _loadedPdfPath == null
                    ? 'No File Loaded'
                    : 'Page $_currentPage / $_totalPages',
                style: const TextStyle(color: AppTheme.fgMuted, fontSize: 12),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      );
    } else {
      return Container(
        color: AppTheme.bgGlassSidebar,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(child: _mobileOpenBtn()),
                  if (_loadedPdfPath != null) ...[
                    const SizedBox(width: 6),
                    _iconBtn(
                      state.manifest.allowPrint ? Icons.print_rounded : Icons.print_disabled_rounded,
                      _handleSecurePrint,
                      tooltip: state.manifest.allowPrint ? 'Secure Print' : 'Printing Prohibited',
                    ),
                    const SizedBox(width: 6),
                    _iconBtn(
                      Icons.close_rounded,
                      _closeFile,
                      tooltip: 'Close File',
                    ),
                  ],
                  const SizedBox(width: 8),
                  if (hasMelt && _timeBombRemaining > Duration.zero) ...[
                    Text(
                      _formatDuration(_timeBombRemaining),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_loadedPdfPath != null) ...[_drmBadge(), const SizedBox(width: 8)],
                  Text(
                    _loadedPdfPath == null ? 'No File' : '$_currentPage / $_totalPages',
                    style: const TextStyle(color: AppTheme.fgMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _iconBtn(Icons.arrow_back_ios_rounded, () => _ctrl.previousPage(),
                      tooltip: 'Previous'),
                  _iconBtn(Icons.arrow_forward_ios_rounded, () => _ctrl.nextPage(),
                      tooltip: 'Next'),
                  _iconBtn(
                      Icons.zoom_in_rounded,
                      () => setState(
                          () => _ctrl.zoomLevel = (_ctrl.zoomLevel * 1.2).clamp(1.0, 6.0)),
                      tooltip: 'Zoom In'),
                  _iconBtn(
                      Icons.zoom_out_rounded,
                      () => setState(
                          () => _ctrl.zoomLevel = (_ctrl.zoomLevel / 1.2).clamp(1.0, 6.0)),
                      tooltip: 'Zoom Out'),
                  _iconBtn(Icons.fit_screen_rounded, () => setState(() => _ctrl.zoomLevel = 1.0),
                      tooltip: 'Reset'),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderGlass),
          ],
        ),
      );
    }
  }

  Widget _drmBadge() {
    final state = context.read<AppState>();
    final isLocked = state.manifest.hasSecurity;
    final hasUserLock = state.manifest.hasCloudLock;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLocked
            ? AppTheme.colorCyan.withOpacity(0.1)
            : AppTheme.borderGlass.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isLocked
              ? AppTheme.colorCyan.withOpacity(0.5)
              : AppTheme.borderGlass,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 11,
            color: isLocked ? AppTheme.colorCyan : AppTheme.fgMuted,
          ),
          const SizedBox(width: 4),
          Text(
            hasUserLock
                ? 'LOCKED TO @${state.manifest.targetUsername.toUpperCase()}'
                : (isLocked ? 'DRM PROTECTED' : 'LEGACY'),
            style: TextStyle(
              color: isLocked ? AppTheme.colorCyan : AppTheme.fgMuted,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileOpenBtn() {
    return GestureDetector(
      onTap: _openFilePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.bgGlassPanel,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.colorCyan.withOpacity(0.6)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, color: AppTheme.colorCyan, size: 16),
            SizedBox(width: 6),
            Text(
              'Open GDRM File',
              style: TextStyle(
                color: AppTheme.colorCyan,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: _loadedPdfPath != null ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.bgGlassPanel,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.borderGlass),
          ),
          child: Icon(
            icon,
            color: _loadedPdfPath != null ? AppTheme.fgLight : AppTheme.borderGlass,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _toolBtn(String label, VoidCallback onTap,
      {Color fg = AppTheme.fgLight, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgGlassPanel,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.borderGlass),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_outlined, size: 56, color: AppTheme.borderGlass),
          SizedBox(height: 14),
          Text('No GDRM File Loaded',
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 15)),
          SizedBox(height: 5),
          Text('Open a .gdrm file container to begin reading',
              style: TextStyle(color: AppTheme.borderGlass, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPdfView() {
    final meta = context.watch<AppState>().manifest;

    // ── Anti-Copy Protection & Watermarked PDF Viewer ──
    return Focus(
      focusNode: _viewerFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        // Intercept and prevent copy / select-all keyboard shortcuts
        final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed;

        if (isCtrlOrCmd) {
          if (event.logicalKey == LogicalKeyboardKey.keyC ||
              event.logicalKey == LogicalKeyboardKey.keyA ||
              event.logicalKey == LogicalKeyboardKey.keyX ||
              event.logicalKey == LogicalKeyboardKey.insert) {
            // Block copying
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: DynamicWatermark(
        licensedTo: meta.licensedTo,
        copyrightOwner: meta.copyrightOwner,
        signature: meta.memeSignature,
        sessionOpenTime: _openTimestamp ?? DateTime.now(),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.shadowDeep,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.shadowDeep,
                blurRadius: 20,
                offset: Offset(5, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SfPdfViewer.file(
              File(_loadedPdfPath!),
              controller: _ctrl,
              // Strictly disable text selection and context menu copying
              enableTextSelection: false,
              canShowTextSelectionMenu: false,
              canShowPaginationDialog: false,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              pageSpacing: 8,
              onDocumentLoaded: (details) {
                setState(() {
                  _totalPages = details.document.pages.count;
                  _currentPage = 1;
                });
              },
              onPageChanged: (details) {
                setState(() => _currentPage = details.newPageNumber);
              },
              onDocumentLoadFailed: (details) => _showError(details.description),
            ),
          ),
        ),
      ),
    );
  }
}