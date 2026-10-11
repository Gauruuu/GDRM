import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/gdrm_model.dart';
import '../services/device_key_service.dart';
import '../services/content_uri_service.dart';
import '../services/printing_service.dart';
import '../services/piracy_service.dart';
import '../services/security_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/dynamic_watermark.dart';
import 'piracy_screen.dart';
import 'chrono_lock_screen.dart';
import 'snail_trail_screen.dart';
import 'global_auth_screen.dart';
import 'privacy_policy_screen.dart';
import '../widgets/shared_widgets.dart';

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
  bool _isDragging = false;
  double _basePinchZoom = 1.0;

  DateTime? _openTimestamp;
  Timer? _sessionTimer;
  Duration _activeReadingDuration = Duration.zero;

  // Active document cache for robust close recording on app exit/dispose
  bool _hasRecordedClose = false;
  GdrmMetadata? _cachedManifest;
  String? _cachedCloudUsername;

  // App lifecycle listener to ensure window/app close marks file as closed
  late final AppLifecycleListener _lifecycleListener;

  // ── RiggedFile Live Countdown States ──
  Timer? _meltTimer;
  Duration _timeBombRemaining = Duration.zero;

  // Device network credentials for watermarked printing
  String _deviceIp = 'Local Workstation';
  String _deviceMac = 'Local Device';

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        await writeCloseTrailLog();
        return AppExitResponse.exit;
      },
      onStateChange: (state) {
        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached ||
            state == AppLifecycleState.hidden) {
          writeCloseTrailLog();
        }
      },
    );
    _resolveNetworkInfo();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _timerCancel();
    _sessionTimer?.cancel();
    writeCloseTrailLog();
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

  Future<void> writeCloseTrailLog() async {
    if (_hasRecordedClose) return;
    if (_loadedGdrmPath == null || _openTimestamp == null) return;
    _hasRecordedClose = true;

    try {
      final deviceKey = await DeviceKeyService.getDeviceKey();
      final currentBytes = await File(_loadedGdrmPath!).readAsBytes();
      final closeTimestamp = DateTime.now();
      final activeSeconds = closeTimestamp.difference(_openTimestamp!).inSeconds;
      final openedFormatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(_openTimestamp!);
      final closedFormatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(closeTimestamp);
      final details = 'Session closed. Opened: $openedFormatted, Closed: $closedFormatted (${activeSeconds}s), ExitPage: $_currentPage (IP: $_deviceIp)';

      final closedBytes = GdrmService.appendTrailLog(
        rawFileBytes: currentBytes,
        action: 'CLOSED',
        deviceKey: deviceKey,
        details: details,
      );
      await GdrmService.writeFile(_loadedGdrmPath!, closedBytes);

      // Resolve manifest and username safely from cache or mounted state
      final meta = _cachedManifest ?? (mounted ? context.read<AppState>().manifest : GdrmMetadata.empty);
      final activeUser = _cachedCloudUsername ?? (mounted ? context.read<AppState>().cloudUsername : null);

      // Record in cloud database snail trail with opening and closing timestamps
      if (meta.fingerprint != '---' && meta.fingerprint.isNotEmpty) {
        await PiracyService.recordDatabaseSnailTrail(
          fingerprint: meta.fingerprint,
          action: 'CLOSED',
          deviceKey: deviceKey,
          details: details,
          senderUsername: meta.senderUsername,
          activeUsername: activeUser,
          ipAddress: _deviceIp,
          macAddress: _deviceMac,
          openedAt: _openTimestamp,
          closedAt: closeTimestamp,
        );
      }
    } catch (e) {
      debugPrint('[ReaderConsole] writeCloseTrailLog note: $e');
    }
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
    await writeCloseTrailLog();
    _meltTimer?.cancel();

    if (!mounted) return;
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

    // ── Anti-Forensic USB Debugging / ADB Restriction ──
    if (Platform.isAndroid && await SecurityService.isUsbDebuggingEnabled()) {
      final fileName = filePath != null ? filePath.split(Platform.pathSeparator).last : 'Document.gdrm';
      PiracyService.reportPiracyAttempt(
        manifest: meta,
        pirateDeviceKey: deviceKey,
        pirateIp: _deviceIp,
        pirateMac: _deviceMac,
        pirateUsername: state.cloudUsername ?? 'Anonymous Guest',
        fileName: fileName,
        reason: 'USB Debugging Violation: Android device has active ADB / USB Debugging enabled during container decryption attempt.',
      );
      _showUsbDebuggingDialog();
      return;
    }

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

    // If a document was already open, ensure its close event is recorded first
    if (_loadedGdrmPath != null && !_hasRecordedClose) {
      await writeCloseTrailLog();
    }

    final openTime = DateTime.now();
    _openTimestamp = openTime;
    _hasRecordedClose = false;
    _cachedManifest = meta;
    _cachedCloudUsername = state.cloudUsername;
    final openedFormatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(openTime);
    final openDetails = meta.hasOpenLimit
        ? 'Access verified at $openedFormatted. View: ${meta.currentOpens + 1} / ${meta.maxOpens}'
        : 'Decryption verified at $openedFormatted (IP: $_deviceIp, MAC: $_deviceMac).';

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

    // Sync open event with precise opening timestamp to Firestore database snail trail
    PiracyService.recordDatabaseSnailTrail(
      fingerprint: meta.fingerprint,
      action: 'OPENED',
      deviceKey: deviceKey,
      details: openDetails,
      senderUsername: meta.senderUsername,
      activeUsername: state.cloudUsername,
      ipAddress: _deviceIp,
      macAddress: _deviceMac,
      openedAt: openTime,
    );

    parsed = GdrmService.parse(finalWriteBytes);
    _activeReadingDuration = Duration.zero;
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _openTimestamp != null) {
        setState(() {
          _activeReadingDuration = DateTime.now().difference(_openTimestamp!);
        });
      }
    });

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

  void _closeFile() async {
    _timerCancel();
    _sessionTimer?.cancel();
    await writeCloseTrailLog();
    final openTimeStr = _openTimestamp != null ? DateFormat('HH:mm:ss').format(_openTimestamp!) : '--';
    final closeTimeStr = DateFormat('HH:mm:ss').format(DateTime.now());
    final durationStr = _formatDuration(_activeReadingDuration);

    if (mounted) {
      final state = context.read<AppState>();
      state.clearLoadedFile();
    }

    setState(() {
      _loadedPdfPath = null;
      _loadedGdrmPath = null;
      _currentPage = 1;
      _totalPages = 0;
      _activeReadingDuration = Duration.zero;
      _openTimestamp = null;
      _cachedManifest = null;
      _cachedCloudUsername = null;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.bgGlassPanel,
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.colorCyan, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'File Closed • Session: $durationStr (Open: $openTimeStr, Closed: $closeTimeStr)',
                style: TextStyle(color: AppTheme.fgLight, fontSize: 12),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
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
          content: Text(
            'The author has disabled physical printing permission for this document.\n\nHardware print spooling and virtual printer export are prohibited by cryptographic container policy.',
            style: TextStyle(color: AppTheme.fgLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('DISMISS', style: TextStyle(color: AppTheme.colorCyan)),
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
          side: BorderSide(color: AppTheme.colorMagenta),
        ),
        title: Row(
          children: [
            Icon(Icons.gpp_maybe_rounded, color: AppTheme.colorMagenta),
            const SizedBox(width: 10),
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
            Text(
              'This file container utilizes active FileRip protection.',
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              'WARNING: $attemptsLeft attempts remaining before asset data self-destructs.',
              style: TextStyle(
                color: AppTheme.colorAmber,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: TextStyle(color: AppTheme.fgLight, fontSize: 13),
              decoration: const InputDecoration(hintText: 'Secret container keyphrase'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('CANCEL',
                style: TextStyle(color: AppTheme.fgMuted, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: Text('DECRYPT',
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
          side: BorderSide(color: AppTheme.colorCyan),
        ),
        content: Row(
          children: [
            Icon(Icons.lock_rounded, color: AppTheme.colorCyan, size: 16),
            const SizedBox(width: 10),
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

  void _showMembersOnlyRequiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.bgGlassSidebar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppTheme.colorCyan, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.groups_rounded, color: AppTheme.colorCyan, size: 24),
            const SizedBox(width: 10),
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
        content: Column(
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
            const SizedBox(height: 12),
            Text(
              'You must be signed in with a registered GDRM account to decrypt and access this protected container.',
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 11, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('CANCEL', style: TextStyle(color: AppTheme.fgMuted, fontWeight: FontWeight.bold)),
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
          side: BorderSide(color: AppTheme.colorAmber, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.gpp_bad_rounded, color: AppTheme.colorAmber, size: 24),
            const SizedBox(width: 10),
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
            Text(
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
                      Text(
                        'Intended Recipient: ',
                        style: TextStyle(color: AppTheme.fgMuted, fontSize: 11),
                      ),
                      Text(
                        '@$targetUsername',
                        style: TextStyle(
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
                      Text(
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
            Text(
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
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgGlassPanel,
        title: Text('System Status Notice',
            style: TextStyle(color: AppTheme.fgLight, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
            child: Text(msg, style: TextStyle(color: AppTheme.fgMuted, fontSize: 13))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('OK', style: TextStyle(color: AppTheme.colorCyan)),
          ),
        ],
      ),
    );
  }

  void _showUsbDebuggingDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgGlassPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.usb_off_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'USB DEBUGGING DETECTED',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GDRM security policy strictly prohibits opening or decrypting protected containers while USB Debugging (ADB) is enabled on this device.',
              style: TextStyle(color: AppTheme.fgLight, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please disable USB Debugging in Android Developer Options to unlock secure document viewing.',
                      style: TextStyle(color: AppTheme.fgLight, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('DISMISS', style: TextStyle(color: AppTheme.fgMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colorCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            icon: const Icon(Icons.settings_rounded, size: 14),
            onPressed: () {
              Navigator.pop(dialogCtx);
              SecurityService.openDeveloperSettings();
            },
            label: const Text('DEVELOPER SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          final firstFile = details.files.first;
          final path = firstFile.path;
          if (path.toLowerCase().endsWith('.gdrm')) {
            await openFileFromPath(path);
          } else {
            _showError('Invalid file type dropped.\nPlease drop an encrypted .gdrm container file.');
          }
        }
      },
      child: Stack(
        children: [
          Column(
            children: [
              _buildToolbar(isWide),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(isWide ? 20 : 10),
                        child: _loadedPdfPath == null ? _buildEmptyState() : _buildPdfView(),
                      ),
                    ),
                    if (isWide) _buildFileDetailsPanel(),
                  ],
                ),
              ),
            ],
          ),
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: AppTheme.bgMain.withValues(alpha: 0.88),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                    decoration: BoxDecoration(
                      color: AppTheme.bgGlassPanel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryGreen, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_download_outlined, color: AppTheme.primaryGreen, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          'DROP .GDRM CONTAINER HERE',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Release to decrypt and open document securely',
                          style: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isWide) {
    final state = context.watch<AppState>();
    final hasMelt = state.isFileLoaded && state.manifest.hasTimeBomb;

    if (isWide) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.bgGlassSidebar,
          border: Border(bottom: BorderSide(color: AppTheme.borderGlass)),
        ),
        child: Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: _openFilePicker,
              child: const Text('Open file', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            _secondaryToolBtn('←', () => _ctrl.previousPage()),
            const SizedBox(width: 4),
            _secondaryToolBtn('→', () => _ctrl.nextPage()),
            const Spacer(),
            if (hasMelt && _timeBombRemaining > Duration.zero) ...[
              Text(
                'MELT IN: ${_formatDuration(_timeBombRemaining)}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ] else ...[
              Text(
                _loadedPdfPath == null
                    ? 'No file loaded'
                    : 'Page $_currentPage of $_totalPages',
                style: TextStyle(color: AppTheme.fgMuted, fontSize: 13),
              ),
            ],
          ],
        ),
      );
    } else {
      return Container(
        color: AppTheme.bgGlassSidebar,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Row(
                children: [
                  if (_loadedPdfPath == null)
                    Expanded(child: _mobileOpenBtn())
                  else ...[
                    _iconBtn(
                      Icons.folder_open_outlined,
                      _openFilePicker,
                      tooltip: 'Open Another File',
                    ),
                    const SizedBox(width: 8),
                    _drmBadge(isCompact: true),
                    const SizedBox(width: 8),
                    if (hasMelt && _timeBombRemaining > Duration.zero) ...[
                      Text(
                        _formatDuration(_timeBombRemaining),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    _iconBtn(
                      Icons.shield_outlined,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                        );
                      },
                      tooltip: 'Privacy & Legal Terms',
                    ),
                    const SizedBox(width: 6),
                    _iconBtn(
                      Icons.close_rounded,
                      _closeFile,
                      tooltip: 'Close File',
                    ),
                  ],
                ],
              ),
            ),
            if (_loadedPdfPath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconBtn(Icons.arrow_back_ios_rounded, () => _ctrl.previousPage(),
                        tooltip: 'Previous'),
                    const SizedBox(width: 16),
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: TextStyle(
                        color: AppTheme.fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _iconBtn(Icons.arrow_forward_ios_rounded, () => _ctrl.nextPage(),
                        tooltip: 'Next'),
                  ],
                ),
              ),
            Divider(height: 1, color: AppTheme.borderGlass),
          ],
        ),
      );
    }
  }

  Widget _drmBadge({bool isCompact = false}) {
    final state = context.read<AppState>();
    final isLocked = state.manifest.hasSecurity;
    final hasUserLock = state.manifest.hasCloudLock;

    String labelText;
    if (isCompact) {
      labelText = hasUserLock
          ? '@${state.manifest.targetUsername.toUpperCase()}'
          : (isLocked ? 'DRM' : 'LEGACY');
    } else {
      labelText = hasUserLock
          ? 'LOCKED TO @${state.manifest.targetUsername.toUpperCase()}'
          : (isLocked ? 'DRM PROTECTED' : 'LEGACY');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLocked
            ? AppTheme.colorCyan.withValues(alpha: 0.1)
            : AppTheme.borderGlass.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isLocked
              ? AppTheme.colorCyan.withValues(alpha: 0.5)
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
            labelText,
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
          border: Border.all(color: AppTheme.colorCyan.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, color: AppTheme.colorCyan, size: 16),
            const SizedBox(width: 6),
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



  Widget _secondaryToolBtn(String label, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppTheme.secondaryBtnBg,
        foregroundColor: AppTheme.fgLight,
        side: BorderSide(color: AppTheme.secondaryBtnBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 620),
        child: DashedContainer(
          borderRadius: BorderRadius.circular(10),
          color: AppTheme.borderGlass,
          strokeWidth: 1.5,
          dash: 6,
          gap: 6,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.folder_open_rounded, size: 28, color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 18),
                Text(
                  'Open a .gdrm file',
                  style: TextStyle(
                    color: AppTheme.fgLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Drag and drop your file here, or click below to browse',
                  style: TextStyle(
                    color: AppTheme.fgMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.file_open_rounded, size: 16),
                  label: const Text(
                    'Open file',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _openFilePicker,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileDetailsPanel() {
    final state = context.watch<AppState>();
    final meta = state.manifest;
    final isLoaded = _loadedPdfPath != null;

    String lockText = 'Unbound';
    Color lockColor = AppTheme.colorAmber;
    if (isLoaded) {
      if (meta.hasCloudLock && meta.targetUsername.isNotEmpty) {
        lockText = '@${meta.targetUsername}';
        lockColor = AppTheme.isDark ? AppTheme.darkPrimaryGreen : AppTheme.lightPrimaryGreen;
      } else if (meta.hasMembersOnlyLock) {
        lockText = 'Members only';
        lockColor = AppTheme.isDark ? AppTheme.darkPrimaryGreen : AppTheme.lightPrimaryGreen;
      } else if (meta.receiver.isNotEmpty) {
        lockText = 'Bound';
        lockColor = AppTheme.isDark ? AppTheme.darkPrimaryGreen : AppTheme.lightPrimaryGreen;
      }
    }

    final printText = isLoaded ? (meta.allowPrint ? 'Permitted' : 'Prohibited') : 'Permitted';
    final printColor = (isLoaded && !meta.allowPrint)
        ? Colors.redAccent
        : (AppTheme.isDark ? AppTheme.darkPrimaryGreen : AppTheme.lightPrimaryGreen);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppTheme.bgGlassSidebar,
        border: Border(left: BorderSide(color: AppTheme.borderGlass)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILE DETAILS',
            style: TextStyle(
              color: AppTheme.fgMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          _detailKeyVal('Licensed to', isLoaded && meta.licensedTo.isNotEmpty ? meta.licensedTo : '—'),
          _detailKeyVal('Copyright owner', isLoaded && meta.copyrightOwner.isNotEmpty ? meta.copyrightOwner : '—'),
          _detailKeyVal(
            'Fingerprint',
            isLoaded && meta.fingerprint != '---'
                ? (meta.fingerprint.length > 12 ? '${meta.fingerprint.substring(0, 12)}...' : meta.fingerprint)
                : '—',
            isMono: true,
          ),
          _detailKeyVal('Signature', isLoaded && meta.memeSignature.isNotEmpty ? meta.memeSignature : '—'),
          _detailKeyVal('Receiver lock', lockText, valueColor: lockColor),
          if (!Platform.isAndroid && !Platform.isIOS)
            _detailKeyVal('Printing', printText, valueColor: printColor),
          _detailKeyVal('Opened at', isLoaded && _openTimestamp != null ? DateFormat('HH:mm:ss').format(_openTimestamp!) : '—'),
          _detailKeyVal('Session', isLoaded ? _formatDuration(_activeReadingDuration) : '—'),
          _detailKeyVal('Cloud audit', isLoaded ? 'Synced' : '—', valueColor: AppTheme.isDark ? AppTheme.darkPrimaryGreen : AppTheme.lightPrimaryGreen),

          if (isLoaded) ...[
            const SizedBox(height: 16),
            Divider(color: AppTheme.borderGlass),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppTheme.secondaryBtnBg,
                foregroundColor: AppTheme.fgLight,
                side: BorderSide(color: AppTheme.secondaryBtnBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                minimumSize: const Size(double.infinity, 36),
              ),
              icon: const Icon(Icons.analytics_outlined, size: 14),
              label: const Text('Audit trail', style: TextStyle(fontSize: 12)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SnailTrailScreen(
                      logs: meta.trailLogs,
                      fileFingerprint: meta.fingerprint,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            if (meta.allowPrint && !Platform.isAndroid && !Platform.isIOS) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryBtnBg,
                  foregroundColor: AppTheme.fgLight,
                  side: BorderSide(color: AppTheme.secondaryBtnBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  minimumSize: const Size(double.infinity, 36),
                ),
                icon: const Icon(Icons.print_rounded, size: 14),
                label: const Text('Secure print', style: TextStyle(fontSize: 12)),
                onPressed: _handleSecurePrint,
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppTheme.secondaryBtnBg,
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                minimumSize: const Size(double.infinity, 36),
              ),
              icon: const Icon(Icons.close_rounded, size: 14),
              label: const Text('Close file', style: TextStyle(fontSize: 12)),
              onPressed: _closeFile,
            ),
          ],

          const Spacer(),

          // Privacy & legal terms link
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Privacy & legal terms',
                style: TextStyle(
                  color: AppTheme.fgMuted,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailKeyVal(String key, String val, {Color? valueColor, bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: TextStyle(
              color: AppTheme.fgMuted,
              fontSize: 12.5,
            ),
          ),
          Flexible(
            child: Text(
              val,
              style: TextStyle(
                color: valueColor ?? AppTheme.fgLight,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                fontFamily: isMono ? 'monospace' : null,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
        fingerprint: meta.fingerprint,
        sessionOpenTime: _openTimestamp ?? DateTime.now(),
        userId: context.watch<AppState>().cloudUsername?.isNotEmpty == true
            ? '@${context.watch<AppState>().cloudUsername}'
            : (meta.targetUsername.isNotEmpty ? '@${meta.targetUsername}' : null),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.shadowDeep,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDeep,
                blurRadius: 20,
                offset: const Offset(5, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Listener(
              onPointerPanZoomStart: (event) {
                _basePinchZoom = _ctrl.zoomLevel;
              },
              onPointerPanZoomUpdate: (event) {
                if (event.scale != 1.0) {
                  setState(() {
                    _ctrl.zoomLevel = (_basePinchZoom * event.scale).clamp(0.5, 10.0);
                  });
                }
              },
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  // Trackpad pinch or Ctrl + Mouse Wheel zoom
                  if (HardwareKeyboard.instance.isControlPressed) {
                    if (pointerSignal.scrollDelta.dy < 0) {
                      setState(() {
                        _ctrl.zoomLevel = (_ctrl.zoomLevel * 1.15).clamp(0.5, 10.0);
                      });
                    } else if (pointerSignal.scrollDelta.dy > 0) {
                      setState(() {
                        _ctrl.zoomLevel = (_ctrl.zoomLevel / 1.15).clamp(0.5, 10.0);
                      });
                    }
                  }
                }
              },
              child: GestureDetector(
                onScaleStart: (details) {
                  _basePinchZoom = _ctrl.zoomLevel;
                },
                onScaleUpdate: (details) {
                  if (details.scale != 1.0) {
                    setState(() {
                      _ctrl.zoomLevel = (_basePinchZoom * details.scale).clamp(0.5, 10.0);
                    });
                  }
                },
                child: SfPdfViewer.file(
                  File(_loadedPdfPath!),
                  controller: _ctrl,
                  // Strictly disable text selection and context menu copying
                  enableTextSelection: false,
                  canShowTextSelectionMenu: false,
                  canShowPaginationDialog: true,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  scrollDirection: PdfScrollDirection.vertical,
                  pageSpacing: 8,
                  maxZoomLevel: 10.0,
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
        ),
      ),
    );
  }
}