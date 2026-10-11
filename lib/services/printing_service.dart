import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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

  /// Generates watermarked PDF bytes from original PDF pages using pure Dart vector graphics
  /// (100% crash-proof, no pdfium.dll dependency, instant execution, preserves vector text sharpness)
  static Future<Uint8List> generateWatermarkedPdfBytes({
    required Uint8List originalPdfBytes,
    required GdrmMetadata manifest,
    required String activeUsername,
    required String ipAddress,
    required String macAddress,
    required DateTime printTime,
    PdfPageFormat? targetPageFormat,
    double rasterDpi = 150.0,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: originalPdfBytes);
    final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(printTime);
    final receiverDisplay = manifest.targetUsername.isNotEmpty ? manifest.targetUsername : activeUsername;

    // Sanitized strings for guaranteed rendering without missing glyphs
    final safeLicensedTo = _sanitizeAscii(manifest.licensedTo.toUpperCase());
    final safeReceiverDisplay = _sanitizeAscii(receiverDisplay.toUpperCase());
    final safeCopyright = _sanitizeAscii(manifest.copyrightOwner.toUpperCase());
    final safeActiveUser = _sanitizeAscii(activeUsername.toUpperCase());
    final safeFingerprint = _sanitizeAscii(manifest.fingerprint);
    final safeSignature = _sanitizeAscii(manifest.memeSignature);
    final safeIp = _sanitizeAscii(ipAddress);
    final safeMac = _sanitizeAscii(macAddress);
    final safeDate = _sanitizeAscii(formattedDate);

    // Standard high-reliability fonts
    final sf.PdfFont headerFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 6.5);
    final sf.PdfFont watermarkBoldFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 12, style: sf.PdfFontStyle.bold);
    final sf.PdfFont watermarkSubFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 8);

    // Whisper-faint forensic brushes (authentic examination security tones)
    final watermarkBrush = sf.PdfSolidBrush(sf.PdfColor(90, 90, 90, 16));
    final watermarkSubBrush = sf.PdfSolidBrush(sf.PdfColor(100, 100, 100, 12));
    final headerFooterBrush = sf.PdfSolidBrush(sf.PdfColor(80, 80, 80, 32));

    final centerFormat = sf.PdfStringFormat(alignment: sf.PdfTextAlignment.center);

    for (int i = 0; i < document.pages.count; i++) {
      final sf.PdfPage page = document.pages[i];
      final sf.PdfGraphics graphics = page.graphics;
      final pageSize = page.getClientSize();

      // ── Perimeter Top Margin Header ──
      graphics.drawString(
        '[ GDRM EXAM SECURITY AUDIT - FP: $safeFingerprint ]',
        headerFont,
        brush: headerFooterBrush,
        bounds: Rect.fromLTWH(14, 8, pageSize.width - 28, 12),
      );
      graphics.drawString(
        'LICENSED: $safeLicensedTo',
        headerFont,
        brush: headerFooterBrush,
        bounds: Rect.fromLTWH(14, 8, pageSize.width - 28, 12),
        format: sf.PdfStringFormat(alignment: sf.PdfTextAlignment.right),
      );

      // ── Perimeter Bottom Margin Footer ──
      graphics.drawString(
        'PRINTED BY: @$safeActiveUser  |  $safeDate  |  IP: $safeIp',
        headerFont,
        brush: headerFooterBrush,
        bounds: Rect.fromLTWH(14, pageSize.height - 18, pageSize.width - 28, 12),
      );
      graphics.drawString(
        'SIG: $safeSignature',
        headerFont,
        brush: headerFooterBrush,
        bounds: Rect.fromLTWH(14, pageSize.height - 18, pageSize.width - 28, 12),
        format: sf.PdfStringFormat(alignment: sf.PdfTextAlignment.right),
      );

      // ── Diagonal Center Forensic Watermark ──
      graphics.save();
      graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
      graphics.rotateTransform(-33);

      // Band 1
      graphics.drawString(
        'CONFIDENTIAL EVALUATION COPY - DO NOT DUPLICATE',
        watermarkBoldFont,
        brush: watermarkBrush,
        bounds: const Rect.fromLTWH(-260, -110, 520, 20),
        format: centerFormat,
      );
      graphics.drawString(
        'LICENSED TO: $safeLicensedTo  |  RECEIVER: @$safeReceiverDisplay',
        watermarkSubFont,
        brush: watermarkSubBrush,
        bounds: const Rect.fromLTWH(-260, -92, 520, 16),
        format: centerFormat,
      );

      // Band 2 (Main Center Forensic Axis)
      graphics.drawString(
        'GDRM SECURE PHYSICAL COPY - EXAM SECURITY SYSTEM',
        watermarkBoldFont,
        brush: watermarkBrush,
        bounds: const Rect.fromLTWH(-260, -20, 520, 20),
        format: centerFormat,
      );
      graphics.drawString(
        'AUTHOR: $safeCopyright  |  PRINT SPOOL: @$safeActiveUser',
        watermarkSubFont,
        brush: watermarkSubBrush,
        bounds: const Rect.fromLTWH(-260, -2, 520, 16),
        format: centerFormat,
      );
      graphics.drawString(
        'FP: $safeFingerprint  |  IP: $safeIp  |  $safeDate',
        watermarkSubFont,
        brush: watermarkSubBrush,
        bounds: const Rect.fromLTWH(-260, 14, 520, 16),
        format: centerFormat,
      );

      // Band 3
      graphics.drawString(
        'FOR OFFICIAL USE ONLY - TRACKED CONTAINER',
        watermarkBoldFont,
        brush: watermarkBrush,
        bounds: const Rect.fromLTWH(-260, 75, 520, 20),
        format: centerFormat,
      );
      graphics.drawString(
        'SIG: $safeSignature  |  MAC: $safeMac  |  SESSION: $safeFingerprint',
        watermarkSubFont,
        brush: watermarkSubBrush,
        bounds: const Rect.fromLTWH(-260, 93, 520, 16),
        format: centerFormat,
      );

      graphics.restore();
    }

    final List<int> outputBytes = document.saveSync();
    document.dispose();
    return Uint8List.fromList(outputBytes);
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
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgGlassPanel,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            const SizedBox(width: 20),
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
      final watermarkedBytes = await generateWatermarkedPdfBytes(
        originalPdfBytes: originalPdfBytes,
        manifest: manifest,
        activeUsername: activeUsername,
        ipAddress: ipAddress,
        macAddress: macAddress,
        printTime: DateTime.now(),
        rasterDpi: 150.0,
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
                  icon: Icon(Icons.close_rounded, color: AppTheme.fgLight),
                  onPressed: () => Navigator.pop(ctx),
                ),
                title: Column(
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
                      style: TextStyle(color: AppTheme.isDark ? AppTheme.darkPrimaryGreen : AppTheme.lightPrimaryGreen, fontSize: 10),
                    ),
                  ],
                ),
              ),
              body: SfPdfViewer.memory(
                watermarkedBytes,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                canShowPaginationDialog: true,
                scrollDirection: PdfScrollDirection.vertical,
                pageSpacing: 12,
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
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppTheme.bgGlassPanel,
            title: const Text('Simulation Error', style: TextStyle(color: Colors.redAccent)),
            content: Text(e.toString(), style: TextStyle(color: AppTheme.fgLight, fontSize: 12)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK')),
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
            side: BorderSide(color: AppTheme.colorCyan),
          ),
          title: Row(
            children: [
              Icon(Icons.print_rounded, color: AppTheme.colorCyan),
              const SizedBox(width: 10),
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
              Text(
                'Print to physical hardware paper with 100% true-to-fit scaling and indelible dynamic security watermark.',
                style: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
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
                              Icon(Icons.print, size: 16, color: AppTheme.fgLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: TextStyle(
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
                    color: Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
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
                  color: AppTheme.colorAmber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.colorAmber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        color: AppTheme.colorAmber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Virtual PDF export & file saving are disabled.\nWatermarked to: $activeUsername',
                        style: TextStyle(
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
              child: Text('CANCEL',
                  style: TextStyle(color: AppTheme.fgMuted, fontWeight: FontWeight.bold)),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.colorCyan,
                side: BorderSide(color: AppTheme.colorCyan),
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
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.bgGlassPanel,
          content: Row(
            children: [
              CircularProgressIndicator(color: AppTheme.colorCyan),
              const SizedBox(width: 20),
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
        final printBytes = await generateWatermarkedPdfBytes(
          originalPdfBytes: originalPdfBytes,
          manifest: manifest,
          activeUsername: activeUsername,
          ipAddress: ipAddress,
          macAddress: macAddress,
          printTime: DateTime.now(),
          rasterDpi: 150.0,
        );

        if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // Close loading

        // Send directly to the hardware printer with 100% paper fit layout
        await Printing.directPrintPdf(
          printer: selectedPrinter!,
          onLayout: (PdfPageFormat format) async => printBytes,
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
                      style: TextStyle(color: AppTheme.fgLight, fontSize: 12)),
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
                  style: TextStyle(color: AppTheme.fgLight, fontSize: 12)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('OK', style: TextStyle(color: AppTheme.colorCyan)),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}
