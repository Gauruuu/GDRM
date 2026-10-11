import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/piracy_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'snail_trail_screen.dart';

class PiracyAlertsScreen extends StatelessWidget {
  final String? senderUsername;
  final bool isEmbedded;

  const PiracyAlertsScreen({
    super.key,
    this.senderUsername,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final effectiveUsername = senderUsername ?? state.cloudUsername ?? 'gauruu';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header (matches Page 3 & Page 6) ──
        Padding(
          padding: EdgeInsets.fromLTRB(
            isEmbedded ? 32 : 24,
            isEmbedded ? 32 : 16,
            isEmbedded ? 32 : 24,
            24,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alerts',
                      style: TextStyle(
                        color: AppTheme.fgLight,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unauthorized open attempts on files you created.',
                      style: TextStyle(
                        color: AppTheme.fgMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.unreadPiracyAlertsCount > 0)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryBtnBg,
                    foregroundColor: AppTheme.fgLight,
                    side: BorderSide(color: AppTheme.secondaryBtnBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.done_all_rounded, size: 15),
                  label: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                  onPressed: () async {
                    await state.markAllPiracyAlertsRead();
                  },
                ),
            ],
          ),
        ),

        // ── List of Alerts ──
        Expanded(
          child: StreamBuilder<List<PiracyAlertItem>>(
            stream: PiracyService.getPiracyAlertsStream(effectiveUsername),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
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
                          color: AppTheme.navActiveBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 44,
                          color: AppTheme.isDark ? AppTheme.darkPrimaryGreen : AppTheme.lightPrimaryGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Unauthorized Attempts',
                        style: TextStyle(
                          color: AppTheme.fgLight,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'All files created by @$effectiveUsername are secure.',
                        style: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isEmbedded ? 32 : 20,
                  vertical: 8,
                ),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _AlertCard(alert: alert);
                },
              );
            },
          ),
        ),
      ],
    );

    if (isEmbedded) {
      return Container(
        color: AppTheme.bgMain,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        backgroundColor: AppTheme.bgGlassSidebar,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.fgLight, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Alerts',
          style: TextStyle(
            color: AppTheme.fgLight,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: content,
    );
  }
}

class _AlertCard extends StatefulWidget {
  final PiracyAlertItem alert;

  const _AlertCard({required this.alert});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(alert.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgGlassPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alert.isRead ? AppTheme.borderGlass : Colors.redAccent.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: Title & Date ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  alert.details.isNotEmpty
                      ? alert.details
                      : 'Unauthorized open attempt detected',
                  style: TextStyle(
                    color: AppTheme.fgLight,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                formattedTime,
                style: TextStyle(
                  color: AppTheme.fgMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Meta info row: File, Recipient, Platform ──
          Wrap(
            spacing: 24,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _infoSegment('File', alert.fileName),
              _infoSegment('Recipient', alert.licensedTo),
              _infoSegment(
                null,
                alert.piratePlatform.isNotEmpty ? alert.piratePlatform : 'Unknown Platform',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Action Buttons ──
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryBtnBg,
                  foregroundColor: AppTheme.fgLight,
                  side: BorderSide(color: AppTheme.secondaryBtnBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SnailTrailScreen(
                        fileFingerprint: alert.fingerprint,
                        logs: const [],
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View trail',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    _expanded ? 'Hide forensics' : 'Forensic details',
                    style: TextStyle(
                      color: AppTheme.fgMuted,
                      fontSize: 11.5,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Expandable Forensic Details ──
          if (_expanded) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgMain,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderGlass),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Fingerprint', alert.fingerprint),
                  _detailRow('IP Address', alert.pirateIp),
                  _detailRow('MAC Address', alert.pirateMac),
                  _detailRow('Device Key', alert.pirateDeviceKey),
                  _detailRow('Pirate Account', alert.pirateUsername),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoSegment(String? label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          if (label != null)
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: AppTheme.fgMuted,
                fontSize: 12.5,
              ),
            ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: AppTheme.fgLight,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.fgLight,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
