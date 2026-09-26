import 'dart:typed_data';

/// Represents a single audit entry inside a .gdrm container's immutable SnailTrail.
class GdrmTrailLog {
  final String action;
  final String timestamp;
  final String deviceKey;
  final String details;

  const GdrmTrailLog({
    required this.action,
    required this.timestamp,
    required this.deviceKey,
    required this.details,
  });

  @override
  String toString() => '$action|$timestamp|$deviceKey|$details';

  static GdrmTrailLog? parseLine(String line) {
    final parts = line.split('|');
    if (parts.length < 4) return null;
    return GdrmTrailLog(
      action: parts[0],
      timestamp: parts[1],
      deviceKey: parts[2],
      details: parts[3],
    );
  }
}

/// Metadata header structure embedded in a .gdrm container.
class GdrmMetadata {
  final String licensedTo;
  final String copyrightOwner;
  final String fingerprint;
  final String memeSignature;
  final String timestamp;
  final String sender;
  final String receiver;
  final String openAt;

  // Additive Security Extensions
  final String senderUsername;
  final String senderEmail;
  final String senderDisplayName;
  final String senderDeviceKey;
  final String passwordHash;
  final int maxAttempts;
  final int currentAttempts;
  final String targetUsername;
  final String riggedExpiry;
  final int maxOpens;
  final int currentOpens;
  final bool allowPrint;
  final bool membersOnly;
  final List<GdrmTrailLog> trailLogs;

  const GdrmMetadata({
    required this.licensedTo,
    required this.copyrightOwner,
    required this.fingerprint,
    required this.memeSignature,
    required this.timestamp,
    this.sender = '',
    this.receiver = '',
    this.openAt = '',
    this.senderUsername = '',
    this.senderEmail = '',
    this.senderDisplayName = '',
    this.senderDeviceKey = '',
    this.passwordHash = '',
    this.maxAttempts = 0,
    this.currentAttempts = 0,
    this.targetUsername = '',
    this.riggedExpiry = '',
    this.maxOpens = 0,
    this.currentOpens = 0,
    this.allowPrint = true,
    this.membersOnly = false,
    this.trailLogs = const [],
  });

  bool get hasReceiver => receiver.isNotEmpty;
  bool get hasSecurity => sender.isNotEmpty;
  bool get isEncrypted => sender.isNotEmpty;

  bool get hasChronoLock => openAt.isNotEmpty;
  bool get hasPassword => passwordHash.isNotEmpty;
  bool get isRipped => hasPassword && maxAttempts > 0 && currentAttempts >= maxAttempts;
  bool get hasCloudLock => targetUsername.isNotEmpty;
  bool get hasMembersOnlyLock => membersOnly;
  bool get hasTimeBomb => riggedExpiry.isNotEmpty;
  bool get hasOpenLimit => maxOpens > 0;

  bool get isTimeBombed {
    if (!hasTimeBomb) return false;
    final expiry = DateTime.tryParse(riggedExpiry)?.toUtc();
    if (expiry == null) return false;
    return DateTime.now().toUtc().isAfter(expiry);
  }

  bool get isOpenCeilingExceeded => hasOpenLimit && currentOpens >= maxOpens;

  DateTime? get openAtDateTime =>
      openAt.isEmpty ? null : DateTime.tryParse(openAt)?.toUtc();

  bool get isTimeLocked {
    final dt = openAtDateTime;
    if (dt == null) return false;
    return DateTime.now().toUtc().isBefore(dt);
  }

  static const GdrmMetadata empty = GdrmMetadata(
    licensedTo: '---',
    copyrightOwner: '---',
    fingerprint: '---',
    memeSignature: '---',
    timestamp: '---',
  );
}

/// Decrypted payload result after unpacking a .gdrm container.
class GdrmParseResult {
  final GdrmMetadata metadata;
  final Uint8List pdfBytes;

  const GdrmParseResult({required this.metadata, required this.pdfBytes});
}

/// DRM Authorization status for a file on the current device.
enum GdrmDrmStatus {
  legacy,
  boundNow,
  authorised,
  piracyDetected,
  timeLocked,
  expired,
  attemptsExceeded,
  authRequired,
}

/// Result of checking device DRM binding.
class GdrmDrmCheckResult {
  final GdrmDrmStatus status;
  final Uint8List? updatedBytes;
  final String? message;

  const GdrmDrmCheckResult(this.status, {this.updatedBytes, this.message});
}

/// Current user context passed by host application (e.g. Zen-PDF).
class GdrmUserContext {
  final String? userId;
  final String? username;
  final String? email;
  final String? displayName;
  final String? licenseKey;
  final bool isMember;

  const GdrmUserContext({
    this.userId,
    this.username,
    this.email,
    this.displayName,
    this.licenseKey,
    this.isMember = false,
  });
}

/// Granular security and UI policies for the embedded GDRM Viewer.
class GdrmSecurityConfig {
  /// Whether to block screen capture and OS-level screenshots.
  final bool preventScreenCapture;

  /// Whether to render forensic dynamic watermark over pages.
  final bool enableDynamicWatermark;

  /// Whether printing is allowed by default (overridden if metadata strictly disallows).
  final bool allowPrinting;

  /// Custom watermark opacity (0.05 to 0.50).
  final double watermarkOpacity;

  /// Custom legal/system directive text for AI/OCR deterrence.
  final String? customDirective;

  const GdrmSecurityConfig({
    this.preventScreenCapture = true,
    this.enableDynamicWatermark = true,
    this.allowPrinting = false,
    this.watermarkOpacity = 0.18,
    this.customDirective,
  });
}
