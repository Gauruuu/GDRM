import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gdrm_model.dart';
import '../services/piracy_service.dart';
import '../theme/app_theme.dart';

class SnailTrailScreen extends StatefulWidget {
  final List<SnailTrailLog> logs;
  final String fileFingerprint;
  final String? senderUsername;

  const SnailTrailScreen({
    super.key,
    required this.logs,
    required this.fileFingerprint,
    this.senderUsername,
  });

  @override
  State<SnailTrailScreen> createState() => _SnailTrailScreenState();
}

class _SnailTrailScreenState extends State<SnailTrailScreen> {
  bool _showDatabaseTrail = false;

  @override
  void initState() {
    super.initState();
    if (widget.logs.isEmpty) {
      _showDatabaseTrail = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        backgroundColor: AppTheme.bgGlassSidebar,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.fgLight, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SNAILTRAIL SECURITY AUDIT',
              style: TextStyle(color: AppTheme.fgLight, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            Text(
              'Container Hash: ${widget.fileFingerprint}',
              style: const TextStyle(color: AppTheme.fgMuted, fontSize: 9, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showDatabaseTrail ? Icons.cloud_done_rounded : Icons.insert_drive_file_outlined,
              color: AppTheme.colorCyan,
              size: 20,
            ),
            tooltip: _showDatabaseTrail ? 'Switch to Local .gdrm File Trail' : 'Switch to Cloud Database Snail Trail',
            onPressed: () {
              setState(() {
                _showDatabaseTrail = !_showDatabaseTrail;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Mode switch tab
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.bgGlassSidebar,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderGlass),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showDatabaseTrail = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_showDatabaseTrail ? AppTheme.colorCyan.withOpacity(0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: !_showDatabaseTrail ? AppTheme.colorCyan.withOpacity(0.5) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insert_drive_file_outlined, size: 13, color: !_showDatabaseTrail ? AppTheme.colorCyan : AppTheme.fgMuted),
                          const SizedBox(width: 6),
                          Text(
                            '.GDRM File Trail (${widget.logs.length})',
                            style: TextStyle(
                              color: !_showDatabaseTrail ? AppTheme.colorCyan : AppTheme.fgMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showDatabaseTrail = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _showDatabaseTrail ? AppTheme.colorCyan.withOpacity(0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _showDatabaseTrail ? AppTheme.colorCyan.withOpacity(0.5) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_sync_rounded, size: 13, color: _showDatabaseTrail ? AppTheme.colorCyan : AppTheme.fgMuted),
                          const SizedBox(width: 6),
                          const Text(
                            'Live Cloud Audit Trail',
                            style: TextStyle(
                              color: AppTheme.colorCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _showDatabaseTrail ? _buildDatabaseTrailView() : _buildLocalTrailView(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalTrailView() {
    if (widget.logs.isEmpty) {
      return _buildEmptyState('No Local .gdrm Snail Trail Found');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: widget.logs.length,
      itemBuilder: (context, index) {
        final log = widget.logs[index];
        final isLast = index == widget.logs.length - 1;
        
        Color accentColor = AppTheme.colorCyan;
        IconData iconData = Icons.radio_button_checked_rounded;
        
        if (log.action == 'PACKED') {
          accentColor = AppTheme.colorCyan;
          iconData = Icons.inventory_2_outlined;
        } else if (log.action == 'OPENED') {
          accentColor = Colors.greenAccent;
          iconData = Icons.lock_open_rounded;
        } else if (log.action == 'CLOSED') {
          accentColor = AppTheme.fgMuted;
          iconData = Icons.disabled_by_default_rounded;
        } else if (log.action == 'DEVICE_BOUND') {
          accentColor = AppTheme.colorAmber;
          iconData = Icons.lock_outline_rounded;
        } else if (log.action.contains('FAILED') || log.action.contains('ALERT')) {
          accentColor = Colors.redAccent;
          iconData = Icons.gpp_bad_rounded;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
                    ),
                    child: Icon(iconData, color: accentColor, size: 14),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppTheme.borderGlass,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgGlassPanel,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: log.action.contains('ALERT') ? Colors.redAccent.withOpacity(0.5) : AppTheme.borderGlass,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              log.action,
                              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                            ),
                            const Spacer(),
                            const Icon(Icons.access_time_rounded, color: AppTheme.fgMuted, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimestamp(log.timestamp),
                              style: const TextStyle(color: AppTheme.fgMuted, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          log.details,
                          style: const TextStyle(color: AppTheme.fgLight, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.bgMain,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.borderGlass),
                          ),
                          child: Text(
                            'DEVICE KEY: ${log.deviceKey}',
                            style: const TextStyle(color: AppTheme.fgMuted, fontSize: 9, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatabaseTrailView() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: PiracyService.getDatabaseSnailTrailStream(widget.fileFingerprint),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.colorCyan));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                  const SizedBox(height: 12),
                  const Text('Error loading cloud audit events',
                      style: TextStyle(color: AppTheme.fgLight, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('${snapshot.error}',
                      style: const TextStyle(color: AppTheme.fgMuted, fontSize: 11),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        final cloudLogs = snapshot.data ?? [];

        if (cloudLogs.isEmpty) {
          return _buildEmptyState('No Cloud Database Snail Trail Synced Yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          itemCount: cloudLogs.length,
          itemBuilder: (context, index) {
            final data = cloudLogs[index];
            final isLast = index == cloudLogs.length - 1;
            final action = (data['action'] as String?) ?? 'EVENT';
            final details = (data['details'] as String?) ?? '';
            final deviceKey = (data['deviceKey'] as String?) ?? 'Unknown';
            final ip = (data['ipAddress'] as String?) ?? 'Unknown';
            final mac = (data['macAddress'] as String?) ?? 'Unknown';
            final platform = (data['platform'] as String?) ?? '';

            String timeStr = '---';
            if (data['timestamp'] is Timestamp) {
              final dt = (data['timestamp'] as Timestamp).toDate().toLocal();
              final pad = (int n) => n.toString().padLeft(2, '0');
              timeStr = '${pad(dt.day)}/${pad(dt.month)} ${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
            } else if (data['timestamp'] is String) {
              final dt = DateTime.tryParse(data['timestamp'] as String)?.toLocal();
              if (dt != null) {
                final pad = (int n) => n.toString().padLeft(2, '0');
                timeStr = '${pad(dt.day)}/${pad(dt.month)} ${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
              }
            }

            Color accentColor = AppTheme.colorCyan;
            IconData iconData = Icons.radio_button_checked_rounded;

            if (action == 'PACKED') {
              accentColor = AppTheme.colorCyan;
              iconData = Icons.inventory_2_outlined;
            } else if (action == 'OPENED') {
              accentColor = Colors.greenAccent;
              iconData = Icons.lock_open_rounded;
            } else if (action == 'CLOSED') {
              accentColor = AppTheme.fgMuted;
              iconData = Icons.disabled_by_default_rounded;
            } else if (action == 'DEVICE_BOUND') {
              accentColor = AppTheme.colorAmber;
              iconData = Icons.lock_outline_rounded;
            } else if (action.contains('ALERT') || action.contains('FAILED') || action.contains('TRIGGERED')) {
              accentColor = Colors.redAccent;
              iconData = Icons.gpp_bad_rounded;
            } else if (action.contains('PRINT')) {
              accentColor = AppTheme.colorMagenta;
              iconData = Icons.print_rounded;
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
                        ),
                        child: Icon(iconData, color: accentColor, size: 14),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppTheme.borderGlass,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.bgGlassPanel,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: action.contains('ALERT') || action.contains('TRIGGERED')
                                ? Colors.redAccent.withOpacity(0.5)
                                : AppTheme.borderGlass,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  action,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.cloud_done_rounded, color: AppTheme.colorCyan, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  timeStr,
                                  style: const TextStyle(color: AppTheme.fgMuted, fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              details,
                              style: const TextStyle(color: AppTheme.fgLight, fontSize: 12, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgMain,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.borderGlass),
                                  ),
                                  child: Text(
                                    'DEVICE: ${deviceKey.length > 20 ? "${deviceKey.substring(0, 18)}..." : deviceKey}',
                                    style: const TextStyle(color: AppTheme.fgMuted, fontSize: 9, fontFamily: 'monospace'),
                                  ),
                                ),
                                if (ip != 'Unknown' && ip.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgMain,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.borderGlass),
                                    ),
                                    child: Text(
                                      'IP: $ip',
                                      style: const TextStyle(color: AppTheme.colorCyan, fontSize: 9, fontFamily: 'monospace'),
                                    ),
                                  ),
                                if (mac != 'Unknown' && mac.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgMain,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.borderGlass),
                                    ),
                                    child: Text(
                                      'MAC: $mac',
                                      style: const TextStyle(color: AppTheme.colorCyan, fontSize: 9, fontFamily: 'monospace'),
                                    ),
                                  ),
                                if (platform.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgMain,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.borderGlass),
                                    ),
                                    child: Text(
                                      'OS: ${platform.toUpperCase()}',
                                      style: const TextStyle(color: AppTheme.fgMuted, fontSize: 9),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timeline_outlined, size: 48, color: AppTheme.borderGlass),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppTheme.fgMuted, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatTimestamp(String tsStr) {
    try {
      final secondsSinceEpoch = double.parse(tsStr);
      final dt = DateTime.fromMillisecondsSinceEpoch((secondsSinceEpoch * 1000).toInt()).toLocal();
      final pad = (int n) => n.toString().padLeft(2, '0');
      return '${pad(dt.day)}/${pad(dt.month)} ${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
    } catch (_) {
      return tsStr;
    }
  }
}