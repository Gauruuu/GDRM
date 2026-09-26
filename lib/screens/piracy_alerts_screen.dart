import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/piracy_service.dart';
import '../theme/app_theme.dart';
import 'snail_trail_screen.dart';

class PiracyAlertsScreen extends StatelessWidget {
  final String senderUsername;

  const PiracyAlertsScreen({super.key, required this.senderUsername});

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
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  'SECURITY & PIRACY ALERTS',
                  style: TextStyle(
                    color: AppTheme.fgLight,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            Text(
              'Monitoring author: @${senderUsername.replaceAll('@', '')}',
              style: const TextStyle(color: AppTheme.fgMuted, fontSize: 10),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mark All as Read',
            icon: const Icon(Icons.done_all_rounded, color: AppTheme.colorCyan, size: 20),
            onPressed: () async {
              await PiracyService.markAllAlertsAsRead(senderUsername);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.bgGlassPanel,
                    content: Text('All security alerts marked as read.',
                        style: TextStyle(color: AppTheme.fgLight, fontSize: 12)),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PiracyAlertItem>>(
        stream: PiracyService.getPiracyAlertsStream(senderUsername),
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
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 42),
                    const SizedBox(height: 12),
                    const Text('Error loading piracy alerts',
                        style: TextStyle(color: AppTheme.fgLight, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('${snapshot.error}',
                        style: const TextStyle(color: AppTheme.fgMuted, fontSize: 11),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.shield_outlined, size: 48, color: Colors.greenAccent),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Piracy Attempts Detected',
                    style: TextStyle(color: AppTheme.fgLight, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'All your authored files are secure and operating within licensed bounds.',
                    style: TextStyle(color: AppTheme.fgMuted, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final formattedTime = DateFormat('dd MMM yyyy, HH:mm:ss').format(alert.timestamp);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.bgGlassPanel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: alert.isRead ? AppTheme.borderGlass : Colors.redAccent.withOpacity(0.6),
                    width: alert.isRead ? 1.0 : 1.5,
                  ),
                  boxShadow: alert.isRead
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.12),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'PIRACY BREACH',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formattedTime,
                            style: const TextStyle(color: AppTheme.fgMuted, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        alert.details,
                        style: const TextStyle(
                          color: AppTheme.fgLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: AppTheme.borderGlass, height: 1),
                      const SizedBox(height: 10),

                      // Forensic grid
                      _buildForensicRow(Icons.description_outlined, 'File Name', alert.fileName),
                      _buildForensicRow(Icons.fingerprint, 'Fingerprint', alert.fingerprint, isMono: true),
                      _buildForensicRow(Icons.person_pin_outlined, 'Licensed Recipient', alert.licensedTo),
                      const SizedBox(height: 6),
                      const Text(
                        'PIRATE FORENSIC METRICS',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgMain,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderGlass),
                        ),
                        child: Column(
                          children: [
                            _buildForensicRow(Icons.wifi_rounded, 'Pirate IP Address', alert.pirateIp, isMono: true, valueColor: Colors.orangeAccent),
                            _buildForensicRow(Icons.router_rounded, 'Pirate MAC Address', alert.pirateMac, isMono: true, valueColor: Colors.orangeAccent),
                            _buildForensicRow(Icons.computer_rounded, 'Pirate Platform/OS', alert.piratePlatform.toUpperCase()),
                            _buildForensicRow(Icons.account_circle_outlined, 'Pirate Account', alert.pirateUsername),
                            _buildForensicRow(Icons.memory_rounded, 'Pirate Device Key', alert.pirateDeviceKey, isMono: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!alert.isRead)
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: AppTheme.fgMuted),
                              icon: const Icon(Icons.mark_email_read_outlined, size: 14),
                              label: const Text('Mark Read', style: TextStyle(fontSize: 11)),
                              onPressed: () => PiracyService.markAlertAsRead(alert.id),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.colorCyan.withOpacity(0.15),
                              foregroundColor: AppTheme.colorCyan,
                              elevation: 0,
                              side: BorderSide(color: AppTheme.colorCyan.withOpacity(0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            icon: const Icon(Icons.timeline_rounded, size: 14),
                            label: const Text('View Full Snail Trail', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SnailTrailScreen(
                                    logs: const [],
                                    fileFingerprint: alert.fingerprint,
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
      ),
    );
  }

  Widget _buildForensicRow(IconData icon, String label, String value, {bool isMono = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: AppTheme.fgMuted),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(color: AppTheme.fgMuted, fontSize: 10),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppTheme.fgLight,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                fontFamily: isMono ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
