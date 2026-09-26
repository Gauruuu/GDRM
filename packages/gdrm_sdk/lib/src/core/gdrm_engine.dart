import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import '../models/gdrm_models.dart';
import '../services/gdrm_device_service.dart';

/// Core cryptographic and file container engine for .GDRM packages.
class GdrmEngine {
  static const String marker = '===PDFDATA===\n';
  static const String headerPrefix = 'GDRM_V1';

  /// Generates a human-readable unique document fingerprint (e.g. GDRM-A7B2-9F01-C34E)
  static String generateFingerprint() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    String seg() => List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'GDRM-${seg()}-${seg()}-${seg()}';
  }

  /// Checks if given bytes or file header represents a valid .gdrm container
  static bool isGdrmFile(Uint8List bytes) {
    if (bytes.length < 10) return false;
    final prefix = String.fromCharCodes(bytes.take(15));
    return prefix.startsWith(headerPrefix) || prefix.startsWith('GDRM_RIPPED');
  }

  static String _generateSenderToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Uint8List _deriveXorKey(String senderToken) {
    final key = <int>[];
    var current = sha256.convert(utf8.encode('GDRM_PDF_ENCRYPT_v1:$senderToken')).bytes;
    while (key.length < 512) {
      key.addAll(current);
      current = sha256.convert(current).bytes;
    }
    return Uint8List.fromList(key.sublist(0, 512));
  }

  static Uint8List _xorPdf(Uint8List pdfBytes, String senderToken) {
    final key = _deriveXorKey(senderToken);
    final result = Uint8List(pdfBytes.length);
    for (int i = 0; i < pdfBytes.length; i++) {
      result[i] = pdfBytes[i] ^ key[i % key.length];
    }
    return result;
  }

  /// Encrypts raw PDF bytes into a proprietary .gdrm container with policy directives.
  static Uint8List pack({
    required Uint8List pdfBytes,
    required String licensedTo,
    required String copyrightOwner,
    required String memeSignature,
    DateTime? openAt,
    String senderUsername = '',
    String senderEmail = '',
    String senderDisplayName = '',
    String senderDeviceKey = '',
    String password = '',
    int maxAttempts = 0,
    String targetUsername = '',
    DateTime? riggedExpiry,
    int maxOpens = 0,
    bool allowPrint = true,
    bool membersOnly = false,
  }) {
    final fingerprint = generateFingerprint();
    final sender = _generateSenderToken();
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).toStringAsFixed(6);
    final openAtStr = openAt != null ? openAt.toUtc().toIso8601String() : '';
    final passwordHash = password.isNotEmpty ? GdrmDeviceService.hashPassword(password) : '';
    final riggedExpiryStr = riggedExpiry != null ? riggedExpiry.toUtc().toIso8601String() : '';

    final encryptedPdf = _xorPdf(pdfBytes, sender);
    final initialLog = 'PACKED|$timestamp|${senderDeviceKey.isNotEmpty ? senderDeviceKey : 'ORIGIN_HOST'}|Authored by ${senderUsername.isNotEmpty ? "@$senderUsername" : copyrightOwner}\n';

    final header = 'GDRM_V1\n'
        'LICENSED_TO=$licensedTo\n'
        'COPYRIGHT_OWNER=$copyrightOwner\n'
        'FINGERPRINT=$fingerprint\n'
        'MEME_SIGNATURE=$memeSignature\n'
        'TIMESTAMP=$timestamp\n'
        'SENDER=$sender\n'
        'SENDER_USERNAME=$senderUsername\n'
        'SENDER_EMAIL=$senderEmail\n'
        'SENDER_NAME=$senderDisplayName\n'
        'SENDER_DEVICE_KEY=$senderDeviceKey\n'
        'RECEIVER=\n'
        'OPEN_AT=$openAtStr\n'
        'PASSWORD_HASH=$passwordHash\n'
        'MAX_ATTEMPTS=$maxAttempts\n'
        'CURRENT_ATTEMPTS=0\n'
        'TARGET_USERNAME=$targetUsername\n'
        'RIGGED_EXPIRY=$riggedExpiryStr\n'
        'MAX_OPENS=$maxOpens\n'
        'CURRENT_OPENS=0\n'
        'ALLOW_PRINT=${allowPrint ? '1' : '0'}\n'
        'MEMBERS_ONLY=${membersOnly ? '1' : '0'}\n'
        'TRAIL_START\n'
        '$initialLog'
        'TRAIL_END\n'
        '$marker';

    final headerBytes = Uint8List.fromList(header.codeUnits);
    final result = Uint8List(headerBytes.length + encryptedPdf.length);
    result.setAll(0, headerBytes);
    result.setAll(headerBytes.length, encryptedPdf);
    return result;
  }

  /// Parses and decrypts a .gdrm container into its metadata and PDF bytes.
  static GdrmParseResult parse(Uint8List data) {
    final headerLookahead = String.fromCharCodes(data.take(30));
    if (headerLookahead.contains('GDRM_RIPPED')) {
      throw const FormatException('CRITICAL ERROR: This document container has triggered anti-tamper self-destruction.');
    }

    final markerBytes = Uint8List.fromList(marker.codeUnits);
    int markerIndex = -1;

    outer:
    for (int i = 0; i <= data.length - markerBytes.length; i++) {
      for (int j = 0; j < markerBytes.length; j++) {
        if (data[i + j] != markerBytes[j]) continue outer;
      }
      markerIndex = i;
      break;
    }

    if (markerIndex == -1) {
      throw const FormatException('Data structure validation failed. Not a valid .gdrm document.');
    }

    final headerBytes = data.sublist(0, markerIndex);
    final payloadBytes = data.sublist(markerIndex + markerBytes.length);
    final headerText = String.fromCharCodes(headerBytes);

    final meta = <String, String>{};
    final parsedTrails = <GdrmTrailLog>[];
    bool inTrailBlock = false;

    for (final line in headerText.split('\n')) {
      final trimmed = line.trim();
      if (trimmed == 'TRAIL_START') {
        inTrailBlock = true;
        continue;
      }
      if (trimmed == 'TRAIL_END') {
        inTrailBlock = false;
        continue;
      }

      if (inTrailBlock && trimmed.isNotEmpty) {
        final log = GdrmTrailLog.parseLine(trimmed);
        if (log != null) parsedTrails.add(log);
      } else {
        final eq = line.indexOf('=');
        if (eq != -1) {
          meta[line.substring(0, eq).trim()] = line.substring(eq + 1).trim();
        }
      }
    }

    final sender = meta['SENDER'] ?? '';
    final pdfBytes = sender.isNotEmpty ? _xorPdf(payloadBytes, sender) : payloadBytes;

    return GdrmParseResult(
      metadata: GdrmMetadata(
        licensedTo: meta['LICENSED_TO'] ?? 'Unknown',
        copyrightOwner: meta['COPYRIGHT_OWNER'] ?? 'Unknown',
        fingerprint: meta['FINGERPRINT'] ?? 'Unknown',
        memeSignature: meta['MEME_SIGNATURE'] ?? 'None',
        timestamp: meta['TIMESTAMP'] ?? 'Unknown',
        sender: sender,
        senderUsername: meta['SENDER_USERNAME'] ?? '',
        senderEmail: meta['SENDER_EMAIL'] ?? '',
        senderDisplayName: meta['SENDER_NAME'] ?? '',
        senderDeviceKey: meta['SENDER_DEVICE_KEY'] ?? '',
        receiver: meta['RECEIVER'] ?? '',
        openAt: meta['OPEN_AT'] ?? '',
        passwordHash: meta['PASSWORD_HASH'] ?? '',
        maxAttempts: int.tryParse(meta['MAX_ATTEMPTS'] ?? '0') ?? 0,
        currentAttempts: int.tryParse(meta['CURRENT_ATTEMPTS'] ?? '0') ?? 0,
        targetUsername: meta['TARGET_USERNAME'] ?? '',
        riggedExpiry: meta['RIGGED_EXPIRY'] ?? '',
        maxOpens: int.tryParse(meta['MAX_OPENS'] ?? '0') ?? 0,
        currentOpens: int.tryParse(meta['CURRENT_OPENS'] ?? '0') ?? 0,
        allowPrint: (meta['ALLOW_PRINT'] ?? '1') != '0',
        membersOnly: (meta['MEMBERS_ONLY'] ?? '0') == '1',
        trailLogs: parsedTrails,
      ),
      pdfBytes: pdfBytes,
    );
  }

  /// Verifies hardware binding status against the current device key.
  static GdrmDrmCheckResult verifyDeviceBinding({
    required Uint8List rawFileBytes,
    required GdrmParseResult parsed,
    required String deviceKey,
  }) {
    final meta = parsed.metadata;
    if (!meta.hasSecurity) return const GdrmDrmCheckResult(GdrmDrmStatus.legacy);
    if (!meta.hasReceiver) {
      final updated = _writeReceiverIntoBytes(rawFileBytes, deviceKey);
      return GdrmDrmCheckResult(
        GdrmDrmStatus.boundNow,
        updatedBytes: updated,
        message: 'Document successfully bound to this primary device hardware.',
      );
    }
    if (meta.receiver == deviceKey) {
      return const GdrmDrmCheckResult(
        GdrmDrmStatus.authorised,
        message: 'Hardware authorization verified.',
      );
    }
    return const GdrmDrmCheckResult(
      GdrmDrmStatus.piracyDetected,
      message: 'Piracy violation: Document is locked to a different authorized workstation.',
    );
  }

  static Uint8List _writeReceiverIntoBytes(Uint8List data, String deviceKey) {
    final text = String.fromCharCodes(data);
    final updated = text.replaceFirst('RECEIVER=\n', 'RECEIVER=$deviceKey\n');
    return Uint8List.fromList(updated.codeUnits);
  }

  /// Appends an action log entry to the embedded SnailTrail.
  static Uint8List appendTrailLog({
    required Uint8List rawFileBytes,
    required String action,
    required String deviceKey,
    required String details,
  }) {
    final text = String.fromCharCodes(rawFileBytes);
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).toStringAsFixed(3);
    final logLine = '$action|$timestamp|$deviceKey|$details\nTRAIL_END';
    final updated = text.replaceFirst('TRAIL_END', logLine);
    return Uint8List.fromList(updated.codeUnits);
  }

  /// Increments opening counter in the container.
  static Uint8List incrementOpeningCounter(Uint8List rawFileBytes, int currentVal) {
    final text = String.fromCharCodes(rawFileBytes);
    final updated = text.replaceFirst('CURRENT_OPENS=$currentVal\n', 'CURRENT_OPENS=${currentVal + 1}\n');
    return Uint8List.fromList(updated.codeUnits);
  }

  /// Corrupts container file irreversibly if failed threshold reached.
  static Uint8List deployedTerminalSelfDestruct() {
    final ripHeader = 'GDRM_RIPPED_V1\nMETADATA=DESTROYED\nSTATUS=RIGGED_MELT_TRIGGERED\nTIMESTAMP=${DateTime.now().toUtc()}\n';
    final rng = Random.secure();
    final garbage = Uint8List.fromList(List<int>.generate(1024, (_) => rng.nextInt(256)));
    final result = Uint8List(ripHeader.codeUnits.length + garbage.length);
    result.setAll(0, ripHeader.codeUnits);
    result.setAll(ripHeader.codeUnits.length, garbage);
    return result;
  }

  /// Registers failed password attempt and melts container if max attempts exceeded.
  static Uint8List registerFailedAttempt(Uint8List rawFileBytes, GdrmMetadata meta) {
    final text = String.fromCharCodes(rawFileBytes);
    final nextAttempts = meta.currentAttempts + 1;
    if (meta.maxAttempts > 0 && nextAttempts >= meta.maxAttempts) {
      return deployedTerminalSelfDestruct();
    } else {
      final updated = text.replaceFirst('CURRENT_ATTEMPTS=${meta.currentAttempts}\n', 'CURRENT_ATTEMPTS=$nextAttempts\n');
      return Uint8List.fromList(updated.codeUnits);
    }
  }

  /// Utility to write byte payload back to target file
  static Future<void> saveFile(String filePath, Uint8List bytes) async {
    await File(filePath).writeAsBytes(bytes, flush: true);
  }
}
