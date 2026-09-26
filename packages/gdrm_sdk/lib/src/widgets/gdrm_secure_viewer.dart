import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../core/gdrm_engine.dart';
import '../models/gdrm_models.dart';
import '../services/gdrm_device_service.dart';
import 'gdrm_watermark.dart';

/// Turnkey secure viewer widget for GDRM-protected documents and standard PDFs.
///
/// Features:
/// - In-memory RAM decryption (no decrypted PDF bytes ever saved to disk).
/// - Hardware-locked device verification.
/// - Dynamic forensic watermark overlay.
/// - Anti-screenshot & screen capture protection via [ScreenSecurity].
/// - Audit logging to container's SnailTrail.
class GdrmSecureViewer extends StatefulWidget {
  /// File path on disk, or provide [rawBytes].
  final String? filePath;

  /// In-memory raw bytes (if file is loaded from network or memory buffer).
  final Uint8List? rawBytes;

  /// User context for authentication & watermark attribution.
  final GdrmUserContext userContext;

  /// Security configuration & UI policies.
  final GdrmSecurityConfig securityConfig;

  /// Custom controller for PDF viewer.
  final PdfViewerController? controller;

  /// Callback when access is denied due to DRM policies.
  final void Function(GdrmDrmStatus status, String message)? onAccessDenied;

  /// Callback when document is successfully unlocked and rendered.
  final void Function(GdrmMetadata metadata)? onDocumentLoaded;

  /// Custom error builder if DRM validation fails.
  final Widget Function(BuildContext context, GdrmDrmStatus status, String error)? errorBuilder;

  /// Password provider callback if document requires password unlock.
  final Future<String?> Function(BuildContext context, GdrmMetadata metadata)? onPasswordRequired;

  const GdrmSecureViewer({
    super.key,
    this.filePath,
    this.rawBytes,
    this.userContext = const GdrmUserContext(),
    this.securityConfig = const GdrmSecurityConfig(),
    this.controller,
    this.onAccessDenied,
    this.onDocumentLoaded,
    this.errorBuilder,
    this.onPasswordRequired,
  }) : assert(filePath != null || rawBytes != null, 'Either filePath or rawBytes must be provided.');

  @override
  State<GdrmSecureViewer> createState() => _GdrmSecureViewerState();
}

class _GdrmSecureViewerState extends State<GdrmSecureViewer> {
  bool _isLoading = true;
  String? _errorMessage;
  GdrmDrmStatus? _failureStatus;
  Uint8List? _decryptedPdfBytes;
  GdrmMetadata? _metadata;
  late final DateTime _sessionOpenTime;
  late final PdfViewerController _pdfController;

  @override
  void initState() {
    super.initState();
    _sessionOpenTime = DateTime.now();
    _pdfController = widget.controller ?? PdfViewerController();
    _initSecurity();
    _loadDocument();
  }

  @override
  void dispose() {
    if (widget.securityConfig.preventScreenCapture) {
      _disableScreenSecurity();
    }
    super.dispose();
  }

  Future<void> _initSecurity() async {
    if (widget.securityConfig.preventScreenCapture) {
      try {
        if (Platform.isWindows) {
          const channel = MethodChannel('com.gdrm.ecosystem/security');
          await channel.invokeMethod('setSecureWindow');
        }
      } catch (_) {}
    }
  }

  Future<void> _disableScreenSecurity() async {
    // Teardown screen protection hooks on dispose
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _failureStatus = null;
    });

    try {
      Uint8List fileBytes;
      if (widget.rawBytes != null) {
        fileBytes = widget.rawBytes!;
      } else {
        final file = File(widget.filePath!);
        if (!await file.exists()) {
          _fail(GdrmDrmStatus.legacy, 'File not found: ${widget.filePath}');
          return;
        }
        fileBytes = await file.readAsBytes();
      }

      // Check if file is a GDRM container
      if (!GdrmEngine.isGdrmFile(fileBytes)) {
        // Standard PDF mode
        setState(() {
          _decryptedPdfBytes = fileBytes;
          _metadata = null;
          _isLoading = false;
        });
        return;
      }

      // Parse GDRM container
      final parsed = GdrmEngine.parse(fileBytes);
      final meta = parsed.metadata;
      final deviceKey = GdrmDeviceService.getActiveDeviceKey();

      // 1. Check Attempts & Ripped state
      if (meta.isRipped) {
        _fail(GdrmDrmStatus.attemptsExceeded, 'Document container has permanently self-destructed.');
        return;
      }

      // 2. Check Expiry Time-Bomb
      if (meta.isTimeBombed) {
        _fail(GdrmDrmStatus.expired, 'Document access has expired on ${meta.riggedExpiry}.');
        return;
      }

      // 3. Check Chrono Lock (OpenAt)
      if (meta.isTimeLocked) {
        _fail(GdrmDrmStatus.timeLocked, 'Document is locked until ${meta.openAt}.');
        return;
      }

      // 4. Check Open Limit
      if (meta.isOpenCeilingExceeded) {
        _fail(GdrmDrmStatus.expired, 'Document has reached maximum allowed opening limit (${meta.maxOpens}).');
        return;
      }

      // 5. Check Target User Lock
      if (meta.hasCloudLock && widget.userContext.username != null) {
        if (widget.userContext.username!.toLowerCase() != meta.targetUsername.toLowerCase()) {
          _fail(GdrmDrmStatus.authRequired, 'This document is exclusively restricted to user: @${meta.targetUsername}');
          return;
        }
      }

      // 6. Check Members Only Lock
      if (meta.hasMembersOnlyLock && !widget.userContext.isMember) {
        _fail(GdrmDrmStatus.authRequired, 'This document is restricted to authenticated tier members.');
        return;
      }

      // 7. Verify Hardware Device Binding
      final drmResult = GdrmEngine.verifyDeviceBinding(
        rawFileBytes: fileBytes,
        parsed: parsed,
        deviceKey: deviceKey,
      );

      if (drmResult.status == GdrmDrmStatus.piracyDetected) {
        _fail(GdrmDrmStatus.piracyDetected, 'Piracy Alert: Document is locked to another authorized machine.');
        return;
      }

      // Auto-bind or update container if needed
      var currentBytes = fileBytes;
      if (drmResult.status == GdrmDrmStatus.boundNow && drmResult.updatedBytes != null) {
        currentBytes = drmResult.updatedBytes!;
        if (widget.filePath != null) {
          await GdrmEngine.saveFile(widget.filePath!, currentBytes);
        }
      }

      // 8. Handle Password Lock
      if (meta.hasPassword) {
        String? enteredPassword;
        if (widget.onPasswordRequired != null) {
          enteredPassword = await widget.onPasswordRequired!(context, meta);
        }

        final hashedEntered = enteredPassword != null ? GdrmDeviceService.hashPassword(enteredPassword) : '';
        if (hashedEntered != meta.passwordHash) {
          final updatedFailed = GdrmEngine.registerFailedAttempt(currentBytes, meta);
          if (widget.filePath != null) {
            await GdrmEngine.saveFile(widget.filePath!, updatedFailed);
          }
          _fail(GdrmDrmStatus.authRequired, 'Invalid document password. Attempts logged.');
          return;
        }
      }

      // 9. Increment Open Counter & Log Trail
      if (meta.hasOpenLimit) {
        currentBytes = GdrmEngine.incrementOpeningCounter(currentBytes, meta.currentOpens);
      }
      currentBytes = GdrmEngine.appendTrailLog(
        rawFileBytes: currentBytes,
        action: 'SDK_OPEN',
        deviceKey: deviceKey,
        details: 'Opened in secure viewer by ${widget.userContext.username ?? "Anonymous User"}',
      );
      if (widget.filePath != null) {
        await GdrmEngine.saveFile(widget.filePath!, currentBytes);
      }

      // Successfully unlocked
      setState(() {
        _decryptedPdfBytes = parsed.pdfBytes;
        _metadata = meta;
        _isLoading = false;
      });

      widget.onDocumentLoaded?.call(meta);
    } catch (e) {
      _fail(GdrmDrmStatus.legacy, 'Failed to open document: $e');
    }
  }

  void _fail(GdrmDrmStatus status, String message) {
    setState(() {
      _failureStatus = status;
      _errorMessage = message;
      _isLoading = false;
    });
    widget.onAccessDenied?.call(status, message);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.redAccent),
            SizedBox(height: 16),
            Text(
              'Decrypting GDRM Container & Verifying Hardware...',
              style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _failureStatus != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _failureStatus ?? GdrmDrmStatus.legacy, _errorMessage ?? 'Access Denied');
      }
      return _buildDefaultErrorUI();
    }

    Widget viewer = SfPdfViewer.memory(
      _decryptedPdfBytes!,
      controller: _pdfController,
      canShowScrollHead: true,
      canShowScrollStatus: true,
    );

    if (widget.securityConfig.enableDynamicWatermark && _metadata != null) {
      viewer = GdrmDynamicWatermark(
        licensedTo: _metadata!.licensedTo.isNotEmpty ? _metadata!.licensedTo : (widget.userContext.displayName ?? 'Authenticated User'),
        copyrightOwner: _metadata!.copyrightOwner.isNotEmpty ? _metadata!.copyrightOwner : 'GDRM Protected',
        signature: _metadata!.memeSignature.isNotEmpty ? _metadata!.memeSignature : _metadata!.fingerprint,
        sessionOpenTime: _sessionOpenTime,
        opacity: widget.securityConfig.watermarkOpacity,
        customDirective: widget.securityConfig.customDirective,
        child: viewer,
      );
    }

    return viewer;
  }

  Widget _buildDefaultErrorUI() {
    final isPiracy = _failureStatus == GdrmDrmStatus.piracyDetected;
    return Container(
      color: const Color(0xFF0F0F12),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1C22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isPiracy ? Colors.redAccent : Colors.orangeAccent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: (isPiracy ? Colors.redAccent : Colors.orangeAccent).withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPiracy ? Icons.gavel_rounded : Icons.lock_clock_rounded,
                color: isPiracy ? Colors.redAccent : Colors.orangeAccent,
                size: 52,
              ),
              const SizedBox(height: 18),
              Text(
                isPiracy ? 'SECURITY POLICY VIOLATION' : 'GDRM ACCESS RESTRICTED',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'You do not have permission to view this protected document on this machine.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadDocument,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('RETRY VALIDATION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPiracy ? Colors.redAccent : Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
