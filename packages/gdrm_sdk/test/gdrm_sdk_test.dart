import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdrm_sdk/gdrm_sdk.dart';

void main() {
  group('GDRM SDK Core Engine Tests', () {
    final samplePdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.7 Test Document Content for Zen-PDF'));

    test('Pack and parse .gdrm container accurately', () {
      final packedBytes = GdrmEngine.pack(
        pdfBytes: samplePdfBytes,
        licensedTo: 'Gaurav / Zen-PDF User',
        copyrightOwner: 'Zen Technologies Corp',
        memeSignature: 'ZEN-ENTERPRISE-DRM',
        password: 'secure_zen_pass',
        maxAttempts: 3,
        allowPrint: false,
      );

      expect(GdrmEngine.isGdrmFile(packedBytes), isTrue);

      final parsed = GdrmEngine.parse(packedBytes);
      expect(parsed.metadata.licensedTo, 'Gaurav / Zen-PDF User');
      expect(parsed.metadata.copyrightOwner, 'Zen Technologies Corp');
      expect(parsed.metadata.hasPassword, isTrue);
      expect(parsed.metadata.allowPrint, isFalse);
      expect(parsed.pdfBytes, equals(samplePdfBytes));
    });

    test('Device binding and hardware lock check', () {
      final packedBytes = GdrmEngine.pack(
        pdfBytes: samplePdfBytes,
        licensedTo: 'Test User',
        copyrightOwner: 'Owner',
        memeSignature: 'SIG',
      );

      final parsed = GdrmEngine.parse(packedBytes);
      const primaryDeviceKey = 'DEV_KEY_MACHINE_A_1234567890ABCDEF12345678';
      const rogueDeviceKey = 'DEV_KEY_MACHINE_B_9876543210FEDCBA98765432';

      // First open -> binds to Device A
      final bindResult = GdrmEngine.verifyDeviceBinding(
        rawFileBytes: packedBytes,
        parsed: parsed,
        deviceKey: primaryDeviceKey,
      );

      expect(bindResult.status, equals(GdrmDrmStatus.boundNow));
      expect(bindResult.updatedBytes, isNotNull);

      // Subsequent open on Device A -> Authorised
      final boundParsed = GdrmEngine.parse(bindResult.updatedBytes!);
      final authResult = GdrmEngine.verifyDeviceBinding(
        rawFileBytes: bindResult.updatedBytes!,
        parsed: boundParsed,
        deviceKey: primaryDeviceKey,
      );
      expect(authResult.status, equals(GdrmDrmStatus.authorised));

      // Attempt open on Rogue Device B -> Piracy Detected!
      final rogueResult = GdrmEngine.verifyDeviceBinding(
        rawFileBytes: bindResult.updatedBytes!,
        parsed: boundParsed,
        deviceKey: rogueDeviceKey,
      );
      expect(rogueResult.status, equals(GdrmDrmStatus.piracyDetected));
    });

    test('Self-destruct on exceeded attempts', () {
      final packedBytes = GdrmEngine.pack(
        pdfBytes: samplePdfBytes,
        licensedTo: 'Target',
        copyrightOwner: 'Owner',
        memeSignature: 'SIG',
        password: 'correct_pass',
        maxAttempts: 2,
      );

      final parsed = GdrmEngine.parse(packedBytes);
      
      // First failed attempt
      final attempt1 = GdrmEngine.registerFailedAttempt(packedBytes, parsed.metadata);
      expect(GdrmEngine.isGdrmFile(attempt1), isTrue);

      // Second failed attempt (reaches maxAttempts)
      final attempt2Meta = GdrmEngine.parse(attempt1).metadata;
      final attempt2 = GdrmEngine.registerFailedAttempt(attempt1, attempt2Meta);

      // Now container is destroyed / melted
      expect(() => GdrmEngine.parse(attempt2), throwsA(isA<FormatException>()));
    });
  });
}
