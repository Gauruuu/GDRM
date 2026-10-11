import 'dart:io';
import '../lib/models/gdrm_model.dart';

void main() async {
  final pdf = await File('scratch/test.pdf').readAsBytes();
  final packed = GdrmService.pack(
    pdfBytes: pdf,
    licensedTo: 'Gaurang',
    copyrightOwner: 'GDRM Ecosystem',
    memeSignature: 'TEST_SIG',
  );
  await File('scratch/test_document.gdrm').writeAsBytes(packed);
  print('Generated scratch/test_document.gdrm successfully!');
}
