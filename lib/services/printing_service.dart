import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/gdrm_model.dart';
import '../theme/app_theme.dart';
import 'piracy_service.dart';

class PrintingService {
  /// Keywords found in virtual PDF printers or file writers that should be blocked in hardware mode
  static const List<String> _virtualPrinterKeywords = [
    'pdf',
    'xps',
    'onenote',
    'fax',
    'save as',
    'print to file',
    'cutepdf',
    'foxit',
    'bullzip',
    'primopdf',
    'dopdf',
    'nitro',
    'distiller',
    'virtual',
  ];

  /// Checks if a printer is a virtual printer / PDF writer
  static bool isVirtualPrinter(Printer printer) {
    final name = printer.name.toLowerCase();
    final model = (printer.model ?? '').toLowerCase();
    final location = (printer.location ?? '').toLowerCase();

    return _virtualPrinterKeywords.any((keyword) =>
        name.contains(keyword) ||
        model.contains(keyword) ||
        location.contains(keyword));
  }

  /// Fetches only physical/hardware printers
  static Future<List<Printer>> getPhysicalPrinters() async {
    final allPrinters = await Printing.listPrinters();
    return allPrinters.where((p) => !isVirtualPrinter(p)).toList();
  }

  /// Sanitizes text to pure printable ASCII characters, preventing any Type1 font unicode exceptions
  static String _sanitizeAscii(String input) {
    if (input.isEmpty) return '';
    var s = input
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('•', '-')
        .replaceAll('…', '...')
        .replaceAll('©', '(C)')
        .replaceAll('®', '(R)')
        .replaceAll('™', '(TM)')
        .replaceAll('°', ' deg')
        .replaceAll('±', '+/-')
        .replaceAll('✓', '[OK]')
        .replaceAll('✗', '[X]');
    return s.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  /// Generates watermarked PDF bytes from original PDF pages with exact 1:1 paper point scaling
  static Future<Uint8List> generateWatermarkedPdfBytes({
    required Uint8List originalPdfBytes,
    required GdrmMetadata manifest,
    required String activeUsername,
    required String ipAddress,
    required String macAddress,
    required DateTime printTime,
    PdfPageFormat? targetPageFormat,
    double rasterDpi = 200.0,
  }) async {
    pw.ThemeData theme;
    try {
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();
      theme = pw.ThemeData.withFont(base: font, bold: boldFont);
    } catch (_) {
      theme = pw.ThemeData.base();
    }

    final pdfDoc = pw.Document(theme: theme);
    final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(printTime);
    final receiverDisplay = manifest.targetUsername.isNotEmpty ? manifest.targetUsername : activeUsername;

    // Sanitized strings for guaranteed rendering without missing glyphs or exceptions
    final safeLicensedTo = _sanitizeAscii(manifest.licensedTo.toUpperCase());
    final safeReceiverDisplay = _sanitizeAscii(receiverDisplay.toUpperCase());
    final safeCopyright = _sanitizeAscii(manifest.copyrightOwner.toUpperCase());
    final safeActiveUser = _sanitizeAscii(activeUsername.toUpperCase());
    final safeFingerprint = _sanitizeAscii(manifest.fingerprint);
    final safeSignature = _sanitizeAscii(manifest.memeSignature);
    final safeIp = _sanitizeAscii(ipAddress);
    final safeMac = _sanitizeAscii(macAddress);
    final safeDate = _sanitizeAscii(formattedDate);

    // Ultra-faint tones tailored for authentic examination & confidential paper security
    // Whisper-faint (~1.5% - 2.3% opacity) with light weight so questions, text, equations, and diagrams remain 100% clear
    final headerFooterColor = PdfColor.fromInt(0x14555555); // ~7.8% opacity for perimeter margins
    final examWatermarkColor = PdfColor.fromInt(0x05666666); // ~2.0% opacity whisper-faint watermark
    final examWatermarkSubColor = PdfColor.fromInt(0x03666666); // ~1.2% opacity subtle detail

    // Rasterize each page of the original PDF at high resolution
    await for (final page in Printing.raster(originalPdfBytes, dpi: rasterDpi)) {
      final imageBytes = await page.toPng();
      final pageImage = pw.MemoryImage(imageBytes);

      // Convert raster pixels to standard PDF points (72 points = 1 inch)
      final double naturalWidthPt = page.width * 72.0 / rasterDpi;
      final double naturalHeightPt = page.height * 72.0 / rasterDpi;

      final formatToUse = targetPageFormat ??
          PdfPageFormat(
            naturalWidthPt,
            naturalHeightPt,
            marginAll: 0,
          );

      pdfDoc.addPage(
        pw.Page(
          pageFormat: formatToUse,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Stack(
              fit: pw.StackFit.expand,
              children: [
                // Cleanly fitted original page content (guarantees no zooming, no stretching, no cropping)
                pw.Center(
                  child: pw.FittedBox(
                    fit: pw.BoxFit.contain,
                    child: pw.Image(pageImage),
                  ),
                ),

                // ── Authentic Exam Paper Security Diagonal Background ──
                // Evenly spaced, whisper-faint, anti-leak repeating watermark
                pw.Center(
                  child: pw.Transform.rotate(
                    angle: -0.58, // ~ -33 degrees natural diagonal flow
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Band 1
                        pw.Text(
                          'CONFIDENTIAL EVALUATION COPY - DO NOT DUPLICATE',
                          style: pw.TextStyle(
                            color: examWatermarkColor,
                            fontSize: 12,
                            letterSpacing: 2.5,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'LICENSED TO: $safeLicensedTo  |  RECEIVER: @$safeReceiverDisplay',
                          style: pw.TextStyle(
                            color: examWatermarkSubColor,
                            fontSize: 8,
                            letterSpacing: 1.0,
                          ),
                        ),
                        pw.SizedBox(height: 70),

                        // Band 2 (Main Center Forensic Axis)
                        pw.Text(
                          'GDRM SECURE PHYSICAL COPY - EXAM SECURITY SYSTEM',
                          style: pw.TextStyle(
                            color: examWatermarkColor,
                            fontSize: 13,
                            letterSpacing: 3.0,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'AUTHOR: $safeCopyright  |  PRINT SPOOL: @$safeActiveUser',
                          style: pw.TextStyle(
                            color: examWatermarkSubColor,
                            fontSize: 8.5,
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'FP: $safeFingerprint  |  IP: $safeIp  |  $safeDate',
                          style: pw.TextStyle(
                            color: examWatermarkSubColor,
                            fontSize: 7.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 70),

                        // Band 3
                        pw.Text(
                          'FOR OFFICIAL USE ONLY - TRACKED CONTAINER',
                          style: pw.TextStyle(
                            color: examWatermarkColor,
                            fontSize: 11,
                            letterSpacing: 2.0,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'SIG: $safeSignature  |  MAC: $safeMac  |  SESSION: $safeFingerprint',
                          style: pw.TextStyle(
                            color: examWatermarkSubColor,
                            fontSize: 7.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Perimeter Top Margin Header ──
                pw.Positioned(
                  top: 8,
                  left: 14,
                  right: 14,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '[ GDRM EXAM SECURITY AUDIT - FP: $safeFingerprint ]',
                        style: pw.TextStyle(
                          color: headerFooterColor,
                          fontSize: 6.0,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.Text(
                        'LICENSED: $safeLicensedTo',
                        style: pw.TextStyle(
                          color: headerFooterColor,
                          fontSize: 6.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Perimeter Bottom Margin Footer ──
                pw.Positioned(
                  bottom: 8,
                  left: 14,
                  right: 14,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'PRINTED BY: @$safeActiveUser  |  $safeDate  |  IP: $safeIp',
                        style: pw.TextStyle(
                          color: headerFooterColor,
                          fontSize: 6.0,
                        ),
                      ),
                      pw.Text(
                        'SIG: $safeSignature',
                        style: pw.TextStyle(
                          color: headerFooterColor,
                          fontSize: 6.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return await pdfDoc.save();
  }

  /// Opens full interactive Print Simulation with paper fit metrics and watermarked preview
  static Future<void> simulatePrint({
    required BuildContext context,
    required Uint8List originalPdfBytes,
    required GdrmMetadata manifest,
    required String activeUsername,
    required String ipAddress,
    required String macAddress,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: AppTheme.bgGlassPanel,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppTheme.colorCyan),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Generating simulated watermarked paper output...',
                style: TextStyle(color: AppTheme.fgLight, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      await generateWatermarkedPdfBytes(
        originalPdfBytes: originalPdfBytes,
        manifest: manifest,
        activeUsername: activeUsername,
        ipAddress: ipAddress,
        macAddress: macAddress,
        printTime: DateTime.now(),
      );

      if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // Close loading

      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => Scaffold(
              backgroundColor: AppTheme.bgMain,
              appBar: AppBar(
                backgroundColor: AppTheme.bgGlassSidebar,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.fgLight),
                  onPressed: () => Navigator.pop(ctx),
                ),
                title: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECURE PRINT SIMULATION',
                      style: TextStyle(
                        color: AppTheme.fgLight,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      '100% Exact Paper Fit & Dynamic Security Watermark Preview',
                      style: TextStyle(color: AppTheme.colorCyan, fontSize: 10),
                    ),
                  ],
                ),
              ),
              body: PdfPreview(
                build: (format) async => generateWatermarkedPdfBytes(
                  originalPdfBytes: originalPdfBytes,
                  manifest: manifest,
                  activeUsername: activeUsername,
                  ipAddress: ipAddress,
                  macAddress: macAddress,
                  printTime: DateTime.now(),
                  targetPageFormat: format,
                ),
                allowPrinting: false,
                allowSharing: false,
                canChangeOrientation: true,
                canChangePageFormat: true,
                canDebug: false,
                initialPageFormat: PdfPageFormat.a4,
                pdfFileName: 'GDRM_Simulation_${manifest.fingerprint}.pdf',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.bgGlassPanel,
            title: const Text('Simulation Error', style: TextStyle(color: Colors.redAccent)),
            content: Text(e.toString(), style: const TextStyle(color: AppTheme.fgLight, fontSize: 12)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  /// Initiates physical print dialog with strict virtual printer filtering + simulation option
  static Future<void> printDocument({
    required BuildContext context,
    required Uint8List originalPdfBytes,
    required GdrmMetadata manifest,
    required String activeUsername,
    required String ipAddress,
    required String macAddress,
  }) async {
    // 1. Fetch available physical hardware printers
    final physicalPrinters = await getPhysicalPrinters();

    if (!context.mounted) return;

    // 2. Show Physical Printer Selection & Simulation Dialog
    Printer? selectedPrinter = physicalPrinters.isNotEmpty ? physicalPrinters.first : null;

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.bgGlassSidebar,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.colorCyan),
          ),
          title: const Row(
            children: [
              Icon(Icons.print_rounded, color: AppTheme.colorCyan),
              SizedBox(width: 10),
              Text(
                'Secure Physical Paper Print',
                style: TextStyle(
                  color: AppTheme.fgLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Print to physical hardware paper with 100% true-to-fit scaling and indelible dynamic security watermark.',
                style: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'SELECT PHYSICAL PRINTER',
                style: TextStyle(
                  color: AppTheme.colorCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              if (physicalPrinters.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgGlassPanel,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderGlass),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Printer>(
                      isExpanded: true,
                      value: selectedPrinter,
                      dropdownColor: AppTheme.bgGlassSidebar,
                      items: physicalPrinters.map((p) {
                        return DropdownMenuItem<Printer>(
                          value: p,
                          child: Row(
                            children: [
                              const Icon(Icons.print, size: 16, color: AppTheme.fgLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: AppTheme.fgLight,
                                    fontSize: 12,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedPrinter = val);
                        }
                      },
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.print_disabled_rounded, color: Colors.redAccent, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No hardware printer connected. You can still run "Simulate Print" to inspect the exact paper fit and watermark.',
                          style: TextStyle(color: Colors.redAccent, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.colorAmber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.colorAmber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: AppTheme.colorAmber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Virtual PDF export & file saving are disabled.\nWatermarked to: $activeUsername',
                        style: const TextStyle(
                          color: AppTheme.colorAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, 'CANCEL'),
              child: const Text('CANCEL',
                  style: TextStyle(color: AppTheme.fgMuted, fontWeight: FontWeight.bold)),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.colorCyan,
                side: const BorderSide(color: AppTheme.colorCyan),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              icon: const Icon(Icons.preview_rounded, size: 14),
              onPressed: () => Navigator.pop(dialogCtx, 'SIMULATE'),
              label: const Text('SIMULATE PRINT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            if (physicalPrinters.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: () => Navigator.pop(dialogCtx, 'PRINT'),
                child: const Text('PRINT NOW',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
      ),
    );

    if (action == null || action == 'CANCEL' || !context.mounted) return;

    if (action == 'SIMULATE') {
      await simulatePrint(
        context: context,
        originalPdfBytes: originalPdfBytes,
        manifest: manifest,
        activeUsername: activeUsername,
        ipAddress: ipAddress,
        macAddress: macAddress,
      );
      return;
    }

    if (action == 'PRINT' && selectedPrinter != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          backgroundColor: AppTheme.bgGlassPanel,
          content: Row(
            children: [
              CircularProgressIndicator(color: AppTheme.colorCyan),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Burning security watermarks & spooling to printer...',
                  style: TextStyle(color: AppTheme.fgLight, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );

      try {
        await generateWatermarkedPdfBytes(
          originalPdfBytes: originalPdfBytes,
          manifest: manifest,
          activeUsername: activeUsername,
          ipAddress: ipAddress,
          macAddress: macAddress,
          printTime: DateTime.now(),
        );

        if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // Close loading

        // Send directly to the hardware printer with 100% paper fit layout
        await Printing.directPrintPdf(
          printer: selectedPrinter!,
          onLayout: (PdfPageFormat format) async => generateWatermarkedPdfBytes(
            originalPdfBytes: originalPdfBytes,
            manifest: manifest,
            activeUsername: activeUsername,
            ipAddress: ipAddress,
            macAddress: macAddress,
            printTime: DateTime.now(),
            targetPageFormat: format,
          ),
          name: 'GDRM_Protected_${manifest.fingerprint}',
        );

        // Record physical print event to cloud database audit trail
        PiracyService.recordDatabaseSnailTrail(
          fingerprint: manifest.fingerprint,
          action: 'PHYSICAL_PRINT',
          deviceKey: manifest.receiver.isNotEmpty ? manifest.receiver : 'PRINT_STATION',
          details: 'Document watermarked and spooled to physical printer "${selectedPrinter!.name}" by @$activeUsername',
          senderUsername: manifest.senderUsername,
          activeUsername: activeUsername,
          ipAddress: ipAddress,
          macAddress: macAddress,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.bgGlassPanel,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 8),
                  Text('Document spooled to ${selectedPrinter!.name} with security watermark.',
                      style: const TextStyle(color: AppTheme.fgLight, fontSize: 12)),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // Close loading
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.bgGlassPanel,
              title: const Text('Print Error',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              content: Text('Failed to complete print operation:\n$e',
                  style: const TextStyle(color: AppTheme.fgLight, fontSize: 12)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(color: AppTheme.colorCyan)),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}
