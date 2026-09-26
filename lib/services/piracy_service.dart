import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/gdrm_model.dart';

class PiracyAlertItem {
  final String id;
  final String fingerprint;
  final String fileName;
  final String licensedTo;
  final String copyrightOwner;
  final String senderUsername;
  final String pirateDeviceKey;
  final String pirateIp;
  final String pirateMac;
  final String pirateUsername;
  final String piratePlatform;
  final String action;
  final String details;
  final DateTime timestamp;
  final bool isRead;

  const PiracyAlertItem({
    required this.id,
    required this.fingerprint,
    required this.fileName,
    required this.licensedTo,
    required this.copyrightOwner,
    required this.senderUsername,
    required this.pirateDeviceKey,
    required this.pirateIp,
    required this.pirateMac,
    required this.pirateUsername,
    required this.piratePlatform,
    required this.action,
    required this.details,
    required this.timestamp,
    required this.isRead,
  });

  factory PiracyAlertItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parsedTime = DateTime.now();
    if (data['timestamp'] is Timestamp) {
      parsedTime = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      parsedTime = DateTime.tryParse(data['timestamp'] as String) ?? DateTime.now();
    }

    return PiracyAlertItem(
      id: doc.id,
      fingerprint: data['fingerprint'] ?? 'Unknown',
      fileName: data['fileName'] ?? 'Protected.gdrm',
      licensedTo: data['licensedTo'] ?? 'Unknown',
      copyrightOwner: data['copyrightOwner'] ?? 'Unknown',
      senderUsername: data['senderUsername'] ?? '',
      pirateDeviceKey: data['pirateDeviceKey'] ?? 'Unknown',
      pirateIp: data['pirateIp'] ?? 'Unknown',
      pirateMac: data['pirateMac'] ?? 'Unknown',
      pirateUsername: data['pirateUsername'] ?? 'Anonymous / Unknown',
      piratePlatform: data['piratePlatform'] ?? 'Unknown',
      action: data['action'] ?? 'PIRACY_ALERT',
      details: data['details'] ?? '',
      timestamp: parsedTime,
      isRead: data['isRead'] == true,
    );
  }
}

class PiracyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Records an audit snail trail event into Firestore database
  static Future<void> recordDatabaseSnailTrail({
    required String fingerprint,
    required String action,
    required String deviceKey,
    required String details,
    String? senderUsername,
    String? activeUsername,
    String? ipAddress,
    String? macAddress,
  }) async {
    try {
      final logEntry = {
        'fingerprint': fingerprint,
        'action': action,
        'deviceKey': deviceKey,
        'details': details,
        'senderUsername': senderUsername ?? '',
        'activeUsername': activeUsername ?? '',
        'ipAddress': ipAddress ?? 'Unknown',
        'macAddress': macAddress ?? 'Unknown',
        'platform': Platform.operatingSystem,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // 1. Add to the dedicated file snail trail collection
      await _firestore
          .collection('gdrm_snail_trails')
          .doc(fingerprint)
          .collection('events')
          .add(logEntry)
          .timeout(const Duration(seconds: 4));

      // 2. Update file summary document
      await _firestore.collection('gdrm_snail_trails').doc(fingerprint).set({
        'fingerprint': fingerprint,
        'lastAction': action,
        'lastDeviceKey': deviceKey,
        'lastUpdated': FieldValue.serverTimestamp(),
        'senderUsername': senderUsername ?? '',
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[PiracyService] Firestore SnailTrail record note: $e');
    }
  }

  /// Reports an unauthorized pirate access attempt to Firestore and notifies the sender
  static Future<void> reportPiracyAttempt({
    required GdrmMetadata manifest,
    required String pirateDeviceKey,
    required String pirateIp,
    required String pirateMac,
    required String pirateUsername,
    String? fileName,
    String reason = 'Unauthorized device attempted to open locked file container.',
  }) async {
    try {
      String cleanSender = manifest.senderUsername.trim().toLowerCase().replaceAll('@', '');
      if (cleanSender.isEmpty && manifest.copyrightOwner.contains('@')) {
        cleanSender = manifest.copyrightOwner
            .split('@')
            .last
            .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
            .trim()
            .toLowerCase();
      }

      final alertData = {
        'fingerprint': manifest.fingerprint,
        'fileName': fileName ?? 'Document.gdrm',
        'licensedTo': manifest.licensedTo,
        'copyrightOwner': manifest.copyrightOwner,
        'senderUsername': cleanSender,
        'senderEmail': manifest.senderEmail.toLowerCase().trim(),
        'pirateDeviceKey': pirateDeviceKey,
        'pirateIp': pirateIp,
        'pirateMac': pirateMac,
        'pirateUsername': pirateUsername.isNotEmpty ? pirateUsername : 'Unauthenticated_User',
        'piratePlatform': Platform.operatingSystem,
        'action': 'PIRACY_DETECTED',
        'details': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Add to global piracy alerts collection
      await _firestore
          .collection('gdrm_piracy_alerts')
          .add(alertData)
          .timeout(const Duration(seconds: 5));

      // Also record in database snail trail
      await recordDatabaseSnailTrail(
        fingerprint: manifest.fingerprint,
        action: 'PIRACY_ALERT',
        deviceKey: pirateDeviceKey,
        details: 'Piracy Alert: $reason (IP: $pirateIp, MAC: $pirateMac, User: $pirateUsername)',
        senderUsername: cleanSender.isNotEmpty ? cleanSender : manifest.senderUsername,
        activeUsername: pirateUsername,
        ipAddress: pirateIp,
        macAddress: pirateMac,
      );
    } catch (e) {
      debugPrint('[PiracyService] Error reporting piracy alert to Firestore: $e');
    }
  }

  /// Real-time stream of piracy alerts for a specific sender
  static Stream<List<PiracyAlertItem>> getPiracyAlertsStream(String senderUsername) {
    final cleanSender = senderUsername.trim().toLowerCase().replaceAll('@', '');
    if (cleanSender.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('gdrm_piracy_alerts')
        .where('senderUsername', isEqualTo: cleanSender)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => PiracyAlertItem.fromFirestore(doc))
              .toList();
          // Sort descending by timestamp
          items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return items;
        });
  }

  /// Marks a specific piracy alert as read
  static Future<void> markAlertAsRead(String alertId) async {
    try {
      await _firestore
          .collection('gdrm_piracy_alerts')
          .doc(alertId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('[PiracyService] Error marking alert as read: $e');
    }
  }

  /// Marks all piracy alerts as read for a given sender
  static Future<void> markAllAlertsAsRead(String senderUsername) async {
    final cleanSender = senderUsername.trim().toLowerCase().replaceAll('@', '');
    if (cleanSender.isEmpty) return;

    try {
      final query = await _firestore
          .collection('gdrm_piracy_alerts')
          .where('senderUsername', isEqualTo: cleanSender)
          .where('isRead', isEqualTo: false)
          .get()
          .timeout(const Duration(seconds: 4));

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[PiracyService] Error marking all alerts as read: $e');
    }
  }

  /// Real-time stream of database snail trail events for a file
  static Stream<List<Map<String, dynamic>>> getDatabaseSnailTrailStream(String fingerprint) {
    if (fingerprint.isEmpty || fingerprint == '---') {
      return Stream.value([]);
    }

    return _firestore
        .collection('gdrm_snail_trails')
        .doc(fingerprint)
        .collection('events')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();

          list.sort((a, b) {
            final tA = a['timestamp'];
            final tB = b['timestamp'];
            DateTime dateA = DateTime.fromMillisecondsSinceEpoch(0);
            DateTime dateB = DateTime.fromMillisecondsSinceEpoch(0);
            if (tA is Timestamp) {
              dateA = tA.toDate();
            } else if (tA is String) {
              dateA = DateTime.tryParse(tA) ?? dateA;
            }
            if (tB is Timestamp) {
              dateB = tB.toDate();
            } else if (tB is String) {
              dateB = DateTime.tryParse(tB) ?? dateB;
            }
            return dateA.compareTo(dateB);
          });
          return list;
        });
  }

  /// Fetches global database snail trail events for a file
  static Future<List<Map<String, dynamic>>> fetchDatabaseSnailTrail(String fingerprint) async {
    if (fingerprint.isEmpty || fingerprint == '---') return [];
    try {
      final query = await _firestore
          .collection('gdrm_snail_trails')
          .doc(fingerprint)
          .collection('events')
          .get()
          .timeout(const Duration(seconds: 4));

      final list = query.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();

      list.sort((a, b) {
        final tA = a['timestamp'];
        final tB = b['timestamp'];
        DateTime dateA = DateTime.fromMillisecondsSinceEpoch(0);
        DateTime dateB = DateTime.fromMillisecondsSinceEpoch(0);
        if (tA is Timestamp) {
          dateA = tA.toDate();
        } else if (tA is String) {
          dateA = DateTime.tryParse(tA) ?? dateA;
        }
        if (tB is Timestamp) {
          dateB = tB.toDate();
        } else if (tB is String) {
          dateB = DateTime.tryParse(tB) ?? dateB;
        }
        return dateA.compareTo(dateB);
      });

      return list;
    } catch (e) {
      debugPrint('[PiracyService] Error fetching database snail trail: $e');
      return [];
    }
  }
}
