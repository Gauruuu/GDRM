import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

void main() async {
  print('Testing pure Dart Syncfusion PDF watermarking...');
  
  // Create a sample 2-page PDF
  final sf.PdfDocument doc = sf.PdfDocument();
  doc.pages.add().graphics.drawString('Page 1 content: Examination Paper 2026', sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 18));
  doc.pages.add().graphics.drawString('Page 2 content: Confidential Rights Document', sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 18));
  final List<int> originalBytes = doc.saveSync();
  doc.dispose();

  print('Original PDF size: ${originalBytes.length} bytes');

  // Now watermark it in pure Dart
  final sf.PdfDocument watermarkedDoc = sf.PdfDocument(inputBytes: originalBytes);
  final sf.PdfFont headerFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 7);
  final sf.PdfFont watermarkFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 14, style: sf.PdfFontStyle.bold);
  final sf.PdfFont subFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 9);
  
  // Whisper-faint colors
  final watermarkBrush = sf.PdfSolidBrush(sf.PdfColor(100, 100, 100, 25)); // faint opacity
  final headerBrush = sf.PdfSolidBrush(sf.PdfColor(80, 80, 80, 50));

  for (int i = 0; i < watermarkedDoc.pages.count; i++) {
    final sf.PdfPage page = watermarkedDoc.pages[i];
    final sf.PdfGraphics graphics = page.graphics;
    final pageSize = page.getClientSize();

    // 1. Top header
    graphics.drawString('CONFIDENTIAL  |  LICENSED TO: GAURAV  |  GDRM PROTECTED', headerFont, brush: headerBrush, bounds: sf.Rect.fromLTWH(14, 8, pageSize.width - 28, 12));

    // 2. Bottom footer
    graphics.drawString('PRINTED: 11 OCT 2026  |  IP: 192.168.1.1  |  SIG: GDRM_SECURE', headerFont, brush: headerBrush, bounds: sf.Rect.fromLTWH(14, pageSize.height - 18, pageSize.width - 28, 12));

    // 3. Center diagonal watermark
    graphics.save();
    graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
    graphics.rotateTransform(-35);
    graphics.drawString('RESTRICTED PHYSICAL COPY - GAURAV', watermarkFont, brush: watermarkBrush, format: sf.PdfStringFormat(alignment: sf.PdfTextAlignment.center));
    graphics.drawString('PROPERTY OF GAURANG DALAL (@GAURUU) - DO NOT COPY', subFont, brush: watermarkBrush, bounds: sf.Rect.fromLTWH(-200, 20, 400, 20), format: sf.PdfStringFormat(alignment: sf.PdfTextAlignment.center));
    graphics.restore();
  }

  final List<int> outputBytes = watermarkedDoc.saveSync();
  watermarkedDoc.dispose();

  print('Watermarked PDF size: ${outputBytes.length} bytes');
  print('SUCCESS! Pure Dart watermarking completed without any crash!');
}
