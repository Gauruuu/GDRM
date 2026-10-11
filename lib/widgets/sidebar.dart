import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../screens/global_auth_screen.dart';
import 'account_profile_dialog.dart';
import 'shared_widgets.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Determine current user display info
    final isAuthenticated = state.isCloudAuthenticated;
    final displayName = isAuthenticated
        ? (state.cloudDisplayName?.isNotEmpty == true
            ? state.cloudDisplayName!
            : state.cloudUsername!)
        : 'Guest User';
    final username = isAuthenticated
        ? '@${state.cloudUsername!}'
        : 'Sign In / Register';
    final initial = isAuthenticated
        ? (displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U')
        : '?';

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppTheme.bgGlassSidebar,
        border: Border(
          right: BorderSide(color: AppTheme.borderGlass, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: GDRM V — The Milky Way Update ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const GdrmVLogoBadge(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'GDRM',
                            style: TextStyle(
                              color: AppTheme.fgLight,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6)),
                            ),
                            child: const Text(
                              'V',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'THE MILKY WAY',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Document rights manager',
                        style: TextStyle(
                          color: AppTheme.fgMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Navigation Items ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _SidebarNavItem(
                  label: 'Reader',
                  isActive: state.currentView == AppView.reader,
                  onTap: () => state.switchView(AppView.reader),
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  label: 'Packer',
                  isActive: state.currentView == AppView.packer,
                  onTap: () => state.switchView(AppView.packer),
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  label: 'Tracked files',
                  isActive: state.currentView == AppView.trackedFiles,
                  onTap: () => state.switchView(AppView.trackedFiles),
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  label: 'Alerts',
                  isActive: state.currentView == AppView.alerts,
                  badgeCount: state.unreadPiracyAlertsCount,
                  onTap: () => state.switchView(AppView.alerts),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Bottom Profile Section ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (state.isCloudAuthenticated) {
                    showAccountProfileDialog(context);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GlobalAuthScreen()),
                    );
                  }
                },
                hoverColor: AppTheme.borderGlass.withValues(alpha: 0.35),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      // Circular Avatar (matches screenshot)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.isDark
                              ? AppTheme.darkPrimaryGreen.withValues(alpha: 0.25)
                              : const Color(0xFF163E2E),
                          border: AppTheme.isDark
                              ? Border.all(color: AppTheme.darkPrimaryGreen.withValues(alpha: 0.5), width: 1)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: AppTheme.isDark ? AppTheme.darkPrimaryGreen : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                color: AppTheme.fgLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              username,
                              style: TextStyle(
                                color: AppTheme.fgMuted,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Theme Switch Quick Toggle
                      IconButton(
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        splashRadius: 16,
                        tooltip: state.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        icon: Icon(
                          state.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          color: AppTheme.fgMuted,
                        ),
                        onPressed: () => state.toggleTheme(),
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

class _SidebarNavItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _SidebarNavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppTheme.navActiveBg : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: isActive
            ? null
            : AppTheme.borderGlass.withValues(alpha: 0.35),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? AppTheme.navActiveFg : AppTheme.fgLight,
                    fontSize: 13.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

/// Kept for compatibility with mobile drawer
class UserAuthBadge extends StatelessWidget {
  final AppState state;

  const UserAuthBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = state.isCloudAuthenticated;
    final displayName = isAuthenticated
        ? (state.cloudDisplayName?.isNotEmpty == true
            ? state.cloudDisplayName!
            : state.cloudUsername!)
        : 'Guest User';
    final username = isAuthenticated
        ? '@${state.cloudUsername!}'
        : 'Sign In / Register';
    final initial = isAuthenticated
        ? (displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U')
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showAccountProfileDialog(context),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.navActiveBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderGlass),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.isDark ? AppTheme.darkPrimaryGreen : const Color(0xFF163E2E),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: AppTheme.fgLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      username,
                      style: TextStyle(
                        color: AppTheme.fgMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}