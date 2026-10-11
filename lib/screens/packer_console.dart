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

class PackerConsole extends StatefulWidget {
  final void Function(String path)? onOpenInReader;

  const PackerConsole({super.key, this.onOpenInReader});

  @override
  State<PackerConsole> createState() => _PackerConsoleState();
}

enum PackerAccessMode {
  specificUser,
  membersOnly,
  openPublic,
}

class _PackerConsoleState extends State<PackerConsole> {
  final _licensedToCtrl = TextEditingController();
  final _copyrightCtrl = TextEditingController();
  final _memeCtrl = TextEditingController(text: 'SECURE_SIGNATURE_v1');
  
  // Recipient Access Control: Specific User, Any Member, or Public/Open
  PackerAccessMode _accessMode = PackerAccessMode.specificUser;
  final _targetUserCtrl = TextEditingController();
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
          colorScheme: ColorScheme.dark(
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
          colorScheme: ColorScheme.dark(
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

    if (_accessMode == PackerAccessMode.specificUser && targetUser.isEmpty) {
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

    // Verify recipient in Firestore if specific username lock is enabled
    if (_accessMode == PackerAccessMode.specificUser && targetUser.isNotEmpty) {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppTheme.colorAmber)),
              title: Text('Recipient Not Found', style: TextStyle(color: AppTheme.colorAmber, fontWeight: FontWeight.bold)),
              content: Text('The username "@$targetUser" is not currently registered on Firebase.\n\nThe receiver will have to create an account with username "@$targetUser" to open and decrypt the file.\n\nDo you want to proceed?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('CANCEL', style: TextStyle(color: AppTheme.fgMuted))),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('PROCEED ANYWAY', style: TextStyle(color: AppTheme.colorCyan, fontWeight: FontWeight.bold))),
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
        targetUsername: _accessMode == PackerAccessMode.specificUser ? targetUser : '',
        riggedExpiry: computedExpiry,
        maxOpens: _riggedOpenEnabled ? (int.tryParse(_maxOpensCtrl.text.trim()) ?? 5) : 0,
        allowPrint: _allowPrint,
        membersOnly: _accessMode == PackerAccessMode.membersOnly,
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
                border: Border.all(color: AppTheme.colorCyan.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
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
                            color: Colors.greenAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
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
                                style: TextStyle(
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
                          icon: Icon(Icons.close_rounded, color: AppTheme.fgMuted, size: 20),
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
                          _summaryRow(
                            'Recipient Lock',
                            _accessMode == PackerAccessMode.specificUser && _targetUserCtrl.text.isNotEmpty
                                ? '@${_targetUserCtrl.text.trim()}'
                                : (_accessMode == PackerAccessMode.membersOnly ? 'Registered members' : 'Public / Unbound'),
                            _accessMode == PackerAccessMode.openPublic
                                ? AppTheme.colorAmber
                                : (AppTheme.isDark ? AppTheme.darkPrimaryGreen : AppTheme.lightPrimaryGreen),
                          ),
                          _summaryRow('Fingerprint', parsed.metadata.fingerprint.length > 16 ? '${parsed.metadata.fingerprint.substring(0, 16)}...' : parsed.metadata.fingerprint, AppTheme.colorAmber, isMono: true),
                          _summaryRow('File Size', '${(packedBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB', AppTheme.fgLight),
                          if (_chronoLockEnabled && _openAt != null)
                            _summaryRow('ChronoLock', _formatOpenAt(_openAt!), AppTheme.colorAmber),
                          if (_fileRipEnabled)
                            _summaryRow('FileRip Protection', '${_maxAttemptsCtrl.text} Max Attempts', Colors.redAccent),
                          if (_riggedTimeEnabled || _riggedOpenEnabled)
                            _summaryRow('Self-Destruct Trigger', 'Armed', Colors.orangeAccent),
                          Divider(color: AppTheme.borderGlass, height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.folder_outlined, color: AppTheme.fgMuted, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  currentSavedPath,
                                  style: TextStyle(color: AppTheme.fgMuted, fontSize: 10, fontFamily: 'monospace'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: currentSavedPath));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppTheme.bgGlassPanel,
                                      content: Text('File path copied to clipboard', style: TextStyle(color: AppTheme.fgLight, fontSize: 12)),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6),
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
                              backgroundColor: AppTheme.colorCyan.withValues(alpha: 0.18),
                              foregroundColor: AppTheme.colorCyan,
                              elevation: 0,
                              side: BorderSide(color: AppTheme.colorCyan, width: 1.2),
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
                                                style: TextStyle(color: AppTheme.fgLight, fontSize: 12),
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
                                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
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
                              backgroundColor: AppTheme.colorMagenta.withValues(alpha: 0.18),
                              foregroundColor: AppTheme.colorMagenta,
                              elevation: 0,
                              side: BorderSide(color: AppTheme.colorMagenta, width: 1.2),
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
                                final recipient = _accessMode == PackerAccessMode.specificUser && _targetUserCtrl.text.isNotEmpty
                                    ? '@${_targetUserCtrl.text.trim()}'
                                    : (_accessMode == PackerAccessMode.membersOnly ? 'Registered members' : 'Public');
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
                                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
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
                          side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.5)),
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
          Text(label, style: TextStyle(color: AppTheme.fgMuted, fontSize: 11)),
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



  void _showDialog(String title, String msg, {required bool isError}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgGlassPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isError ? Colors.redAccent : AppTheme.colorCyan)),
        title: Text(title, style: TextStyle(color: isError ? Colors.redAccent : AppTheme.colorCyan, fontWeight: FontWeight.bold)),
        content: Text(msg, style: TextStyle(color: AppTheme.fgLight)),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text('OK', style: TextStyle(color: AppTheme.colorCyan)))],
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    VoidCallback? onEditingComplete,
    Widget? statusWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.fgLight,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onEditingComplete: onEditingComplete,
          style: TextStyle(color: AppTheme.fgLight, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.fgMuted, fontSize: 13),
            filled: true,
            fillColor: AppTheme.bgGlassPanel,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppTheme.borderGlass),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppTheme.borderGlass),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppTheme.primaryGreen, width: 1.5),
            ),
          ),
        ),
        if (statusWidget != null) ...[
          const SizedBox(height: 4),
          statusWidget,
        ],
      ],
    );
  }

  Widget _accessOptionTile({
    required PackerAccessMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? expandedChild,
  }) {
    final isSelected = _accessMode == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? (AppTheme.isDark ? const Color(0xFF1B201E) : const Color(0xFFEDF4F0))
              : AppTheme.bgGlassPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGlass,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _accessMode = mode;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 18,
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.fgMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 15, color: isSelected ? AppTheme.primaryGreen : AppTheme.fgMuted),
                              const SizedBox(width: 6),
                              Text(
                                title,
                                style: TextStyle(
                                  color: AppTheme.fgLight,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: AppTheme.fgMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected && expandedChild != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: expandedChild,
              ),
          ],
        ),
      ),
    );
  }

  Widget _checkboxOption({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool?> onChanged,
    Widget? expandedChild,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: value,
                      activeColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: BorderSide(color: AppTheme.borderGlass, width: 1.5),
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppTheme.fgLight,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppTheme.fgMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (value && expandedChild != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 8),
              child: expandedChild,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isWide = MediaQuery.of(context).size.width >= 720;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 16, vertical: 36),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (Page 2 & Page 5) ──
              Text(
                'Packer',
                style: TextStyle(
                  color: AppTheme.fgLight,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Convert a PDF into a protected .gdrm file.',
                style: TextStyle(
                  color: AppTheme.fgMuted,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── Access Protection Mode Selector ──
              Text(
                'Access protection',
                style: TextStyle(
                  color: AppTheme.fgLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose who has the right to open and decrypt this document.',
                style: TextStyle(
                  color: AppTheme.fgMuted,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),

              // Option 1: Specific Username Lock
              _accessOptionTile(
                mode: PackerAccessMode.specificUser,
                title: 'Lock to specific username',
                subtitle: 'Only this registered username handle can decrypt and view the document.',
                icon: Icons.person_rounded,
                expandedChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: AppTheme.borderGlass, height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _targetUserCtrl,
                            onEditingComplete: _verifyTargetUser,
                            style: TextStyle(color: AppTheme.fgLight, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'e.g. gaurav (without @)',
                              hintStyle: TextStyle(color: AppTheme.fgMuted, fontSize: 12.5),
                              filled: true,
                              fillColor: AppTheme.bgMain,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppTheme.borderGlass)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppTheme.primaryGreen, width: 1.5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: _isCheckingUser ? null : _verifyTargetUser,
                          child: _isCheckingUser
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Verify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (_userVerifyStatus != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _userVerifyStatus!,
                        style: TextStyle(color: _userVerifyColor, fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),

              // Option 2: Any Registered Member
              _accessOptionTile(
                mode: PackerAccessMode.membersOnly,
                title: 'Any registered GDRM member',
                subtitle: 'Any authenticated user with an account can open. Public access blocked.',
                icon: Icons.groups_rounded,
              ),

              // Option 3: Public / Open File
              _accessOptionTile(
                mode: PackerAccessMode.openPublic,
                title: 'Public / Open file (No account)',
                subtitle: 'No username restriction or account required. Anyone with GDRM can open.',
                icon: Icons.public_rounded,
              ),

              const SizedBox(height: 18),

              // ── Metadata Text Fields ──
              _labeledField(
                label: 'Recipient name',
                controller: _licensedToCtrl,
                hint: 'e.g. Gaurav Sharma',
              ),
              const SizedBox(height: 18),

              _labeledField(
                label: 'Copyright owner',
                controller: _copyrightCtrl,
                hint: 'Gaurang Dalal (@gauruu)',
              ),
              const SizedBox(height: 24),

              _checkboxOption(
                value: _allowPrint,
                title: 'Allow printing',
                subtitle: 'Recipient may print watermarked copies.',
                onChanged: (v) => setState(() => _allowPrint = v ?? false),
              ),

              _checkboxOption(
                value: _chronoLockEnabled,
                title: 'ChronoLock unlock timer',
                subtitle: 'File stays locked until a designated future date and time.',
                onChanged: (v) => setState(() => _chronoLockEnabled = v ?? false),
                expandedChild: GestureDetector(
                  onTap: _pickOpenAt,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgMain,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderGlass),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          _openAt == null ? 'Set unlock date & time' : _formatOpenAt(_openAt!),
                          style: TextStyle(
                            color: _openAt == null ? AppTheme.fgMuted : AppTheme.fgLight,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              _checkboxOption(
                value: _riggedTimeEnabled,
                title: 'Expiry timer',
                subtitle: 'File becomes unreadable after a set time.',
                onChanged: (v) => setState(() => _riggedTimeEnabled = v ?? false),
                expandedChild: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _riggedDurationCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AppTheme.fgLight, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Duration',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _durationUnit,
                      dropdownColor: AppTheme.bgGlassPanel,
                      style: TextStyle(color: AppTheme.fgLight, fontSize: 12.5, fontWeight: FontWeight.w600),
                      items: ['MINUTES', 'HOURS', 'DAYS'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) => setState(() => _durationUnit = v ?? 'MINUTES'),
                    ),
                  ],
                ),
              ),

              _checkboxOption(
                value: _riggedOpenEnabled,
                title: 'Open limit',
                subtitle: 'Limit how many times the file can be opened.',
                onChanged: (v) => setState(() => _riggedOpenEnabled = v ?? false),
                expandedChild: TextField(
                  controller: _maxOpensCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppTheme.fgLight, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Max open limit (e.g. 5)',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Action Button (Page 2 & Page 5) ──
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  minimumSize: const Size(double.infinity, 46),
                ),
                onPressed: state.isPackerWorking ? null : _pack,
                child: state.isPackerWorking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Choose PDF and create .gdrm',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}