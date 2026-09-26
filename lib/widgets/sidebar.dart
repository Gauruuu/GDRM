import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';
import 'account_profile_dialog.dart';
import '../screens/snail_trail_screen.dart';
import '../screens/global_auth_screen.dart';
import '../screens/piracy_alerts_screen.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: AppTheme.bgGlassSidebar,
        border: Border(right: BorderSide(color: AppTheme.borderGlass)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 2),
            child: Text(
              'GDRM ECOSYSTEM',
              style: TextStyle(
                  color: AppTheme.fgLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Text('Custom Digital Right Manager',
                style: TextStyle(color: AppTheme.fgMuted, fontSize: 11)),
          ),
          NavButton(
            label: 'READER CONSOLE',
            active: state.currentView == AppView.reader,
            onTap: () => state.switchView(AppView.reader),
          ),
          NavButton(
            label: 'PACKER CONSOLE',
            active: state.currentView == AppView.packer,
            onTap: () => state.switchView(AppView.packer),
          ),
          
          // ── User Identity & Firebase Auth Badge ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: UserAuthBadge(state: state),
          ),

          // ── Piracy & Security Alerts Quick Trigger ──
          if (state.isCloudAuthenticated)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PiracyAlertsScreen(senderUsername: state.cloudUsername!),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: state.unreadPiracyAlertsCount > 0
                        ? Colors.redAccent.withOpacity(0.12)
                        : AppTheme.bgGlassPanel,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: state.unreadPiracyAlertsCount > 0
                          ? Colors.redAccent.withOpacity(0.6)
                          : AppTheme.borderGlass,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.unreadPiracyAlertsCount > 0
                            ? Icons.warning_amber_rounded
                            : Icons.shield_outlined,
                        color: state.unreadPiracyAlertsCount > 0
                            ? Colors.redAccent
                            : AppTheme.colorCyan,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PIRACY & ALERTS',
                          style: TextStyle(
                            color: state.unreadPiracyAlertsCount > 0
                                ? Colors.redAccent
                                : AppTheme.fgLight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (state.unreadPiracyAlertsCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.unreadPiracyAlertsCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Divider(color: AppTheme.borderGlass, height: 1),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ACTIVE SYSTEM MANIFEST',
                      style: TextStyle(
                          color: AppTheme.fgMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  ManifestIndicator(
                      title: 'Licensed To', value: state.manifest.licensedTo),
                  ManifestIndicator(
                      title: 'Copyright Owner',
                      value: state.manifest.copyrightOwner),
                  ManifestIndicator(
                      title: 'Fingerprint',
                      value: state.manifest.fingerprint,
                      valueColor: AppTheme.colorAmber,
                      isMono: true),
                  ManifestIndicator(
                      title: 'Signature',
                      value: state.manifest.memeSignature,
                      valueColor: AppTheme.colorMagenta),
                  const Divider(color: AppTheme.borderGlass),

                  if (state.manifest.trailLogs.isNotEmpty) ...[
                    const Text(
                      'FILE AUDIT MATRIX',
                      style: TextStyle(
                          color: AppTheme.fgMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SnailTrailScreen(
                              logs: state.manifest.trailLogs,
                              fileFingerprint: state.manifest.fingerprint,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgGlassPanel,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppTheme.colorCyan.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined,
                                color: AppTheme.colorCyan, size: 14),
                            SizedBox(width: 8),
                            Text(
                              'VIEW SNAILTRAIL LOGS',
                              style: TextStyle(
                                  color: AppTheme.colorCyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: AppTheme.borderGlass, height: 1),
                    ),
                  ],

                  const Text('DRM BINDING',
                      style: TextStyle(
                          color: AppTheme.fgMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  ManifestIndicator(
                      title: 'Sender Token',
                      value: state.manifest.sender.isEmpty
                          ? '---'
                          : state.manifest.sender.substring(0, 16) + '...',
                      valueColor: AppTheme.colorCyan,
                      isMono: true),
                  ManifestIndicator(
                      title: 'Receiver Lock',
                      value: state.manifest.hasCloudLock
                          ? '@${state.manifest.targetUsername}'
                          : (state.manifest.hasMembersOnlyLock
                              ? 'MEMBERS ONLY'
                              : (state.manifest.receiver.isEmpty
                                  ? 'UNBOUND'
                                  : '${state.manifest.receiver.substring(0, 16)}...')),
                      valueColor: state.manifest.hasCloudLock
                          ? AppTheme.colorCyan
                          : (state.manifest.hasMembersOnlyLock
                              ? Colors.greenAccent
                              : (state.manifest.receiver.isEmpty
                                  ? AppTheme.colorAmber
                                  : Colors.greenAccent)),
                      isMono: true),
                  ManifestIndicator(
                      title: 'Print Permission',
                      value: state.manifest.allowPrint ? 'PERMITTED' : 'RESTRICTED',
                      valueColor: state.manifest.allowPrint
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      isMono: true),
                  const SizedBox(height: 8),
                  _DrmStatusChip(meta: state.manifest),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('GDRM Document Protection Ecosystem',
                style: TextStyle(color: AppTheme.footerGray, fontSize: 9)),
          ),
        ],
      ),
    );
  }
}

class UserAuthBadge extends StatelessWidget {
  final AppState state;

  const UserAuthBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isCloudAuthenticated) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showAccountProfileDialog(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.colorCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.colorCyan.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.colorCyan.withValues(alpha: 0.25),
                  child: Text(
                    state.cloudDisplayName?.isNotEmpty == true
                        ? state.cloudDisplayName![0].toUpperCase()
                        : (state.cloudUsername?.isNotEmpty == true
                            ? state.cloudUsername![0].toUpperCase()
                            : 'U'),
                    style: const TextStyle(
                      color: AppTheme.colorCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.cloudDisplayName?.isNotEmpty == true
                            ? state.cloudDisplayName!
                            : state.cloudUsername!,
                        style: const TextStyle(
                          color: AppTheme.fgLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${state.cloudUsername}',
                        style: const TextStyle(
                          color: AppTheme.colorCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Tooltip(
                  message: 'Manage Account (Verify Email, Delete Account)',
                  child: Icon(Icons.manage_accounts_rounded, color: AppTheme.colorCyan, size: 18),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GlobalAuthScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.bgGlassPanel,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.colorCyan.withOpacity(0.35)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login_rounded, color: AppTheme.colorCyan, size: 14),
              SizedBox(width: 6),
              Text(
                'SIGN IN / REGISTER',
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
      );
    }
  }
}

class _DrmStatusChip extends StatelessWidget {
  final dynamic meta;
  const _DrmStatusChip({required this.meta});

  @override
  Widget build(BuildContext context) {
    final bool hasSecurity = meta.hasSecurity as bool;
    final bool hasReceiver = meta.hasReceiver as bool;

    final Color color;
    final String label;
    final IconData icon;

    if (!hasSecurity) {
      color = AppTheme.fgMuted;
      label = 'LEGACY FILE';
      icon = Icons.lock_open_rounded;
    } else if (!hasReceiver) {
      color = AppTheme.colorAmber;
      label = 'UNBOUND';
      icon = Icons.lock_clock_rounded;
    } else {
      color = Colors.greenAccent;
      label = 'LOCKED & BOUND';
      icon = Icons.verified_user_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.35))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}