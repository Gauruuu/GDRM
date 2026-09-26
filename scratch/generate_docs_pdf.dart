import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final pdf = pw.Document();

  final primaryColor = PdfColor.fromInt(0xFF00838F); // Deep Teal/Cyan
  final headerNavy = PdfColor.fromInt(0xFF0F172A); // Dark Slate/Navy
  final cardBg = PdfColor.fromInt(0xFF0F172A); // Dark header card
  final bodyText = PdfColor.fromInt(0xFF1E293B); // Dark slate for crystal-clear readability
  final mutedText = PdfColor.fromInt(0xFF64748B); // Slate grey
  final tableRowBg = PdfColor.fromInt(0xFFF8FAFC); // Very light grey
  final tableHeaderBg = PdfColor.fromInt(0xFF1E293B);

  // ── Page 1: Architecture & Authentication ──
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Top Banner
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: pw.BoxDecoration(
                color: cardBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: primaryColor, width: 1.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GDRM ECOSYSTEM',
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(0xFF00E5FF),
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Custom Digital Rights Management & Cryptographic Document Container',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF00E5FF),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'v1.0.0 SPEC',
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Section 1
            pw.Text(
              '1. SYSTEM ARCHITECTURE & OVERVIEW',
              style: pw.TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'GDRM (Gaurav Digital Rights Management) is an enterprise-grade, zero-trust document security ecosystem built with Flutter and Firebase. It provides end-to-end cryptographic encapsulation of PDF documents into proprietary .gdrm containers, offering hardware binding, username recipient locking, anti-copy reader protection, multi-factor destruction triggers, and watermarked physical paper printing.',
              style: pw.TextStyle(color: bodyText, fontSize: 9.5, height: 1.4),
            ),
            pw.SizedBox(height: 14),

            // Section 2
            pw.Text(
              '2. FIREBASE AUTHENTICATION & RECIPIENT REGISTRY',
              style: pw.TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'User authentication is orchestrated through Firebase Auth and Cloud Firestore:',
              style: pw.TextStyle(color: bodyText, fontSize: 9.5),
            ),
            pw.SizedBox(height: 5),
            pw.Bullet(
              text: 'Registration: Collects Full Name, Unique Preferred Username Handle (e.g., @gaurav), Email Address, and Password.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Bullet(
              text: 'Firestore Registry: User documents are indexed under gdrm_users/{username}, storing name, email, uid, and timestamps for real-time recipient verification.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Bullet(
              text: 'Flexible Login: Supports signing in via either unique username handle or email address with session persistence.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Bullet(
              text: 'Sidebar Identity Badge: Displays verified profile status, active username, and instant account switching.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.SizedBox(height: 14),

            // Section 3
            pw.Text(
              '3. USERNAME-LOCKED .GDRM CONTAINER ENCRYPTION',
              style: pw.TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Senders can lock documents exclusively to a recipient username:',
              style: pw.TextStyle(color: bodyText, fontSize: 9.5),
            ),
            pw.SizedBox(height: 5),
            pw.Bullet(
              text: 'Packer Verification: Sender inputs recipient username (e.g., @alice) with live Firestore registry lookup to confirm recipient existence.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Bullet(
              text: 'Cryptographic Binding: TARGET_USERNAME is embedded into the container header, and payload is encrypted using pseudo-random derived XOR keystreams.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Bullet(
              text: 'Unintended Receiver Enforcement: When a non-intended user opens the file, the app immediately blocks access and displays the Unintended Receiver Warning alert. No unauthorized decryption or prompt-leaking is permitted.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Spacer(),

            // Footer
            pw.Divider(color: mutedText, thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('GDRM Ecosystem Technical Documentation',
                    style: pw.TextStyle(color: mutedText, fontSize: 8)),
                pw.Text('Page 1 of 2', style: pw.TextStyle(color: mutedText, fontSize: 8)),
              ],
            ),
          ],
        );
      },
    ),
  );

  // ── Page 2: Reader Security, Printing & Specifications ──
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Section 4
            pw.Text(
              '4. READER SECURITY SUITE & ANTI-COPY PROTECTION',
              style: pw.TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Bullet(
              text: 'Zero Text Selection: Text selection, cursor drag highlighting, context copy menus, scroll status, and pagination dialogs are completely disabled in SfPdfViewer.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Bullet(
              text: 'Keyboard Interceptor: Intercepts and suppresses Ctrl+C, Cmd+C, Ctrl+A, Ctrl+X, and Ctrl+Insert to prevent clipboard leakage.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Bullet(
              text: 'Hardware Key Binding: Automatically locks file to the first opening device hardware key; sharing the file to an unauthorized machine trips the Piracy Alarm.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Bullet(
              text: 'FileRip Password Layer: Implements hashed password challenge with max attempt threshold before triggering irreversible file self-destruction.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Bullet(
              text: 'ChronoLock & Rigged Timers: Enables scheduled future unlock datetimes, live countdown time-bombs (active screen closes & file data melts on expiry), and max view count limits.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.SizedBox(height: 14),

            // Section 5
            pw.Text(
              '5. WATERMARKED PHYSICAL PAPER PRINTING ENGINE',
              style: pw.TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'PrintingService enforces paper-only distribution with persistent provenance tracking:',
              style: pw.TextStyle(color: bodyText, fontSize: 9.5),
            ),
            pw.SizedBox(height: 5),
            pw.Bullet(
              text: 'Virtual PDF Printer Blocking: Inspects system spoolers and filters out virtual PDF writers (e.g., Microsoft Print to PDF, Adobe PDF, Save as PDF, Foxit, CutePDF, OneNote).',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Bullet(
              text: 'Embedded Watermarking: Every page is rasterized and composited with high-resolution watermark metadata (Copyright Owner, Licensed To, Recipient Handle, Printing User, IP/MAC address, and Timestamp).',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.Bullet(
              text: 'Direct Hardware Spooling: Dispatches watermarked pages directly to the selected hardware printer.',
              style: pw.TextStyle(color: bodyText, fontSize: 9),
            ),
            pw.SizedBox(height: 14),

            // Section 6: Container Specification Table
            pw.Text(
              '6. .GDRM CONTAINER SPECIFICATION MATRIX',
              style: pw.TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: tableHeaderBg),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: pw.Text('Field Header',
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: pw.Text('Security Purpose & Functionality',
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                  ],
                ),
                _specRow('LICENSED_TO', 'Authorized licensee/recipient display name', false, tableRowBg, bodyText),
                _specRow('COPYRIGHT_OWNER', 'Legal copyright holder entity', true, tableRowBg, bodyText),
                _specRow('FINGERPRINT', 'Unique cryptographic identifier: GDRM-XXXX-XXXX-XXXX', false, tableRowBg, bodyText),
                _specRow('TARGET_USERNAME', 'Firebase recipient handle required for decryption', true, tableRowBg, bodyText),
                _specRow('SENDER / RECEIVER', 'Cryptographic sender seed / bound device hardware key', false, tableRowBg, bodyText),
                _specRow('OPEN_AT / RIGGED_EXPIRY', 'ChronoLock unlock datetime & time-bomb self-destruct UTC', true, tableRowBg, bodyText),
                _specRow('MAX_OPENS / CURRENT_OPENS', 'Viewing ceiling counter threshold limit', false, tableRowBg, bodyText),
                _specRow('TRAIL_START / TRAIL_END', 'Immutable SnailTrail forensic audit log timestamps', true, tableRowBg, bodyText),
              ],
            ),
            pw.Spacer(),

            // Footer
            pw.Divider(color: mutedText, thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('GDRM Ecosystem Technical Documentation',
                    style: pw.TextStyle(color: mutedText, fontSize: 8)),
                pw.Text('Page 2 of 2', style: pw.TextStyle(color: mutedText, fontSize: 8)),
              ],
            ),
          ],
        );
      },
    ),
  );

  final outputBytes = await pdf.save();
  final outputPath = 'd:/Kabada/GDRM Flutter/gdrm_ecosystem/GDRM_Ecosystem_Documentation.pdf';
  await File(outputPath).writeAsBytes(outputBytes);
  print('GDRM Documentation PDF generated successfully at: $outputPath');
}

pw.TableRow _specRow(String field, String desc, bool isAlt, PdfColor altBg, PdfColor textColor) {
  return pw.TableRow(
    decoration: isAlt ? pw.BoxDecoration(color: altBg) : null,
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        child: pw.Text(field, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textColor)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        child: pw.Text(desc, style: pw.TextStyle(fontSize: 8, color: textColor)),
      ),
    ],
  );
}
