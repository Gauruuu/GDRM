import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../models/gdrm_model.dart';
import '../services/device_key_service.dart';
import '../services/piracy_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class PackerConsole extends StatefulWidget {
  final void Function(String path)? onOpenInReader;

  const PackerConsole({super.key, this.onOpenInReader});

  @override
  State<PackerConsole> createState() => _PackerConsoleState();
}

class _PackerConsoleState extends State<PackerConsole> {
  final _licensedToCtrl = TextEditingController();
  final _copyrightCtrl = TextEditingController();
  final _memeCtrl = TextEditingController(text: 'SECURE_SIGNATURE_v1');
  
  // Recipient Username Lock & Members Only Lock
  final _targetUserCtrl = TextEditingController();
  bool _cloudLockEnabled = true;
  bool _membersOnly = false;
  bool _isCheckingUser = false;
  String? _userVerifyStatus;
  Color _userVerifyColor = AppTheme.fgMuted;

  // Password / FileRip Layer
  final _passwordCtrl = TextEditingController();
  final _maxAttemptsCtrl = TextEditingController(text: '3');
  bool _fileRipEnabled = false;

  // RiggedFile Controllers
  final _riggedDurationCtrl = TextEditingController(text: '30');
  final _maxOpensCtrl = TextEditingController(text: '5');
  String _durationUnit = 'MINUTES'; // MINUTES, HOURS, DAYS
  bool _riggedTimeEnabled = false;
  bool _riggedOpenEnabled = false;

  // ChronoLock
  bool _chronoLockEnabled = false;
  DateTime? _openAt;

  // Physical Printing Permission
  bool _allowPrint = true;

  String? _lastFingerprint;
  String? _lastOutputPath;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.isCloudAuthenticated) {
        if (_copyrightCtrl.text.isEmpty) {
          _copyrightCtrl.text = state.cloudDisplayName?.isNotEmpty == true
              ? '${state.cloudDisplayName!} (@${state.cloudUsername})'
              : '@${state.cloudUsername}';
        }
        if (_memeCtrl.text == 'SECURE_SIGNATURE_v1') {
          _memeCtrl.text = 'SIG_${state.cloudUsername?.toUpperCase()}_GDRM';
        }
      }
    });
  }

  @override
  void dispose() {
    _licensedToCtrl.dispose();
    _copyrightCtrl.dispose();
    _memeCtrl.dispose();
    _targetUserCtrl.dispose();
    _passwordCtrl.dispose();
    _maxAttemptsCtrl.dispose();
    _riggedDurationCtrl.dispose();
    _maxOpensCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyTargetUser() async {
    final username = _targetUserCtrl.text.trim().toLowerCase();
    if (username.isEmpty) {
      setState(() {
        _userVerifyStatus = 'Please enter a target username.';
        _userVerifyColor = Colors.redAccent;
      });
      return;
    }

    setState(() {
      _isCheckingUser = true;
      _userVerifyStatus = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('gdrm_users')
          .doc(username)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final name = (data['name'] as String?) ?? username;
        setState(() {
          _isCheckingUser = false;
          _userVerifyStatus = '✓ Verified recipient: $name (@$username)';
          _userVerifyColor = Colors.greenAccent;
          if (_licensedToCtrl.text.isEmpty) {
            _licensedToCtrl.text = name;
          }
        });
      } else {
        setState(() {
          _isCheckingUser = false;
          _userVerifyStatus = '⚠ User @$username not registered yet on Firebase.';
          _userVerifyColor = AppTheme.colorAmber;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingUser = false;
        _userVerifyStatus = 'Error checking user: $e';
        _userVerifyColor = Colors.redAccent;
      });
    }
  }

  // ── Date/Time Picker Helper Methods ────────────────────────────────────────
  String _formatOpenAt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}  $h:$min';
  }

  Future<void> _pickOpenAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _openAt ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.colorCyan,
            surface: AppTheme.bgGlassSidebar,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _openAt != null
          ? TimeOfDay.fromDateTime(_openAt!)
          : TimeOfDay.fromDateTime(now),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.colorCyan,
            surface: AppTheme.bgGlassSidebar,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _openAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pack() async {
    final licensedTo = _licensedToCtrl.text.trim();
    final copyright = _copyrightCtrl.text.trim();
    final meme = _memeCtrl.text.trim();
    final targetUser = _targetUserCtrl.text.trim().toLowerCase();

    if (licensedTo.isEmpty || copyright.isEmpty) {
      _showDialog('Validation Error', 'Required metadata validation failed. Fill in Licensed Target Name & Copyright Owner.', isError: true);
      return;
    }

    if (_cloudLockEnabled && targetUser.isEmpty) {
      _showDialog('Recipient Required', 'Please enter the receiver\'s username to lock the .gdrm file for them.', isError: true);
      return;
    }

    if (_chronoLockEnabled && _openAt == null) {
      _showDialog('Validation Error', 'ChronoLock is enabled but no unlock date/time has been set.', isError: true);
      return;
    }

    if (_fileRipEnabled && _passwordCtrl.text.trim().isEmpty) {
      _showDialog('Validation Error', 'FileRip password is active but no password phrase was configured.', isError: true);
      return;
    }

    final state = context.read<AppState>();

    // Verify recipient in Firestore if cloud lock is enabled
    if (_cloudLockEnabled && targetUser.isNotEmpty) {
      state.setPackerWorking(true);
      try {
        final lookup = await FirebaseFirestore.instance
            .collection('gdrm_users')
            .doc(targetUser)
            .get();

        if (!lookup.exists) {
          state.setPackerWorking(false);
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.bgGlassPanel,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppTheme.colorAmber)),
              title: const Text('Recipient Not Found', style: TextStyle(color: AppTheme.colorAmber, fontWeight: FontWeight.bold)),
              content: Text('The username "@$targetUser" is not currently registered on Firebase.\n\nThe receiver will have to create an account with username "@$targetUser" to open and decrypt the file.\n\nDo you want to proceed?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.fgMuted))),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('PROCEED ANYWAY', style: TextStyle(color: AppTheme.colorCyan, fontWeight: FontWeight.bold))),
              ],
            ),
          );

          if (proceed != true) return;
        }
      } catch (e) {
        state.setPackerWorking(false);
        // If offline or rule error, warn user
        _showDialog('Firebase Notice', 'Could not query Firestore cloud registry:\n$e\nContinuing packaging with target username "@$targetUser".', isError: false);
      }
    }

    DateTime? computedExpiry;
    if (_riggedTimeEnabled) {
      final amt = int.tryParse(_riggedDurationCtrl.text.trim()) ?? 30;
      final now = DateTime.now().toUtc();
      if (_durationUnit == 'MINUTES') computedExpiry = now.add(Duration(minutes: amt));
      if (_durationUnit == 'HOURS') computedExpiry = now.add(Duration(hours: amt));
      if (_durationUnit == 'DAYS') computedExpiry = now.add(Duration(days: amt));
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: 'Select PDF Document to Convert to .gdrm',
    );
    if (result == null || result.files.single.path == null) {
      state.setPackerWorking(false);
      return;
    }

    final pdfPath = result.files.single.path!;
    state.setPackerWorking(true);

    try {
      final pdfBytes = await File(pdfPath).readAsBytes();
      final baseFileName = p.basenameWithoutExtension(pdfPath);
      final deviceKey = await DeviceKeyService.getDeviceKey();
      final senderUser = state.cloudUsername ?? '';
      final senderEmail = state.cloudEmail ?? '';
      final senderName = state.cloudDisplayName ?? '';

      final packed = GdrmService.pack(
        pdfBytes: pdfBytes,
        licensedTo: licensedTo,
        copyrightOwner: copyright,
        memeSignature: meme,
        openAt: _chronoLockEnabled ? _openAt : null,
        senderUsername: senderUser,
        senderEmail: senderEmail,
        senderDisplayName: senderName,
        senderDeviceKey: deviceKey,
        password: _fileRipEnabled ? _passwordCtrl.text.trim() : '',
        maxAttempts: _fileRipEnabled ? (int.tryParse(_maxAttemptsCtrl.text.trim()) ?? 3) : 0,
        targetUsername: _cloudLockEnabled ? targetUser : '',
        riggedExpiry: computedExpiry,
        maxOpens: _riggedOpenEnabled ? (int.tryParse(_maxOpensCtrl.text.trim()) ?? 5) : 0,
        allowPrint: _allowPrint,
        membersOnly: _membersOnly,
      );

      // Save initial container to documents/temporary directory
      final appDir = await getApplicationDocumentsDirectory();
      final initialOutputPath = p.join(appDir.path, '$baseFileName.gdrm');
      await GdrmService.writeFile(initialOutputPath, packed);

      // If desktop, also write adjacent if possible
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        try {
          final adjacentPath = '${p.withoutExtension(pdfPath)}.gdrm';
          await GdrmService.writeFile(adjacentPath, packed);
        } catch (_) {}
      }

      final parsed = GdrmService.parse(packed);

      // Record initial PACKED event in Cloud Database Snail Trail
      PiracyService.recordDatabaseSnailTrail(
        fingerprint: parsed.metadata.fingerprint,
        action: 'PACKED',
        deviceKey: deviceKey,
        details: 'GDRM container packed and sealed by ${senderUser.isNotEmpty ? "@$senderUser" : copyright} for $licensedTo',
        senderUsername: senderUser,
        activeUsername: senderUser,
      );

      setState(() {
        _lastFingerprint = parsed.metadata.fingerprint;
        _lastOutputPath = initialOutputPath;
        _success = true;
      });

      state.setPackerWorking(false);

      if (!mounted) return;
      _showSaveAndShareModal(
        baseFileName: baseFileName,
        packedBytes: packed,
        parsed: parsed,
        initialPath: initialOutputPath,
      );
    } catch (e) {
      state.setPackerWorking(false);
      _showDialog('Runtime Error', e.toString(), isError: true);
    }
  }

  void _showSaveAndShareModal({
    required String baseFileName,
    required Uint8List packedBytes,
    required GdrmParseResult parsed,
    required String initialPath,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        String currentSavedPath = initialPath;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgGlassSidebar,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.colorCyan.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FILE CONVERTED & ENCRYPTED',
                                style: TextStyle(
                                  color: AppTheme.fgLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                '$baseFileName.gdrm',
                                style: const TextStyle(
                                  color: AppTheme.colorCyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.fgMuted, size: 20),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Summary Details Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgMain,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderGlass),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _summaryRow('Recipient Lock', _cloudLockEnabled && _targetUserCtrl.text.isNotEmpty ? '@${_targetUserCtrl.text.trim()}' : 'Public / Unbound', _cloudLockEnabled && _targetUserCtrl.text.isNotEmpty ? AppTheme.colorCyan : AppTheme.colorAmber),
                          _summaryRow('Fingerprint', parsed.metadata.fingerprint.length > 16 ? '${parsed.metadata.fingerprint.substring(0, 16)}...' : parsed.metadata.fingerprint, AppTheme.colorAmber, isMono: true),
                          _summaryRow('File Size', '${(packedBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB', AppTheme.fgLight),
                          if (_chronoLockEnabled && _openAt != null)
                            _summaryRow('ChronoLock', _formatOpenAt(_openAt!), AppTheme.colorAmber),
                          if (_fileRipEnabled)
                            _summaryRow('FileRip Protection', '${_maxAttemptsCtrl.text} Max Attempts', Colors.redAccent),
                          if (_riggedTimeEnabled || _riggedOpenEnabled)
                            _summaryRow('Self-Destruct Trigger', 'Armed', Colors.orangeAccent),
                          const Divider(color: AppTheme.borderGlass, height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.folder_outlined, color: AppTheme.fgMuted, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  currentSavedPath,
                                  style: const TextStyle(color: AppTheme.fgMuted, fontSize: 10, fontFamily: 'monospace'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: currentSavedPath));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppTheme.bgGlassPanel,
                                      content: Text('File path copied to clipboard', style: TextStyle(color: AppTheme.fgLight, fontSize: 12)),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.copy_rounded, color: AppTheme.colorCyan, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Actions: Save As & Share
                    Row(
                      children: [
                        // Save As / Location Picker
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.colorCyan.withOpacity(0.18),
                              foregroundColor: AppTheme.colorCyan,
                              elevation: 0,
                              side: const BorderSide(color: AppTheme.colorCyan, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.save_alt_rounded, size: 16),
                            label: const Text(
                              'SAVE TO FOLDER',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            onPressed: () async {
                              try {
                                final selectedPath = await FilePicker.platform.saveFile(
                                  dialogTitle: 'Select Where to Save GDRM File',
                                  fileName: '$baseFileName.gdrm',
                                  type: FileType.custom,
                                  allowedExtensions: ['gdrm'],
                                  bytes: packedBytes,
                                );
                                if (selectedPath != null && selectedPath.isNotEmpty) {
                                  final targetFile = File(selectedPath);
                                  if (!await targetFile.exists() || (await targetFile.length()) == 0) {
                                    await targetFile.writeAsBytes(packedBytes);
                                  }
                                  setModalState(() {
                                    currentSavedPath = selectedPath;
                                  });
                                  setState(() {
                                    _lastOutputPath = selectedPath;
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppTheme.bgGlassPanel,
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Saved to: ${p.basename(selectedPath)}',
                                                style: const TextStyle(color: AppTheme.fgLight, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.redAccent.withOpacity(0.8),
                                      content: Text('Save error: $e', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Share Button
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.colorMagenta.withOpacity(0.18),
                              foregroundColor: AppTheme.colorMagenta,
                              elevation: 0,
                              side: const BorderSide(color: AppTheme.colorMagenta, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 16),
                            label: const Text(
                              'SHARE FILE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            onPressed: () async {
                              try {
                                final recipient = _cloudLockEnabled && _targetUserCtrl.text.isNotEmpty
                                    ? '@${_targetUserCtrl.text.trim()}'
                                    : 'Public';
                                await Share.shareXFiles(
                                  [
                                    XFile(
                                      currentSavedPath,
                                      name: '$baseFileName.gdrm',
                                      mimeType: 'application/octet-stream',
                                    ),
                                  ],
                                  subject: 'Encrypted GDRM Container: $baseFileName.gdrm',
                                  text: 'Encrypted GDRM Document ($baseFileName.gdrm) for $recipient.\nFingerprint: ${parsed.metadata.fingerprint}',
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.redAccent.withOpacity(0.8),
                                      content: Text('Share error: $e', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Open in Reader Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.greenAccent,
                          side: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 16),
                        label: const Text(
                          'OPEN IN READER CONSOLE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          if (widget.onOpenInReader != null) {
                            widget.onOpenInReader!(currentSavedPath);
                          } else {
                            final state = context.read<AppState>();
                            state.switchView(AppView.reader);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, Color color, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.fgMuted, fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: isMono ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipientLockSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgGlassPanel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (_cloudLockEnabled || _membersOnly) ? AppTheme.colorCyan.withOpacity(0.6) : AppTheme.borderGlass,
          width: (_cloudLockEnabled || _membersOnly) ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Specific Username Lock
          Row(
            children: [
              Icon(
                Icons.lock_person_rounded,
                size: 18,
                color: _cloudLockEnabled ? AppTheme.colorCyan : AppTheme.fgMuted,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'SPECIFIC RECIPIENT USERNAME LOCK',
                  style: TextStyle(
                    color: AppTheme.fgLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Switch(
                value: _cloudLockEnabled,
                activeColor: AppTheme.colorCyan,
                onChanged: (v) => setState(() {
                  _cloudLockEnabled = v;
                  if (v) _membersOnly = false;
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Strict 1-to-1 lock: Only the user with this registered username handle can decrypt and view this document.',
            style: TextStyle(color: AppTheme.fgMuted, fontSize: 10.5),
          ),
          if (_cloudLockEnabled) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LabeledTextField(
                    label: 'Receiver Preferred Username',
                    controller: _targetUserCtrl,
                    hint: 'e.g. gaurav (without @)',
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.bgGlassSidebar,
                      foregroundColor: AppTheme.colorCyan,
                      side: const BorderSide(color: AppTheme.colorCyan),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onPressed: _isCheckingUser ? null : _verifyTargetUser,
                    child: _isCheckingUser
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.colorCyan),
                          )
                        : const Text('Verify User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            if (_userVerifyStatus != null) ...[
              const SizedBox(height: 6),
              Text(
                _userVerifyStatus!,
                style: TextStyle(
                  color: _userVerifyColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppTheme.borderGlass),
          ),

          // 2. GDRM Members Only Lock
          Row(
            children: [
              Icon(
                Icons.groups_rounded,
                size: 18,
                color: _membersOnly ? Colors.greenAccent : AppTheme.fgMuted,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ANY GDRM MEMBER (ACCOUNT REQUIRED)',
                  style: TextStyle(
                    color: AppTheme.fgLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Switch(
                value: _membersOnly,
                activeColor: Colors.greenAccent,
                onChanged: (v) => setState(() {
                  _membersOnly = v;
                  if (v) _cloudLockEnabled = false;
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Allows any user with a registered GDRM Ecosystem account to access and decrypt the file, regardless of their specific username handle.',
            style: TextStyle(
              color: _membersOnly ? Colors.greenAccent : AppTheme.fgMuted,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _riggedFileSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgGlassPanel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (_riggedTimeEnabled || _riggedOpenEnabled) ? AppTheme.colorMagenta.withOpacity(0.5) : AppTheme.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_rounded, size: 16, color: (_riggedTimeEnabled || _riggedOpenEnabled) ? AppTheme.colorMagenta : AppTheme.fgMuted),
              const SizedBox(width: 8),
              const Expanded(child: Text('RIGGEDFILE COUNTER & TIMERS', style: TextStyle(color: AppTheme.fgLight, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(value: _riggedTimeEnabled, activeColor: AppTheme.colorMagenta, onChanged: (v) => setState(() => _riggedTimeEnabled = v)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Enable Lifespan Time-Bomb (Melt)', style: TextStyle(color: AppTheme.fgLight, fontSize: 12))),
            ],
          ),
          if (_riggedTimeEnabled) ...[
            Row(
              children: [
                Expanded(child: LabeledTextField(label: 'Lifespan Duration Amount', controller: _riggedDurationCtrl, hint: 'e.g. 30')),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    const Text('TIME UNIT', style: TextStyle(color: AppTheme.fgMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: _durationUnit,
                      dropdownColor: AppTheme.bgGlassSidebar,
                      style: const TextStyle(color: AppTheme.colorCyan, fontSize: 13, fontWeight: FontWeight.bold),
                      items: ['MINUTES', 'HOURS', 'DAYS'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) => setState(() => _durationUnit = v ?? 'MINUTES'),
                    ),
                  ],
                ),
              ],
            ),
          ],
          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(color: AppTheme.borderGlass)),
          Row(
            children: [
              Switch(value: _riggedOpenEnabled, activeColor: AppTheme.colorMagenta, onChanged: (v) => setState(() => _riggedOpenEnabled = v)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Enable Max File Opening Ceiling Limit', style: TextStyle(color: AppTheme.fgLight, fontSize: 12))),
            ],
          ),
          if (_riggedOpenEnabled) ...[
            LabeledTextField(label: 'Max Opening Allowance Threshold', controller: _maxOpensCtrl, hint: 'e.g. 5'),
          ],
        ],
      ),
    );
  }

  Widget _fileRipSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgGlassPanel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _fileRipEnabled ? AppTheme.colorMagenta.withOpacity(0.5) : AppTheme.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gpp_maybe_rounded, size: 16, color: _fileRipEnabled ? AppTheme.colorMagenta : AppTheme.fgMuted),
              const SizedBox(width: 8),
              const Expanded(child: Text('FILERIP PASSWORD LAYER', style: TextStyle(color: AppTheme.fgLight, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
              Switch(value: _fileRipEnabled, activeColor: AppTheme.colorMagenta, onChanged: (v) => setState(() => _fileRipEnabled = v)),
            ],
          ),
          if (_fileRipEnabled) ...[
            LabeledTextField(label: 'Security Verification Password', controller: _passwordCtrl, hint: 'Unlock password'),
            LabeledTextField(label: 'Max Failure Entry Attempt Limit', controller: _maxAttemptsCtrl, hint: 'e.g. 3'),
          ],
        ],
      ),
    );
  }

  Widget _chronoLockSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgGlassPanel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _chronoLockEnabled ? AppTheme.colorAmber.withOpacity(0.5) : AppTheme.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_clock_rounded, size: 16, color: _chronoLockEnabled ? AppTheme.colorAmber : AppTheme.fgMuted),
              const SizedBox(width: 8),
              const Expanded(child: Text('CHRONOLOCK', style: TextStyle(color: AppTheme.fgLight, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
              Switch(value: _chronoLockEnabled, activeColor: AppTheme.colorAmber, onChanged: (v) => setState(() => _chronoLockEnabled = v)),
            ],
          ),
          if (_chronoLockEnabled) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickOpenAt,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppTheme.bgMain, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.borderGlass)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.colorAmber),
                    const SizedBox(width: 8),
                    Text(_openAt == null ? 'Set unlock date & time' : _formatOpenAt(_openAt!), style: TextStyle(color: _openAt == null ? AppTheme.fgMuted : AppTheme.colorAmber, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _printPermissionSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgGlassPanel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _allowPrint ? AppTheme.colorCyan.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _allowPrint ? Icons.print_rounded : Icons.print_disabled_rounded,
                size: 16,
                color: _allowPrint ? AppTheme.colorCyan : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PHYSICAL PRINTING PERMISSION',
                  style: TextStyle(
                    color: AppTheme.fgLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Switch(
                value: _allowPrint,
                activeColor: AppTheme.colorCyan,
                inactiveThumbColor: Colors.redAccent,
                inactiveTrackColor: Colors.redAccent.withOpacity(0.3),
                onChanged: (v) => setState(() => _allowPrint = v),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _allowPrint
                ? 'Authorized recipients can print watermarked examination / security copies on physical hardware printers.'
                : 'Physical printing is strictly prohibited. The Reader console will deny all print spooling requests.',
            style: TextStyle(
              color: _allowPrint ? AppTheme.fgMuted : Colors.redAccent.withOpacity(0.85),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(String title, String msg, {required bool isError}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgGlassPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isError ? Colors.redAccent : AppTheme.colorCyan)),
        title: Text(title, style: TextStyle(color: isError ? Colors.redAccent : AppTheme.colorCyan, fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(color: AppTheme.fgLight)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: AppTheme.colorCyan)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isWide = MediaQuery.of(context).size.width >= 720;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 16, vertical: isWide ? 0 : 24),
      child: Center(
        child: Container(
          width: 540,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.bgGlassSidebar,
            border: Border.all(color: AppTheme.borderGlass),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GDRM COMPREHENSIVE PACKER', style: TextStyle(color: AppTheme.fgLight, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 4),
              const Text('Convert PDF to encrypted .gdrm container with Receiver Username Lock', style: TextStyle(color: AppTheme.fgMuted, fontSize: 11)),
              const Divider(color: AppTheme.borderGlass, height: 24),
              
              // ── Recipient Lock Section ──
              _recipientLockSection(),
              const SizedBox(height: 14),

              LabeledTextField(label: 'Licensed Target Name / Recipient Name', controller: _licensedToCtrl, hint: 'e.g. Gaurav Sharma'),
              LabeledTextField(label: 'Legal Copyright Proprietor', controller: _copyrightCtrl, hint: 'e.g. Acme Corp / Author'),
              LabeledTextField(label: 'Signature Override Key', controller: _memeCtrl),
              const SizedBox(height: 14),
              _printPermissionSection(),
              const SizedBox(height: 14),
              _chronoLockSection(),
              const SizedBox(height: 14),
              _fileRipSection(),
              const SizedBox(height: 14),
              _riggedFileSection(),
              const SizedBox(height: 24),
              CyanActionButton(label: 'Select PDF & Compile .gdrm Container', onTap: _pack, isLoading: state.isPackerWorking),
            ],
          ),
        ),
      ),
    );
  }
}