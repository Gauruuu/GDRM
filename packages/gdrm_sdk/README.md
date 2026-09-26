# GDRM Enterprise SDK (`gdrm_sdk`)

**Next-Gen Proprietary Hardware-Locked DRM & Secure Document Viewer Module for Flutter.**

Turn any Flutter PDF application (such as **Zen-PDF**) into a secure, piracy-proof enterprise workstation in less than 5 minutes.

---

## 🚀 Key Features

* 🔒 **Proprietary `.gdrm` Container Support**: Decrypts directly into memory (RAM). Raw PDF bytes are **never written to disk**.
* 🛡️ **Hardware Device Locking**: Auto-binds documents to the first authorized machine using cryptographic device fingerprints.
* 👁️ **Dynamic Forensic Watermarking**: Live overlay with Recipient Name, Copyright Owner, IP address, MAC address, Timestamp, and AI-Deterrence System Directives.
* 🚫 **Anti-Screenshot & Screen Capture Shield**: Native OS-level capture blocking via `ScreenSecurity`.
* ⏳ **Granular Policy Enforcement**:
  * **ChronoLock (`openAt`)**: Time-locked embargoes.
  * **TimeBomb (`riggedExpiry`)**: Automatic self-destruction after expiration.
  * **Open Limit (`maxOpens`)**: Limits total reads per user.
  * **Self-Destruct Meltdown**: Irreversibly corrupts file if brute-force attempts exceed threshold.
  * **Immutable SnailTrail**: Full cryptographic audit trail embedded inside the file.

---

## 📦 1. Installation

Add `gdrm_sdk` to your app's `pubspec.yaml` (e.g. in **Zen-PDF**):

```yaml
dependencies:
  flutter:
    sdk: flutter
  gdrm_sdk:
    path: ../gdrm_ecosystem/packages/gdrm_sdk # Local path or Git repo
```

Then run:
```bash
flutter pub get
```

---

## 💻 2. Quick Start: Dual-Mode Viewer in Zen-PDF

Drop `GdrmSecureViewer` into your viewer page or document tab. It automatically detects whether the opened file is a regular `.pdf` or an encrypted `.gdrm` package:

```dart
import 'package:flutter/material.dart';
import 'package:gdrm_sdk/gdrm_sdk.dart';

class ZenPdfDocumentViewer extends StatelessWidget {
  final String filePath; // Can be a .pdf or .gdrm file
  final String currentUsername;

  const ZenPdfDocumentViewer({
    super.key,
    required this.filePath,
    required this.currentUsername,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(filePath.endsWith('.gdrm') ? 'Zen-PDF (GDRM Protected)' : 'Zen-PDF Viewer'),
      ),
      body: GdrmSecureViewer(
        filePath: filePath,
        userContext: GdrmUserContext(
          username: currentUsername,
          displayName: 'John Doe',
          isMember: true,
        ),
        securityConfig: const GdrmSecurityConfig(
          preventScreenCapture: true,     // Block screenshots
          enableDynamicWatermark: true,   // Forensic watermark
          watermarkOpacity: 0.18,         // Comfortable reading opacity
        ),
        onDocumentLoaded: (metadata) {
          print('Unlocked GDRM Document licensed to: ${metadata.licensedTo}');
        },
        onAccessDenied: (status, message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Access Denied: $message'), backgroundColor: Colors.red),
          );
        },
      ),
    );
  }
}
```

---

## 🛠️ 3. Creator Tool: Encrypting a PDF to `.gdrm` in Zen-PDF

Allow your Zen-PDF users to export and protect their documents:

```dart
import 'dart:io';
import 'package:gdrm_sdk/gdrm_sdk.dart';

Future<void> exportAsGdrm({
  required String inputPdfPath,
  required String outputGdrmPath,
  required String licensedTo,
  required String copyrightOwner,
  DateTime? expiryDate,
  String? password,
}) async {
  // Read original PDF bytes
  final pdfBytes = await File(inputPdfPath).readAsBytes();

  // Pack into encrypted .gdrm container
  final gdrmBytes = GdrmEngine.pack(
    pdfBytes: pdfBytes,
    licensedTo: licensedTo,
    copyrightOwner: copyrightOwner,
    memeSignature: 'ZEN-PDF-ENTERPRISE',
    riggedExpiry: expiryDate,
    password: password ?? '',
    maxAttempts: password != null ? 5 : 0, // 5 attempts then self-destruct
    allowPrint: false,
  );

  // Write protected file
  await File(outputGdrmPath).writeAsBytes(gdrmBytes);
  print('Successfully created protected .gdrm document at: $outputGdrmPath');
}
```

---

## ⚙️ 4. Advanced: Headless DRM Validation

If you want to validate a `.gdrm` file in your own custom rendering pipeline without using the UI widget:

```dart
import 'dart:io';
import 'package:gdrm_sdk/gdrm_sdk.dart';

void inspectGdrmContainer(String path) async {
  final bytes = await File(path).readAsBytes();
  
  if (GdrmEngine.isGdrmFile(bytes)) {
    final parsed = GdrmEngine.parse(bytes);
    final meta = parsed.metadata;
    
    print('Fingerprint: ${meta.fingerprint}');
    print('Licensed To: ${meta.licensedTo}');
    print('Is Expired? ${meta.isTimeBombed}');
    print('Audit Trail: ${meta.trailLogs.length} events logged');
    
    // Decrypted bytes for rendering
    final rawPdfBytes = parsed.pdfBytes;
  }
}
```

---

## 📄 License
Proprietary. Developed for the GDRM Ecosystem and Zen-PDF.
