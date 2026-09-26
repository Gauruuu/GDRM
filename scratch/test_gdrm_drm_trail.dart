import 'dart:convert';
import 'dart:typed_data';
import '../lib/models/gdrm_model.dart';

void main() {
  print('=== GDRM PIRACY & SNAIL TRAIL TEST ===');

  final dummyPdf = Uint8List.fromList(utf8.encode('%PDF-1.4 dummy content for testing'));

  // 1. Pack
  final packedBytes = GdrmService.pack(
    pdfBytes: dummyPdf,
    licensedTo: 'Alice Recipient',
    copyrightOwner: 'Bob Creator',
    memeSignature: 'SIG_BOB_SECURE',
    senderUsername: 'bob_creator',
    senderEmail: 'bob@example.com',
    senderDisplayName: 'Bob Creator',
    senderDeviceKey: 'BOB_HOST_DEVICE_KEY_123',
    targetUsername: 'alice_recipient',
  );

  print('1. Packed bytes length: ${packedBytes.length}');

  // 2. Parse
  final parsed = GdrmService.parse(packedBytes);
  print('2. Parsed Metadata:');
  print('   - Licensed To: ${parsed.metadata.licensedTo}');
  print('   - Sender Username: ${parsed.metadata.senderUsername}');
  print('   - Sender Email: ${parsed.metadata.senderEmail}');
  print('   - Target Username: ${parsed.metadata.targetUsername}');
  print('   - Fingerprint: ${parsed.metadata.fingerprint}');
  print('   - Initial Trail Count: ${parsed.metadata.trailLogs.length}');
  for (final l in parsed.metadata.trailLogs) {
    print('     -> Log: $l');
  }

  assert(parsed.metadata.senderUsername == 'bob_creator', 'Sender username mismatch');
  assert(parsed.metadata.trailLogs.isNotEmpty, 'Initial PACKED trail log missing');
  assert(parsed.metadata.trailLogs.first.action == 'PACKED', 'First log should be PACKED');

  // 3. Device Binding (Alice on Device A)
  final aliceDeviceKey = 'ALICE_DEVICE_KEY_ABC';
  final bindResult = GdrmService.checkDrm(
    rawFileBytes: packedBytes,
    parsed: parsed,
    deviceKey: aliceDeviceKey,
  );
  print('3. First Open by Alice -> DRM Status: ${bindResult.status}');
  assert(bindResult.status == DrmStatus.boundNow, 'Expected boundNow');

  var boundBytes = bindResult.updatedBytes!;
  boundBytes = GdrmService.appendTrailLog(
    rawFileBytes: boundBytes,
    action: 'DEVICE_BOUND',
    deviceKey: aliceDeviceKey,
    details: 'Locked to Alice hardware',
  );
  boundBytes = GdrmService.appendTrailLog(
    rawFileBytes: boundBytes,
    action: 'OPENED',
    deviceKey: aliceDeviceKey,
    details: 'Decrypted and verified',
  );

  // 4. Authorized Open by Alice on Device A
  final parsedBound = GdrmService.parse(boundBytes);
  final authResult = GdrmService.checkDrm(
    rawFileBytes: boundBytes,
    parsed: parsedBound,
    deviceKey: aliceDeviceKey,
  );
  print('4. Second Open by Alice on Device A -> DRM Status: ${authResult.status}');
  assert(authResult.status == DrmStatus.authorised, 'Expected authorised');

  // 5. Piracy Attempt: Someone tries to open on Device B (Pirate Device)
  final pirateDeviceKey = 'PIRATE_DEVICE_KEY_XYZ';
  final pirateResult = GdrmService.checkDrm(
    rawFileBytes: boundBytes,
    parsed: parsedBound,
    deviceKey: pirateDeviceKey,
  );
  print('5. Unauthorized Open on Device B -> DRM Status: ${pirateResult.status}');
  assert(pirateResult.status == DrmStatus.piracyDetected, 'Expected piracyDetected');

  // Append Piracy Alert Snail Trail log to the .gdrm file
  final piracyUpdatedBytes = GdrmService.appendTrailLog(
    rawFileBytes: boundBytes,
    action: 'PIRACY_ALERT',
    deviceKey: pirateDeviceKey,
    details: 'Piracy Attempt: Unauthorized device (IP: 192.168.1.150, MAC: AA:BB:CC:DD:EE:FF, User: pirate_user, OS: windows)',
  );

  final parsedPiratedFile = GdrmService.parse(piracyUpdatedBytes);
  print('6. Trail Logs in .gdrm file after Piracy Attempt:');
  for (final l in parsedPiratedFile.metadata.trailLogs) {
    print('   -> [${l.action}] ${l.details}');
  }

  assert(parsedPiratedFile.metadata.trailLogs.any((l) => l.action == 'PIRACY_ALERT'), 'Piracy log must be in file');

  print('\n✅ ALL GDRM PIRACY & SNAIL TRAIL FUNCTIONAL TESTS PASSED SUCCESSFULLY!');
}
