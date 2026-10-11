import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/file_intent_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/account_profile_dialog.dart';
import 'reader_console.dart';
import 'packer_console.dart';
import 'global_auth_screen.dart';
import 'snail_trail_screen.dart';
import 'piracy_alerts_screen.dart';
import 'composer_audit_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  StreamSubscription<String>? _fileSub;
  // Key lets us call openFileFromPath on the reader
  final GlobalKey<ReaderConsoleState> _readerKey = GlobalKey();
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _fileSub = FileIntentService.onFileReceived.listen(_onIncomingFile);
    final pending = FileIntentService.consumePendingInitialFile();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onIncomingFile(pending);
      });
    }
  }

  @override
  void dispose() {
    _fileSub?.cancel();
    super.dispose();
  }

  void _onIncomingFile(String pathOrUri) {
    // Switch to reader tab first
    context.read<AppState>().switchView(AppView.reader);

    // Wait until ReaderConsoleState is mounted and ready
    void tryOpen(int attemptsLeft) {
      if (_readerKey.currentState != null) {
        _readerKey.currentState?.openFileFromPath(pathOrUri);
      } else if (attemptsLeft > 0) {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) tryOpen(attemptsLeft - 1);
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tryOpen(20));
  }

  void _handleDropDone(DropDoneDetails details) async {
    setState(() => _isDragging = false);
    if (details.files.isNotEmpty) {
      final firstFile = details.files.first;
      final path = firstFile.path;
      if (path.toLowerCase().endsWith('.gdrm')) {
        _onIncomingFile(path);
      } else if (path.toLowerCase().endsWith('.pdf')) {
        // Switch to packer console or reader
        context.read<AppState>().switchView(AppView.packer);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.bgGlassPanel,
            content: Text('PDF ready for packaging: $path', style: TextStyle(color: AppTheme.colorCyan)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.bgGlassPanel,
            content: const Text('Unsupported file format. Please drop a .gdrm or .pdf document.', style: TextStyle(color: Colors.redAccent)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final state = context.watch<AppState>();

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: _handleDropDone,
      child: Stack(
        children: [
          if (isWide)
            Scaffold(
              backgroundColor: AppTheme.bgMain,
              body: Row(
                children: [
                  const AppSidebar(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: state.currentView == AppView.reader
                          ? ReaderConsole(key: _readerKey)
                          : PackerConsole(
                              key: const ValueKey('packer'),
                              onOpenInReader: _onIncomingFile,
                            ),
                    ),
                  ),
                ],
              ),
            )
          else
            Scaffold(
              backgroundColor: AppTheme.bgMain,
              appBar: AppBar(
                backgroundColor: AppTheme.bgGlassSidebar,
                elevation: 0,
                titleSpacing: 16,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GDRM ECOSYSTEM',
                        style: TextStyle(
                            color: AppTheme.fgLight,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1)),
                    Text('Custom Digital Right Manager',
                        style: TextStyle(color: AppTheme.fgMuted, fontSize: 10)),
                  ],
                ),
                actions: [
                  // Theme toggle button for mobile
                  IconButton(
                    icon: Icon(
                      state.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: state.isDarkMode ? AppTheme.colorCyan : AppTheme.colorAmber,
                      size: 20,
                    ),
                    onPressed: () => state.toggleTheme(),
                    tooltip: state.isDarkMode ? 'Switch to Light Theme' : 'Switch to Dark Theme',
                  ),
                  // Track Packaged Files for Composer
                  IconButton(
                    icon: Icon(Icons.hub_outlined, color: AppTheme.colorCyan, size: 20),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ComposerAuditScreen()),
                      );
                    },
                    tooltip: 'Composer File Tracking Matrix',
                  ),
                  // ── Mobile Auth Badge Action ──
                  if (state.isCloudAuthenticated) ...[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            state.unreadPiracyAlertsCount > 0
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_none_rounded,
                            color: state.unreadPiracyAlertsCount > 0
                                ? Colors.redAccent
                                : AppTheme.fgLight,
                            size: 20,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PiracyAlertsScreen(senderUsername: state.cloudUsername!),
                              ),
                            );
                          },
                          tooltip: 'Security & Piracy Alerts',
                        ),
                        if (state.unreadPiracyAlertsCount > 0)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${state.unreadPiracyAlertsCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => showAccountProfileDialog(context),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.colorCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.colorCyan.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: AppTheme.colorCyan.withValues(alpha: 0.3),
                              child: Text(
                                state.cloudUsername?.isNotEmpty == true
                                    ? state.cloudUsername![0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: AppTheme.colorCyan,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '@${state.cloudUsername}',
                              style: TextStyle(
                                color: AppTheme.colorCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GlobalAuthScreen()),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.colorCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.colorCyan.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login_rounded, color: AppTheme.colorCyan, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppTheme.colorCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Builder(
                    builder: (ctx) => IconButton(
                      icon: Icon(Icons.info_outline,
                          color: AppTheme.fgMuted, size: 20),
                      onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                      tooltip: 'System Manifest',
                    ),
                  ),
                ],
              ),
              endDrawer: const _ManifestDrawer(),
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: state.currentView == AppView.reader
                    ? ReaderConsole(key: _readerKey)
                    : PackerConsole(
                        key: const ValueKey('packer'),
                        onOpenInReader: _onIncomingFile,
                      ),
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgGlassSidebar,
                  border: Border(top: BorderSide(color: AppTheme.borderGlass)),
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: AppTheme.colorCyan,
                  unselectedItemColor: AppTheme.fgMuted,
                  currentIndex: state.currentView == AppView.reader ? 0 : 1,
                  onTap: (i) =>
                      state.switchView(i == 0 ? AppView.reader : AppView.packer),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.menu_book_outlined),
                      activeIcon: Icon(Icons.menu_book),
                      label: 'Reader',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2_outlined),
                      activeIcon: Icon(Icons.inventory_2),
                      label: 'Packer',
                    ),
                  ],
                ),
              ),
            ),

          // ── Window-wide Drag & Drop Overlay ──
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: AppTheme.bgMain.withValues(alpha: 0.90),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 42),
                    decoration: BoxDecoration(
                      color: AppTheme.bgGlassPanel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.colorCyan, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.colorCyan.withValues(alpha: 0.35),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_download_outlined, color: AppTheme.colorCyan, size: 64),
                        const SizedBox(height: 18),
                        Text(
                          'DROP CONTAINER ANYWHERE',
                          style: TextStyle(
                            color: AppTheme.colorCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Release file to decrypt, verify, and view automatically',
                          style: TextStyle(color: AppTheme.fgLight, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ManifestDrawer extends StatelessWidget {
  const _ManifestDrawer();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final m = state.manifest;

    return Drawer(
      backgroundColor: AppTheme.bgGlassSidebar,
      width: 280,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Mobile Auth Badge in Drawer ──
              UserAuthBadge(state: state),
              const SizedBox(height: 14),

              // ── Track Packaged Files for Composer ──
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ComposerAuditScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.colorCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.colorCyan.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hub_outlined, color: AppTheme.colorCyan, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'TRACK PACKAGED FILES',
                        style: TextStyle(
                          color: AppTheme.colorCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Divider(color: AppTheme.borderGlass),
              const SizedBox(height: 8),

              Text('ACTIVE SYSTEM MANIFEST',
                  style: TextStyle(
                      color: AppTheme.fgMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8)),
              const SizedBox(height: 14),
              _row('Licensed To', m.licensedTo, AppTheme.fgLight),
              _row('Copyright Owner', m.copyrightOwner, AppTheme.fgLight),
              _row('Fingerprint', m.fingerprint, AppTheme.colorAmber, mono: true),
              _row('Signature', m.memeSignature, AppTheme.colorMagenta),
              Divider(color: AppTheme.borderGlass),
              _row('Sender Token',
                  m.sender.isEmpty ? '---' : '${m.sender.substring(0, 16)}...',
                  AppTheme.colorCyan, mono: true),
              _row(
                  'Receiver Lock',
                  m.hasCloudLock
                      ? '@${m.targetUsername}'
                      : (m.hasMembersOnlyLock
                          ? 'MEMBERS ONLY'
                          : (m.receiver.isEmpty
                              ? 'UNBOUND'
                              : '${m.receiver.substring(0, 16)}...')),
                  m.hasCloudLock
                      ? AppTheme.colorCyan
                      : (m.hasMembersOnlyLock
                          ? Colors.greenAccent
                          : (m.receiver.isEmpty
                              ? AppTheme.colorAmber
                              : Colors.greenAccent)),
                  mono: true),
              _row('Print Permission',
                  m.allowPrint ? 'PERMITTED' : 'RESTRICTED',
                  m.allowPrint ? Colors.greenAccent : Colors.redAccent,
                  mono: true),
              if (m.hasChronoLock) ...[
                Divider(color: AppTheme.borderGlass),
                _row('ChronoLock',
                    m.openAtDateTime != null
                        ? m.openAtDateTime!.toLocal().toString().substring(0, 16)
                        : '---',
                    m.isTimeLocked ? AppTheme.colorAmber : Colors.greenAccent),
              ],
              if (m.trailLogs.isNotEmpty) ...[
                Divider(color: AppTheme.borderGlass),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SnailTrailScreen(
                          logs: m.trailLogs,
                          fileFingerprint: m.fingerprint,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgGlassPanel,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.colorCyan.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, color: AppTheme.colorCyan, size: 13),
                        const SizedBox(width: 6),
                        Text(
                          'VIEW AUDIT TRAIL',
                          style: TextStyle(
                            color: AppTheme.colorCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text('GDRM Document Protection Ecosystem',
                  style: TextStyle(color: AppTheme.footerGray, fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String title, String value, Color color, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title:',
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: mono ? FontWeight.normal : FontWeight.bold,
                  fontFamily: mono ? 'monospace' : null)),
        ],
      ),
    );
  }
}
