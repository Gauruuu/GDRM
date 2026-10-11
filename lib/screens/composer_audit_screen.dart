import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'snail_trail_screen.dart';
import 'global_auth_screen.dart';

class ComposerAuditScreen extends StatefulWidget {
  final String? initialSearchFingerprint;

  const ComposerAuditScreen({super.key, this.initialSearchFingerprint});

  @override
  State<ComposerAuditScreen> createState() => _ComposerAuditScreenState();
}

class _ComposerAuditScreenState extends State<ComposerAuditScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchFingerprint != null) {
      _searchCtrl.text = widget.initialSearchFingerprint!;
      _filterQuery = widget.initialSearchFingerprint!.trim().toLowerCase();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currentUser = state.cloudUsername;

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        backgroundColor: AppTheme.bgGlassSidebar,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.fgLight, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COMPOSER FILE AUDIT MATRIX',
              style: TextStyle(
                color: AppTheme.fgLight,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              currentUser != null
                  ? 'Tracking packaged files created by @$currentUser'
                  : 'GDRM Cloud Container Telemetry Registry',
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 10),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppTheme.colorCyan, size: 20),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh Registry',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgGlassSidebar,
              border: Border(bottom: BorderSide(color: AppTheme.borderGlass)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _filterQuery = val.trim().toLowerCase()),
                    style: TextStyle(color: AppTheme.fgLight, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search container hash, fingerprint, or recipient...',
                      hintStyle: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, color: AppTheme.colorCyan, size: 18),
                      suffixIcon: _filterQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppTheme.fgMuted, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _filterQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.bgGlassPanel,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderGlass),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderGlass),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.colorCyan),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Main Content / Query Stream ──
          Expanded(
            child: !state.isCloudAuthenticated && _filterQuery.isEmpty
                ? _buildUnauthenticatedPrompt()
                : _buildFilesList(currentUser),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_person_outlined, size: 56, color: AppTheme.colorCyan),
            const SizedBox(height: 16),
            Text(
              'Sign In to Track Packaged Files',
              style: TextStyle(color: AppTheme.fgLight, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with your GDRM account to automatically view real-time audit logs, telemetry, and recipient activity for all files you compose.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text('SIGN IN / REGISTER', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GlobalAuthScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList(String? currentUser) {
    Query query = FirebaseFirestore.instance.collection('gdrm_snail_trails');

    if (currentUser != null && _filterQuery.isEmpty) {
      final cleanUser = currentUser.trim().toLowerCase().replaceAll('@', '');
      query = query.where('senderUsername', isEqualTo: cleanUser);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.colorCyan));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 40),
                  const SizedBox(height: 12),
                  Text('Telemetry Stream Error',
                      style: TextStyle(color: AppTheme.fgLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('${snapshot.error}',
                      style: TextStyle(color: AppTheme.fgMuted, fontSize: 11),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final filteredDocs = docs.where((doc) {
          if (_filterQuery.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final fp = (data['fingerprint'] ?? doc.id).toString().toLowerCase();
          final sender = (data['senderUsername'] ?? '').toString().toLowerCase();
          final lastAction = (data['lastAction'] ?? '').toString().toLowerCase();
          return fp.contains(_filterQuery) || sender.contains(_filterQuery) || lastAction.contains(_filterQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 52, color: AppTheme.borderGlass),
                  const SizedBox(height: 14),
                  Text(
                    _filterQuery.isNotEmpty
                        ? 'No Packaged Files Match "$_filterQuery"'
                        : 'No Packaged Files Recorded Yet',
                    style: TextStyle(color: AppTheme.fgLight, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'When you package and distribute .gdrm containers, live telemetry and recipient audit logs will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final fingerprint = data['fingerprint'] ?? doc.id;
            final lastAction = data['lastAction'] ?? 'UNKNOWN';
            final lastDeviceKey = data['lastDeviceKey'] ?? '---';
            final senderUsername = data['senderUsername'] ?? '';

            DateTime? lastUpdated;
            if (data['lastUpdated'] is Timestamp) {
              lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
            } else if (data['lastUpdated'] is String) {
              lastUpdated = DateTime.tryParse(data['lastUpdated'] as String);
            }

            final formattedDate = lastUpdated != null
                ? DateFormat('dd MMM yyyy • HH:mm:ss').format(lastUpdated.toLocal())
                : 'Unknown';

            Color statusColor = AppTheme.colorCyan;
            IconData statusIcon = Icons.inventory_2_outlined;

            if (lastAction == 'OPENED') {
              statusColor = Colors.greenAccent;
              statusIcon = Icons.lock_open_rounded;
            } else if (lastAction == 'CLOSED') {
              statusColor = AppTheme.fgMuted;
              statusIcon = Icons.disabled_by_default_rounded;
            } else if (lastAction == 'DEVICE_BOUND') {
              statusColor = AppTheme.colorAmber;
              statusIcon = Icons.lock_outline_rounded;
            } else if (lastAction.contains('ALERT') || lastAction.contains('FAILED')) {
              statusColor = Colors.redAccent;
              statusIcon = Icons.warning_amber_rounded;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppTheme.bgGlassPanel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: lastAction.contains('ALERT')
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : AppTheme.borderGlass,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      lastAction,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(color: AppTheme.fgMuted, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'FINGERPRINT / CONTAINER HASH',
                                style: TextStyle(
                                  color: AppTheme.fgMuted,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              SelectableText(
                                fingerprint,
                                style: TextStyle(
                                  color: AppTheme.fgLight,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: AppTheme.borderGlass, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (senderUsername.isNotEmpty) ...[
                          Icon(Icons.person_outline_rounded, color: AppTheme.colorCyan, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Composer: @$senderUsername',
                            style: TextStyle(color: AppTheme.colorCyan, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(Icons.devices_rounded, color: AppTheme.fgMuted, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Last Device: ${lastDeviceKey.length > 20 ? "${lastDeviceKey.substring(0, 18)}..." : lastDeviceKey}',
                            style: TextStyle(color: AppTheme.fgMuted, fontSize: 10, fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.colorCyan.withValues(alpha: 0.15),
                            foregroundColor: AppTheme.colorCyan,
                            elevation: 0,
                            side: BorderSide(color: AppTheme.colorCyan.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.analytics_outlined, size: 13),
                          label: const Text(
                            'AUDIT LOGS',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SnailTrailScreen(
                                  logs: const [],
                                  fileFingerprint: fingerprint,
                                  senderUsername: senderUsername,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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
}
