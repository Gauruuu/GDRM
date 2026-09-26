import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Reads the raw bytes of a content:// URI via Android's native
/// ContentResolver. Needed because content:// URIs — the kind you get
/// when a file is opened via WhatsApp, Google Drive, email attachments,
/// etc. — aren't real filesystem paths. dart:io's File() can't open them;
/// only the platform's own APIs can resolve them to actual bytes.
///
/// Reuses the same MethodChannel as SecurityService, just with an added
/// 'readContentUri' case on the native side (see MainActivity.kt notes).
class ContentUriService {
  static const _channel = MethodChannel('com.gdrm.ecosystem/security');

  static Future<Uint8List> readContentUri(String uriString) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>(
        'readContentUri',
        {'uri': uriString},
      );
      if (bytes == null) {
        throw Exception('No data returned for this file.');
      }
      return bytes;
    } on PlatformException catch (e) {
      throw Exception('Could not read file: ${e.message ?? e.code}');
    }
  }
}