import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

Uint8List generateWatermarkedPdfBytes({
  required Uint8List originalPdfBytes,
  required String licensedTo,
  required String copyrightOwner,
  required String memeSignature,
  required String fingerprint,
  required String activeUsername,
  required String ipAddress,
  required String macAddress,
  required DateTime printTime,
}) {
  final sf.PdfDocument document = sf.PdfDocument(inputBytes: originalPdfBytes);
  final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(printTime);

  final safeLicensedTo = licensedTo.toUpperCase();
  final safeReceiverDisplay = activeUsername.toUpperCase();
  final safeCopyright = copyrightOwner.toUpperCase();
  final safeActiveUser = activeUsername.toUpperCase();
  final safeFingerprint = fingerprint;
  final safeSignature = memeSignature;
  final safeIp = ipAddress;
  final safeMac = macAddress;
  final safeDate = formattedDate;

  final sf.PdfFont headerFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 6.5);
  final sf.PdfFont watermarkBoldFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 12, style: sf.PdfFontStyle.bold);
  final sf.PdfFont watermarkSubFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 8);

  final watermarkBrush = sf.PdfSolidBrush(sf.PdfColor(90, 90, 90, 16));
  final watermarkSubBrush = sf.PdfSolidBrush(sf.PdfColor(100, 100, 100, 12));
  final headerFooterBrush = sf.PdfSolidBrush(sf.PdfColor(80, 80, 80, 32));

  final centerFormat = sf.PdfStringFormat(alignment: sf.PdfTextAlignment.center);

  for (int i = 0; i < document.pages.count; i++) {
    final sf.PdfPage page = document.pages[i];
    final sf.PdfGraphics graphics = page.graphics;
    final pageSize = page.getClientSize();

    // Perimeter Top Margin Header
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

    // Perimeter Bottom Margin Footer
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

    // Diagonal Center Forensic Watermark
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

    // Band 2
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

void main() {
  test('Complete Syncfusion Vector Watermark Test', () {
    final sf.PdfDocument doc = sf.PdfDocument();
    doc.pages.add().graphics.drawString('Page 1 Test Content', sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 18));
    doc.pages.add().graphics.drawString('Page 2 Test Content', sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 18));
    final originalBytes = Uint8List.fromList(doc.saveSync());
    doc.dispose();

    final watermarked = generateWatermarkedPdfBytes(
      originalPdfBytes: originalBytes,
      licensedTo: 'Gaurav Sharma',
      copyrightOwner: 'Gaurang Dalal (@gauruu)',
      memeSignature: 'SECURE_SIG',
      fingerprint: 'GDRM-TEST-1234',
      activeUsername: 'gaurav',
      ipAddress: '192.168.1.100',
      macAddress: 'AA:BB:CC:DD:EE:FF',
      printTime: DateTime.now(),
    );

    expect(watermarked.isNotEmpty, true);
    expect(watermarked.length > originalBytes.length, true);
  });
}
