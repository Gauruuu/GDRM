import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';

/// Listens for incoming .gdrm file paths from:
///   - Android: file/content intent (app opened via file manager)
///   - Windows: command-line argument (double-click in Explorer)
class FileIntentService {
  static final _controller = StreamController<String>.broadcast();

  /// Stream of absolute file paths for incoming .gdrm files
  static Stream<String> get onFileReceived => _controller.stream;

  static AppLinks? _appLinks;

  static Future<void> init(List<String> args) async {
    // ── Windows: file path passed as CLI argument ──────────────────────────
    if (Platform.isWindows && args.isNotEmpty) {
      final path = args.first;
      if (path.toLowerCase().endsWith('.gdrm') && File(path).existsSync()) {
        // Slight delay so the widget tree is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _controller.add(path);
        });
      }
    }

    // ── Android: file intent URI from app_links ────────────────────────────
    if (Platform.isAndroid) {
      _appLinks = AppLinks();

      // App opened cold from a file tap
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        final path = _uriToPath(initialUri);
        if (path != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _controller.add(path);
          });
        }
      }

      // App already running, file tapped again
      _appLinks!.uriLinkStream.listen((uri) {
        final path = _uriToPath(uri);
        if (path != null) _controller.add(path);
      });
    }
  }

  /// Android's own intent-filter (VIEW action + .gdrm mimeType/pathPattern,
  /// declared in AndroidManifest.xml) already restricts which files reach
  /// this stream — so we don't need to re-check the URI text here.
  ///
  /// This used to reject any URI that didn't literally contain "gdrm", but
  /// content:// URIs from providers like WhatsApp or Google Drive are
  /// opaque (e.g. content://com.whatsapp.provider.media/item/<uuid>) and
  /// never contain the filename or extension at all. That check was
  /// silently dropping legitimate file opens from those apps.
  static String? _uriToPath(Uri uri) {
    return uri.toString();
  }

  static void dispose() {
    _controller.close();
  }
}