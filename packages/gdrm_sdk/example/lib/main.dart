import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gdrm_sdk/gdrm_sdk.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GdrmSdkExampleApp(),
  ));
}

class GdrmSdkExampleApp extends StatefulWidget {
  const GdrmSdkExampleApp({super.key});

  @override
  State<GdrmSdkExampleApp> createState() => _GdrmSdkExampleAppState();
}

class _GdrmSdkExampleAppState extends State<GdrmSdkExampleApp> {
  Uint8List? _protectedBytes;

  @override
  void initState() {
    super.initState();
    _createSampleDocument();
  }

  void _createSampleDocument() {
    // Generate a sample document encrypted using GdrmEngine
    final samplePdf = utf8.encode('%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj 2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj 3 0 obj<</Type/Page/MediaBox[0 0 300 144]/Parent 2 0 R/Resources<<>>>>endobj\nxref\n0 4\n0000000000 65535 f\n0000000010 00000 n\n0000000053 00000 n\n0000000102 00000 n\ntrailer<</Size 4/Root 1 0 R>>\nstartxref\n178\n%%EOF');
    
    final encryptedGdrm = GdrmEngine.pack(
      pdfBytes: Uint8List.fromList(samplePdf),
      licensedTo: 'Demo Licensee',
      copyrightOwner: 'GDRM Ecosystem',
      memeSignature: 'GDRM-ENTERPRISE-SDK',
      allowPrint: false,
    );

    setState(() {
      _protectedBytes = encryptedGdrm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GDRM SDK Example'),
        backgroundColor: const Color(0xFF1E1E24),
      ),
      body: _protectedBytes == null
          ? const Center(child: CircularProgressIndicator())
          : GdrmSecureViewer(
              rawBytes: _protectedBytes,
              userContext: const GdrmUserContext(
                username: 'demo_user',
                displayName: 'Demo Enterprise User',
                isMember: true,
              ),
              securityConfig: const GdrmSecurityConfig(
                enableDynamicWatermark: true,
                watermarkOpacity: 0.18,
              ),
              onDocumentLoaded: (metadata) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unlocked document: ${metadata.fingerprint}')),
                );
              },
            ),
    );
  }
}
