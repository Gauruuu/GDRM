import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final pdf = pw.Document();

  final posterFormat = PdfPageFormat(
    1000 * PdfPageFormat.mm,
    1000 * PdfPageFormat.mm,
    marginLeft: 24 * PdfPageFormat.mm,
    marginTop: 24 * PdfPageFormat.mm,
    marginRight: 24 * PdfPageFormat.mm,
    marginBottom: 24 * PdfPageFormat.mm,
  );

  // Exact Logo Green
  final logoGreen = PdfColor.fromInt(0xFF377E22);
  final primaryDark = PdfColor.fromInt(0xFF0A3C2F);
  final primaryGreen = logoGreen;
  final accentGreen = PdfColor.fromInt(0xFF286E1E);
  final lightBgGreen = PdfColor.fromInt(0xFFF0FDF4);
  final cardBg = PdfColors.white;
  final bodyTextColor = PdfColor.fromInt(0xFF112211);
  final mutedTextColor = PdfColor.fromInt(0xFF374151);
  final borderGreen = logoGreen;

  final fontTimes = pw.Font.times();
  final fontTimesBold = pw.Font.timesBold();
  final fontTimesItalic = pw.Font.timesItalic();
  final fontTimesBoldItalic = pw.Font.timesBoldItalic();

  // Load logo image
  final logoFile = File('d:/Kabada/GDRM Flutter/gdrm_ecosystem/scratch/gdrm_logo.png');
  pw.MemoryImage? logoImage;
  if (logoFile.existsSync()) {
    logoImage = pw.MemoryImage(logoFile.readAsBytesSync());
  }

  pdf.addPage(
    pw.Page(
      pageFormat: posterFormat,
      build: (pw.Context context) {
        return pw.Container(
          color: PdfColor.fromInt(0xFFF4F9F6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── TOP HEADER BANNER ──────────────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: pw.BoxDecoration(
                        color: cardBg,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: borderGreen, width: 3),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (logoImage != null)
                            pw.Container(
                              width: 140,
                              height: 70,
                              margin: const pw.EdgeInsets.only(right: 18),
                              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                            ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'GDRM Ecosystems',
                                  style: pw.TextStyle(
                                    font: fontTimesBold,
                                    fontSize: 38,
                                    color: primaryDark,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Granular Digital Right Manager — Zero-Trust Cryptographic Document Security Platform',
                                  style: pw.TextStyle(
                                    font: fontTimesBold,
                                    fontSize: 16.5,
                                    color: primaryGreen,
                                  ),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  'Encapsulate  •  Hardware Key Binding  •  Anti-Piracy Interceptor  •  Dynamic Watermark  •  ChronoLock Self-Destruct',
                                  style: pw.TextStyle(
                                    font: fontTimesItalic,
                                    fontSize: 13,
                                    color: mutedTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: cardBg,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: borderGreen, width: 3),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _metaRow('Code', 'CS-DRM-2026-09', fontTimesBold, fontTimes),
                        _metaRow('Category', 'Cyber Security & Infosec', fontTimesBold, fontTimes),
                        _metaRow('Level', 'UG / Capstone Engineering', fontTimesBold, fontTimes),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // ── 12-SECTION GRID (3 Columns x 4 Rows) ───────────────────────
              pw.Expanded(
                child: pw.Column(
                  children: [
                    // ROW 1: Box 1, 2, 3
                    pw.Expanded(
                      flex: 12,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          // 1. ABSTRACT
                          pw.Expanded(
                            child: _buildCard(
                              number: '1.',
                              title: 'ABSTRACT',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'GDRM (Granular Digital Right Manager) is an enterprise-grade, zero-trust document security ecosystem built with Flutter and Firebase. It eliminates document leakage and unauthorized redistribution by encapsulating sensitive PDF documents into tamper-evident .gdrm cryptographic containers.',
                                    style: pw.TextStyle(font: fontTimes, fontSize: 11.5, height: 1.35, color: bodyTextColor),
                                    textAlign: pw.TextAlign.justify,
                                  ),
                                  pw.SizedBox(height: 8),
                                  pw.Text(
                                    'The system integrates active multi-factor enforcement: Cloud username recipient locking, automatic machine hardware binding, zero-selection anti-copy UI hooks, live countdown ChronoLock timers with data-melting triggers, and watermark-enforced physical printing while intercepting virtual PDF writers.',
                                    style: pw.TextStyle(font: fontTimes, fontSize: 11.5, height: 1.35, color: bodyTextColor),
                                    textAlign: pw.TextAlign.justify,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          // 2. SYSTEM INTERFACE (EXACT DESKTOP & MOBILE MOCKUPS)
                          pw.Expanded(
                            child: _buildCard(
                              number: '2.',
                              title: 'SYSTEM INTERFACE (MOCKUPS)',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Row(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      // Desktop Window
                                      pw.Expanded(
                                        flex: 6,
                                        child: pw.Container(
                                          height: 180,
                                          decoration: pw.BoxDecoration(
                                            color: PdfColor.fromInt(0xFF0B0F19),
                                            borderRadius: pw.BorderRadius.circular(6),
                                            border: pw.Border.all(color: primaryGreen, width: 1.5),
                                          ),
                                          child: pw.Column(
                                            children: [
                                              pw.Container(
                                                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                color: PdfColor.fromInt(0xFF161B26),
                                                child: pw.Row(
                                                  children: [
                                                    pw.Text('● ● ●  ', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey400)),
                                                    pw.Text('GDRM Desktop Console', style: pw.TextStyle(font: fontTimesBold, fontSize: 7, color: PdfColors.white)),
                                                  ],
                                                ),
                                              ),
                                              pw.Expanded(
                                                child: pw.Row(
                                                  children: [
                                                    pw.Container(
                                                      width: 75,
                                                      padding: const pw.EdgeInsets.all(4),
                                                      color: PdfColor.fromInt(0xFF161B26),
                                                      child: pw.Column(
                                                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                        children: [
                                                          pw.Text('GDRM ECOSYSTEMS', style: pw.TextStyle(font: fontTimesBold, fontSize: 5.5, color: PdfColor.fromInt(0xFF00F0FF))),
                                                          pw.SizedBox(height: 3),
                                                          _miniNav('READER CONSOLE', true),
                                                          _miniNav('PACKER CONSOLE', false),
                                                          pw.SizedBox(height: 3),
                                                          pw.Container(
                                                            padding: const pw.EdgeInsets.all(2),
                                                            color: PdfColor.fromInt(0xFF1E2538),
                                                            child: pw.Text('@gaurav [Active]', style: const pw.TextStyle(fontSize: 4.8, color: PdfColors.greenAccent)),
                                                          ),
                                                          pw.SizedBox(height: 3),
                                                          pw.Text('MANIFEST:', style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey500)),
                                                          pw.Text('• Lic: Alice Corp', style: const pw.TextStyle(fontSize: 4.2, color: PdfColors.white)),
                                                          pw.Text('• HW: BOUND-OK', style: const pw.TextStyle(fontSize: 4.2, color: PdfColors.greenAccent)),
                                                        ],
                                                      ),
                                                    ),
                                                    pw.Expanded(
                                                      child: pw.Container(
                                                        padding: const pw.EdgeInsets.all(6),
                                                        color: PdfColor.fromInt(0xFF1E2538),
                                                        child: pw.Column(
                                                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                          children: [
                                                            pw.Text('PROTECTED READER VIEW', style: pw.TextStyle(font: fontTimesBold, fontSize: 6.5, color: PdfColor.fromInt(0xFF00F0FF))),
                                                            pw.SizedBox(height: 2),
                                                            pw.Text('1. Zero text drag selection active.', style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey300)),
                                                            pw.Text('2. Clipboard interceptor: Suppressed.', style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey300)),
                                                            pw.Spacer(),
                                                            pw.Container(
                                                              alignment: pw.Alignment.center,
                                                              padding: const pw.EdgeInsets.all(3),
                                                              color: PdfColor.fromInt(0xFF0F172A),
                                                              child: pw.Text('WATERMARK: LICENSED TO @alice', style: pw.TextStyle(font: fontTimesBold, fontSize: 5.5, color: PdfColors.redAccent)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      pw.SizedBox(width: 8),
                                      // Mobile Phone
                                      pw.Expanded(
                                        flex: 4,
                                        child: pw.Container(
                                          height: 180,
                                          padding: const pw.EdgeInsets.all(4),
                                          decoration: pw.BoxDecoration(
                                            color: PdfColor.fromInt(0xFF0B0F19),
                                            borderRadius: pw.BorderRadius.circular(8),
                                            border: pw.Border.all(color: primaryGreen, width: 1.5),
                                          ),
                                          child: pw.Column(
                                            children: [
                                              pw.Container(
                                                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                                color: PdfColor.fromInt(0xFF161B26),
                                                child: pw.Row(
                                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    pw.Text('GDRM Mobile', style: pw.TextStyle(font: fontTimesBold, fontSize: 5.5, color: PdfColors.white)),
                                                    pw.Text('@gaurav', style: const pw.TextStyle(fontSize: 5, color: PdfColors.greenAccent)),
                                                  ],
                                                ),
                                              ),
                                              pw.SizedBox(height: 4),
                                              pw.Expanded(
                                                child: pw.Container(
                                                  padding: const pw.EdgeInsets.all(4),
                                                  color: PdfColor.fromInt(0xFF1E2538),
                                                  child: pw.Column(
                                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                    children: [
                                                      pw.Text('PACKER CONSOLE', style: pw.TextStyle(font: fontTimesBold, fontSize: 6, color: PdfColor.fromInt(0xFF00F0FF))),
                                                      pw.SizedBox(height: 2),
                                                      _uiTag('Target', '@alice_eng [✓]', lightBgGreen, bodyTextColor, fontTimes),
                                                      _uiTag('ChronoLock', '24h Auto-Melt', lightBgGreen, bodyTextColor, fontTimes),
                                                      _uiTag('Max Opens', '3 Views Only', lightBgGreen, bodyTextColor, fontTimes),
                                                      pw.Spacer(),
                                                      pw.Container(
                                                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                                                        alignment: pw.Alignment.center,
                                                        color: accentGreen,
                                                        child: pw.Text('PACK & ENCRYPT', style: pw.TextStyle(font: fontTimesBold, fontSize: 5.5, color: PdfColors.white)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              pw.SizedBox(height: 2),
                                              pw.Container(
                                                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                                                color: PdfColor.fromInt(0xFF161B26),
                                                child: pw.Row(
                                                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                                                  children: [
                                                    pw.Text('Reader', style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey400)),
                                                    pw.Text('Packer (Active)', style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.greenAccent)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    'Desktop Multi-Pane Console (Left)  |  Mobile App Interface (Right)',
                                    style: pw.TextStyle(font: fontTimesBold, fontSize: 9, color: primaryDark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          // 3. INTRODUCTION
                          pw.Expanded(
                            child: _buildCard(
                              number: '3.',
                              title: 'INTRODUCTION',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Conventional PDF documents suffer from structural security deficiencies. Once shared, static password protected files can be duplicated infinitely, decrypted by brute-force tools, or stripped of protection via virtual PDF writers (e.g. Microsoft Print to PDF) and clipboard extractors.',
                                    style: pw.TextStyle(font: fontTimes, fontSize: 11.5, height: 1.35, color: bodyTextColor),
                                    textAlign: pw.TextAlign.justify,
                                  ),
                                  pw.SizedBox(height: 8),
                                  pw.Text(
                                    'GDRM (Granular Digital Right Manager) solves this with an active client-server zero-trust architecture. Decryption keys are never stored in plaintext and files strictly require cryptographic identity validation, hardware key matching, and real-time execution sandboxing.',
                                    style: pw.TextStyle(font: fontTimes, fontSize: 11.5, height: 1.35, color: bodyTextColor),
                                    textAlign: pw.TextAlign.justify,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),

                    // ROW 2: Box 4, 5, 6
                    pw.Expanded(
                      flex: 11,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          // 4. OBJECTIVES
                          pw.Expanded(
                            child: _buildCard(
                              number: '4.',
                              title: 'OBJECTIVES',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _bulletItem('1.', 'Cryptographic Encapsulation: Package PDFs into encrypted .gdrm containers with header signatures.', fontTimes, fontTimesBold),
                                  _bulletItem('2.', 'Identity-Bound Access: Lock documents strictly to recipient @usernames indexed in Cloud Firestore.', fontTimes, fontTimesBold),
                                  _bulletItem('3.', 'Client-Side Anti-Leak: Intercept clipboard shortcuts (Ctrl+C, Ctrl+A) and drag selection.', fontTimes, fontTimesBold),
                                  _bulletItem('4.', 'Hardware Machine Binding: Lock file decryption to primary host device hardware UUID.', fontTimes, fontTimesBold),
                                  _bulletItem('5.', 'Watermarked Print Engine: Prevent virtual PDF printing while enabling secure physical paper spooling.', fontTimes, fontTimesBold),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          // 5. SYSTEM WORKFLOW
                          pw.Expanded(
                            child: _buildCard(
                              number: '5.',
                              title: 'SYSTEM ARCHITECTURE & WORKFLOW',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                                children: [
                                  _flowBox('Sender selects PDF & sets Recipient @handle, Expiry & Policies', lightBgGreen, primaryDark, borderGreen, fontTimesBold),
                                  pw.Text('v', style: pw.TextStyle(font: fontTimesBold, fontSize: 11, color: accentGreen)),
                                  _flowBox('Packer encrypts payload with derived keystream into .gdrm container', lightBgGreen, primaryDark, borderGreen, fontTimesBold),
                                  pw.Text('v', style: pw.TextStyle(font: fontTimesBold, fontSize: 11, color: accentGreen)),
                                  _flowBox('Recipient opens .gdrm -> App validates Firebase Cloud Identity', lightBgGreen, primaryDark, borderGreen, fontTimesBold),
                                  pw.Text('v', style: pw.TextStyle(font: fontTimesBold, fontSize: 11, color: accentGreen)),
                                  _flowBox('Hardware Lock verified (Trips Piracy Alarm on machine mismatch)', lightBgGreen, primaryDark, borderGreen, fontTimesBold),
                                  pw.Text('v', style: pw.TextStyle(font: fontTimesBold, fontSize: 11, color: accentGreen)),
                                  _flowBox('Reader renders document with Zero-Copy Hooks & Watermarked Spooler', lightBgGreen, primaryDark, borderGreen, fontTimesBold),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          // 6. LITERATURE SURVEY
                          pw.Expanded(
                            child: _buildCard(
                              number: '6.',
                              title: 'LITERATURE SURVEY',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _bulletItem('1.', 'Standard Adobe PDF DRM (2018): Vulnerable to master key extractors and virtual PDF print-to-file circumvention.', fontTimes, fontTimesBold),
                                  _bulletItem('2.', 'Enterprise Cloud DRM Systems (Azure AIP, 2021): Robust but involves high recurring costs, heavy agents, and lack of offline self-destruction.', fontTimes, fontTimesBold),
                                  _bulletItem('3.', 'Hardware Cryptographic Anchors (NIST SP 800-57, 2022): Establishes device binding guidelines adapted in GDRM hardware locks.', fontTimes, fontTimesBold),
                                  _bulletItem('4.', 'Client-Side Anti-Scraping Hooks (IEEE TIFS, 2023): Confirms efficacy of low-level OS input interception in data exfiltration defense.', fontTimes, fontTimesBold),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),

                    // ROW 3: Box 7, 8, 9
                    pw.Expanded(
                      flex: 11,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          // 7. RESEARCH GAP
                          pw.Expanded(
                            child: _buildCard(
                              number: '7.',
                              title: 'RESEARCH GAP & THREATS',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _bulletItem('•', 'No Recipient Exclusivity: Standard passwords can be forwarded to arbitrary unauthorized third parties.', fontTimes, fontTimesBold),
                                  _bulletItem('•', 'Clipboard Leakage: Unmonitored copy-paste buffers allow bulk text theft without leaves of audit logs.', fontTimes, fontTimesBold),
                                  _bulletItem('•', 'Virtual Driver Bypass: Users print protected documents to "Save as PDF" to produce unencrypted copies.', fontTimes, fontTimesBold),
                                  _bulletItem('•', 'Absence of Time-Bombs: Inability to enforce immutable self-destruct datetimes or max view quotas.', fontTimes, fontTimesBold),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          // 8. METHODOLOGY
                          pw.Expanded(
                            child: _buildCard(
                              number: '8.',
                              title: 'METHODOLOGY',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _bulletItem('1.', 'Threat Modeling: Analysis of document leakage attack vectors across memory, clipboard, disk caching, and virtual spoolers.', fontTimes, fontTimesBold),
                                  _bulletItem('2.', 'Container Cryptography: Architected .gdrm binary format with integrity headers and XOR keystream encryption.', fontTimes, fontTimesBold),
                                  _bulletItem('3.', 'Flutter & Native Engine: Engineered custom cross-platform Reader and Packer with OS hook suppression.', fontTimes, fontTimesBold),
                                  _bulletItem('4.', 'Cloud Identity Registry: Integrated Firebase Auth and Firestore for real-time recipient verification.', fontTimes, fontTimesBold),
                                  _bulletItem('5.', 'Security Validation: Penetration tests against piracy trips, spoofing, and file tampering.', fontTimes, fontTimesBold),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          // 9. FEATURES NOT IN STANDARD PDF
                          pw.Expanded(
                            child: _buildCard(
                              number: '9.',
                              title: 'FEATURES VS STANDARD PDF',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _featurePill('Username Recipient Lock: Decryption strictly restricted to authorized @username via Firebase Cloud registry.', lightBgGreen, primaryGreen, fontTimesBold, fontTimes),
                                  _featurePill('Hardware Machine Binding: Automatically bonds to the first opening computer; blocks unauthorized replication.', lightBgGreen, primaryGreen, fontTimesBold, fontTimes),
                                  _featurePill('Virtual Printer Blocking: Filters out Adobe/CutePDF drivers; allows only physical paper with dynamic watermarks.', lightBgGreen, primaryGreen, fontTimesBold, fontTimes),
                                  _featurePill('ChronoLock & Rigged Timers: Enables countdown self-destruct time-bombs and max view thresholds.', lightBgGreen, primaryGreen, fontTimesBold, fontTimes),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),

                    // ROW 4: Box 10, 11, 12
                    pw.Expanded(
                      flex: 10,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          // 10. FUTURE SCOPE
                          pw.Expanded(
                            child: _buildCard(
                              number: '10.',
                              title: 'FUTURE SCOPE',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _bulletItem('1.', 'AI Screen Recording Detection: Camera gaze tracking to deter external smartphone recording.', fontTimes, fontTimesBold),
                                  _bulletItem('2.', 'Zero-Knowledge Proofs: Anonymous yet cryptographically verified recipient authorization.', fontTimes, fontTimesBold),
                                  _bulletItem('3.', 'Multi-Format Container: Extend .gdrm encapsulation to CAD blueprints, audio, and video.', fontTimes, fontTimesBold),
                                  _bulletItem('4.', 'Decentralized Audit Logs: Immutable SnailTrail notarization on distributed ledgers.', fontTimes, fontTimesBold),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          // 11. CONCLUSION
                          pw.Expanded(
                            child: _buildCard(
                              number: '11.',
                              title: 'CONCLUSION',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'GDRM Ecosystems successfully establishes a comprehensive zero-trust security paradigm for sensitive electronic documents. By unifying cryptographic container packaging, cloud recipient authentication, hardware device binding, anti-copy reader suppression, and dynamic watermarked physical printing, Granular Digital Right Manager prevents unauthorized data leaks at every stage.',
                                    style: pw.TextStyle(font: fontTimes, fontSize: 10.5, height: 1.35, color: bodyTextColor),
                                    textAlign: pw.TextAlign.justify,
                                  ),
                                  pw.SizedBox(height: 6),
                                  pw.Text(
                                    'The ecosystem is ideally suited for defense, corporate IP governance, legal disclosures, and academic research data protection.',
                                    style: pw.TextStyle(font: fontTimes, fontSize: 10.5, height: 1.35, color: bodyTextColor),
                                    textAlign: pw.TextAlign.justify,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          // 12. REFERENCES
                          pw.Expanded(
                            child: _buildCard(
                              number: '12.',
                              title: 'REFERENCES',
                              fontTitle: fontTimesBold,
                              borderColor: borderGreen,
                              headerColor: primaryDark,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _bulletItem('1.', 'Stallings, W. (2020) - Cryptography & Network Security: Principles and Practice, 8th Ed.', fontTimes, fontTimesBold),
                                  _bulletItem('2.', 'Adobe Systems Inc. (2020) - PDF Reference & Security Architecture Specification, ISO 32000-2.', fontTimes, fontTimesBold),
                                  _bulletItem('3.', 'NIST SP 800-175B (2022) - Guideline for Using Cryptographic Standards in Organizations.', fontTimes, fontTimesBold),
                                  _bulletItem('4.', 'IEEE TIFS (2023) - Defending Against Client-Side Data Leakage in Zero-Trust Systems.', fontTimes, fontTimesBold),
                                  _bulletItem('5.', 'Firebase Architecture Guide (2025) - Securing Enterprise Apps with Cloud Firestore & Auth.', fontTimes, fontTimesBold),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),
              // ── BOTTOM FOOTER ──────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: primaryDark,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('GDRM Ecosystems • Granular Digital Right Manager Architecture', style: pw.TextStyle(font: fontTimesBold, fontSize: 12, color: PdfColors.white)),
                    pw.Text('Department of Computer Engineering & Cyber Security', style: pw.TextStyle(font: fontTimesBold, fontSize: 12, color: PdfColors.white)),
                    pw.Text('1000mm x 1000mm Flex Print Format', style: pw.TextStyle(font: fontTimesBold, fontSize: 12, color: PdfColors.white)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  final outputBytes = await pdf.save();
  final outputPath = 'd:/Kabada/GDRM Flutter/gdrm_ecosystem/GDRM_1m_Flex_Poster.pdf';
  await File(outputPath).writeAsBytes(outputBytes);
  print('GDRM 1m x 1m Flex Print Poster PDF generated successfully at: $outputPath');
}

// ── HELPER WIDGETS ──────────────────────────────────────────────────────────

pw.Widget _miniNav(String label, bool active) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 2),
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
    decoration: pw.BoxDecoration(
      color: active ? PdfColor.fromInt(0xFF1E2538) : null,
      borderRadius: pw.BorderRadius.circular(2),
      border: active ? pw.Border.all(color: PdfColor.fromInt(0xFF00F0FF), width: 0.5) : null,
    ),
    child: pw.Text(
      label,
      style: pw.TextStyle(
        fontSize: 4.8,
        color: active ? PdfColor.fromInt(0xFF00F0FF) : PdfColors.grey400,
      ),
    ),
  );
}

pw.Widget _metaRow(String label, String value, pw.Font bold, pw.Font regular) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 70,
          child: pw.Text('$label :', style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColor.fromInt(0xFF0A3C2F))),
        ),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(font: regular, fontSize: 11.5, color: PdfColor.fromInt(0xFF112211))),
        ),
      ],
    ),
  );
}

pw.Widget _buildCard({
  required String number,
  required String title,
  required pw.Font fontTitle,
  required PdfColor borderColor,
  required PdfColor headerColor,
  required pw.Widget child,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: borderColor, width: 2.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4),
          margin: const pw.EdgeInsets.only(bottom: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1.5)),
          ),
          child: pw.Row(
            children: [
              pw.Text('$number ', style: pw.TextStyle(font: fontTitle, fontSize: 14, color: borderColor)),
              pw.Text(title, style: pw.TextStyle(font: fontTitle, fontSize: 13.5, color: headerColor)),
            ],
          ),
        ),
        pw.Expanded(child: child),
      ],
    ),
  );
}

pw.Widget _bulletItem(String num, String text, pw.Font regular, pw.Font bold) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 14,
          child: pw.Text(num, style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColor.fromInt(0xFF0E5A44))),
        ),
        pw.Expanded(
          child: pw.Text(text, style: pw.TextStyle(font: regular, fontSize: 10, height: 1.3, color: PdfColor.fromInt(0xFF112211))),
        ),
      ],
    ),
  );
}

pw.Widget _flowBox(String text, PdfColor bg, PdfColor textCol, PdfColor borderCol, pw.Font font) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
    decoration: pw.BoxDecoration(
      color: bg,
      borderRadius: pw.BorderRadius.circular(4),
      border: pw.Border.all(color: borderCol, width: 1),
    ),
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(font: font, fontSize: 9.5, color: textCol),
    ),
  );
}

pw.Widget _featurePill(String text, PdfColor bg, PdfColor borderCol, pw.Font bold, pw.Font regular) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 4),
    padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 5),
    decoration: pw.BoxDecoration(
      color: bg,
      borderRadius: pw.BorderRadius.circular(3),
      border: pw.Border(left: pw.BorderSide(color: borderCol, width: 3)),
    ),
    child: pw.Text(text, style: pw.TextStyle(font: regular, fontSize: 9.5, height: 1.25, color: PdfColor.fromInt(0xFF112211))),
  );
}

pw.Widget _uiTag(String label, String value, PdfColor bg, PdfColor textColor, pw.Font font) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 2),
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFF1E293B),
      borderRadius: pw.BorderRadius.circular(2),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('$label:', style: pw.TextStyle(font: font, fontSize: 5.5, color: PdfColor.fromInt(0xFF94A3B8))),
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 5.5, color: textColor)),
      ],
    ),
  );
}
