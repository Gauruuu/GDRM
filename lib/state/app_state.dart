import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/gdrm_model.dart';
import '../services/piracy_service.dart';
import '../services/smtp_email_service.dart';

enum AppView { reader, packer }

class AppState extends ChangeNotifier {
  AppState() {
    _initAuthListener();
  }

  // ── Navigation ──────────────────────────────────────────────────────────────
  AppView currentView = AppView.reader;

  void switchView(AppView view) {
    currentView = view;
    notifyListeners();
  }

  // ── Firebase Cloud Authentication States ──────────────────────────────────
  String? cloudUsername;
  String? cloudDisplayName;
  String? cloudEmail;
  String? cloudUid;
  bool isAuthLoading = false;

  bool get isCloudAuthenticated => cloudUsername != null;

  // ── Piracy Security Monitoring & Alerts ───────────────────────────────────
  StreamSubscription<List<PiracyAlertItem>>? _piracySub;
  List<PiracyAlertItem> activePiracyAlerts = [];
  int unreadPiracyAlertsCount = 0;

  void _initPiracyAlertListener(String username) {
    _piracySub?.cancel();
    final clean = username.trim().toLowerCase().replaceAll('@', '');
    if (clean.isEmpty) {
      activePiracyAlerts = [];
      unreadPiracyAlertsCount = 0;
      notifyListeners();
      return;
    }

    _piracySub = PiracyService.getPiracyAlertsStream(clean).listen(
      (alerts) {
        activePiracyAlerts = alerts;
        unreadPiracyAlertsCount = alerts.where((a) => !a.isRead).length;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[AppState] Piracy alert stream notification error: $e');
      },
    );
  }

  Future<void> markPiracyAlertRead(String alertId) async {
    await PiracyService.markAlertAsRead(alertId);
    // Local optimistic update
    final index = activePiracyAlerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      // Re-calculate unread count
      unreadPiracyAlertsCount = activePiracyAlerts.where((a) => !a.isRead && a.id != alertId).length;
      notifyListeners();
    }
  }

  Future<void> markAllPiracyAlertsRead() async {
    if (cloudUsername != null && cloudUsername!.isNotEmpty) {
      await PiracyService.markAllAlertsAsRead(cloudUsername!);
      unreadPiracyAlertsCount = 0;
      notifyListeners();
    }
  }

  bool isEmailVerified = false;

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        cloudUid = user.uid;
        cloudEmail = user.email;
        cloudDisplayName = user.displayName ?? '';
        isEmailVerified = user.emailVerified;

        if (cloudUsername == null) {
          try {
            final query = await FirebaseFirestore.instance
                .collection('gdrm_users')
                .where('uid', isEqualTo: user.uid)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 3));

            if (query.docs.isNotEmpty) {
              final data = query.docs.first.data();
              cloudUsername = data['username'] as String?;
              cloudDisplayName = (data['name'] as String?) ?? user.displayName ?? '';
              cloudEmail = (data['email'] as String?) ?? user.email;
              if (data['isEmailVerified'] == true) {
                isEmailVerified = true;
              }
              if (cloudUsername != null) {
                _initPiracyAlertListener(cloudUsername!);
              }
              notifyListeners();
            } else if (user.email != null) {
              cloudUsername = user.email!.split('@').first;
              _initPiracyAlertListener(cloudUsername!);
              notifyListeners();
            }
          } catch (e) {
            debugPrint('[Firebase Auth Init] Firestore profile resolve error: $e');
            if (user.email != null) {
              cloudUsername = user.email!.split('@').first;
              _initPiracyAlertListener(cloudUsername!);
              notifyListeners();
            }
          }
        } else {
          _initPiracyAlertListener(cloudUsername!);
        }
      } else {
        cloudUsername = null;
        cloudDisplayName = null;
        cloudEmail = null;
        cloudUid = null;
        isEmailVerified = false;
        _piracySub?.cancel();
        _piracySub = null;
        activePiracyAlerts = [];
        unreadPiracyAlertsCount = 0;
        notifyListeners();
      }
    });
  }

  /// Authenticate user via username or email + password. Returns 'SUCCESS' or error description.
  Future<String> loginToCloud(String identifier, String password) async {
    try {
      final cleanIdentifier = identifier.trim().toLowerCase();
      String resolvedEmail = cleanIdentifier;
      String resolvedUsername = cleanIdentifier;
      String resolvedDisplayName = '';

      if (cleanIdentifier.contains('@')) {
        // ── Sign in directly via Email ──
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: cleanIdentifier,
              password: password,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw 'Connection timed out while contacting Firebase. Please check your internet connection.',
            );

        if (credential.user != null) {
          cloudUid = credential.user!.uid;
          cloudEmail = cleanIdentifier;
          cloudDisplayName = credential.user!.displayName ?? '';

          try {
            final query = await FirebaseFirestore.instance
                .collection('gdrm_users')
                .where('uid', isEqualTo: credential.user!.uid)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 3));

            if (query.docs.isNotEmpty) {
              final data = query.docs.first.data();
              cloudUsername = data['username'] as String?;
              cloudDisplayName = (data['name'] as String?) ?? credential.user!.displayName ?? '';
            } else {
              cloudUsername = cleanIdentifier.split('@').first;
            }
          } catch (_) {
            cloudUsername = cleanIdentifier.split('@').first;
          }

          if (cloudUsername != null) {
            _initPiracyAlertListener(cloudUsername!);
          }
          notifyListeners();
          return 'SUCCESS';
        }
        return 'Authentication failed. Please check your credentials.';
      } else {
        // ── Sign in via Username handle ──
        try {
          final doc = await FirebaseFirestore.instance
              .collection('gdrm_users')
              .doc(cleanIdentifier)
              .get()
              .timeout(const Duration(seconds: 4));

          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            resolvedEmail = (data['email'] as String?) ?? '';
            resolvedUsername = cleanIdentifier;
            resolvedDisplayName = (data['name'] as String?) ?? '';
          }
        } catch (e) {
          debugPrint('[Login] Firestore username lookup notice: $e');
        }

        if (resolvedEmail.isEmpty || !resolvedEmail.contains('@')) {
          return 'Username @$cleanIdentifier not found in registry. Please try logging in with your Email address.';
        }

        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: resolvedEmail,
              password: password,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw 'Connection timed out while contacting Firebase.',
            );

        if (credential.user != null) {
          cloudUsername = resolvedUsername;
          cloudEmail = resolvedEmail;
          cloudDisplayName = resolvedDisplayName.isNotEmpty
              ? resolvedDisplayName
              : (credential.user!.displayName ?? '');
          cloudUid = credential.user!.uid;
          _initPiracyAlertListener(resolvedUsername);
          notifyListeners();
          return 'SUCCESS';
        }
        return 'Authentication failed.';
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[Firebase Auth Exception] code=${e.code}, msg=${e.message}');
      if (e.code == 'user-not-found') {
        return 'No registered account found for this username/email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Incorrect password. Please verify and try again.';
      } else if (e.code == 'invalid-email') {
        return 'The email format is invalid.';
      } else if (e.code == 'user-disabled') {
        return 'This account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        return 'Too many failed attempts. Please wait a moment and try again.';
      } else if (e.code == 'network-request-failed') {
        return 'Network connection failed. Please check your internet connection.';
      } else if (e.code == 'operation-not-allowed') {
        return 'Email/Password sign-in is not enabled in Firebase Console.';
      }
      return 'Firebase Error: ${e.message ?? e.code}';
    } catch (e) {
      debugPrint('[Login Exception] $e');
      return '$e';
    }
  }

  /// Provision an account with Name, Username, Email, and Password
  Future<String> registerOnCloud({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final cleanName = name.trim();
      final cleanUsername = username.trim().toLowerCase();
      final cleanEmail = email.trim().toLowerCase();

      // Validate username handle format (letters, numbers, underscore only)
      if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(cleanUsername)) {
        return 'INVALID_USERNAME_FORMAT';
      }

      // 1. Check if Username handle is taken in Firestore (with fast 3s timeout)
      try {
        final userCheck = await FirebaseFirestore.instance
            .collection('gdrm_users')
            .doc(cleanUsername)
            .get()
            .timeout(const Duration(seconds: 3));

        if (userCheck.exists) {
          return 'USERNAME_TAKEN';
        }
      } catch (e) {
        debugPrint('[Registration Pre-Check] Firestore lookup notice (continuing): $e');
      }

      // 2. Create native Firebase Auth Identity
      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: cleanEmail,
            password: password,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw 'Connection timed out while creating Firebase account. Check your internet connection.',
          );

      if (credential.user == null) {
        return 'Firebase provisioning failed. Please try again.';
      }

      // Update user display name in Firebase Auth
      try {
        await credential.user!.updateDisplayName(cleanName);
      } catch (_) {}

      // 3. Save profile document in Firestore `gdrm_users/{cleanUsername}`
      try {
        await FirebaseFirestore.instance
            .collection('gdrm_users')
            .doc(cleanUsername)
            .set({
          'name': cleanName,
          'username': cleanUsername,
          'email': cleanEmail,
          'uid': credential.user!.uid,
          'isEmailVerified': true,
          'emailVerifiedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('[Registration] Warning saving Firestore profile doc: $e');
      }

      cloudUsername = cleanUsername;
      cloudDisplayName = cleanName;
      cloudEmail = cleanEmail;
      cloudUid = credential.user!.uid;
      isEmailVerified = true;

      _initPiracyAlertListener(cleanUsername);
      notifyListeners();
      return 'SUCCESS';
    } on FirebaseAuthException catch (e) {
      debugPrint('[Firebase Auth Register Exception] code=${e.code}, msg=${e.message}');
      if (e.code == 'email-already-in-use') {
        return 'EMAIL_TAKEN';
      } else if (e.code == 'weak-password') {
        return 'WEAK_PASSWORD';
      } else if (e.code == 'invalid-email') {
        return 'INVALID_EMAIL';
      } else if (e.code == 'operation-not-allowed') {
        return 'Email/Password sign-in is not enabled in Firebase Console. Please enable it in Firebase Console under Authentication -> Sign-in method.';
      } else if (e.code == 'network-request-failed') {
        return 'Network connection failed. Please check your internet connection.';
      }
      return 'Firebase Error: ${e.message ?? e.code}';
    } catch (e) {
      debugPrint('[Register Exception] $e');
      return '$e';
    }
  }

  Future<String> sendPasswordResetEmail(String emailOrUsername) async {
    try {
      final clean = emailOrUsername.trim().toLowerCase();
      String resolvedEmail = clean;
      if (!clean.contains('@')) {
        final doc = await FirebaseFirestore.instance
            .collection('gdrm_users')
            .doc(clean)
            .get()
            .timeout(const Duration(seconds: 4));
        if (doc.exists && doc.data() != null) {
          resolvedEmail = (doc.data()!['email'] as String?) ?? '';
        }
      }
      if (resolvedEmail.isEmpty || !resolvedEmail.contains('@')) {
        return 'Could not find a registered email for "@$clean". Please enter your full email address.';
      }
      await FirebaseAuth.instance.sendPasswordResetEmail(email: resolvedEmail);
      return 'SUCCESS:$resolvedEmail';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send password reset email.';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ── OTP State Management (Gmail SMTP) ────────────────────────────────────
  String? _pendingRegOtp;
  DateTime? _regOtpExpiry;
  String? _pendingVerificationOtp;
  DateTime? _verificationOtpExpiry;
  String? _pendingDeleteOtp;
  DateTime? _deleteOtpExpiry;

  /// Sends a 6-digit OTP to the prospective user's email via Gmail SMTP during registration.
  Future<String> sendRegistrationOtp(String email) async {
    try {
      final clean = email.trim().toLowerCase();
      if (clean.isEmpty || !clean.contains('@')) {
        return 'Please enter a valid email address.';
      }

      final otp = SmtpEmailService.generateOtp();
      _pendingRegOtp = otp;
      _regOtpExpiry = DateTime.now().add(const Duration(minutes: 10));

      final success = await SmtpEmailService.sendOtp(
        recipientEmail: clean,
        otp: otp,
        title: 'Verify Your Email to Complete Registration',
        subtitle: 'Confirm your new GDRM identity and cryptographic credentials',
      );

      if (success) {
        return 'SUCCESS';
      } else {
        return 'Failed to send verification email. Please check your internet connection and try again.';
      }
    } catch (e) {
      return 'Error sending verification code: $e';
    }
  }

  /// Verifies if the registration OTP matches the active code and is not expired.
  bool validateRegistrationOtp(String enteredOtp) {
    if (_pendingRegOtp == null || _regOtpExpiry == null) return false;
    if (DateTime.now().isAfter(_regOtpExpiry!)) {
      _pendingRegOtp = null;
      _regOtpExpiry = null;
      return false;
    }
    return enteredOtp.trim() == _pendingRegOtp;
  }

  /// Sends a 6-digit OTP to the user's email via Gmail SMTP for email verification.
  Future<String> sendVerificationOtpEmail() async {
    try {
      final email = cloudEmail ?? FirebaseAuth.instance.currentUser?.email;
      if (email == null || email.isEmpty) {
        return 'No registered email address found for the current account.';
      }

      final otp = SmtpEmailService.generateOtp();
      _pendingVerificationOtp = otp;
      _verificationOtpExpiry = DateTime.now().add(const Duration(minutes: 10));

      final success = await SmtpEmailService.sendOtp(
        recipientEmail: email,
        otp: otp,
        title: 'Verify Your Email Address',
        subtitle: 'Confirm your registered GDRM account identity',
      );

      if (success) {
        return 'SUCCESS';
      } else {
        return 'Failed to send OTP email. Please check your internet connection and try again.';
      }
    } catch (e) {
      return 'Error sending OTP: $e';
    }
  }

  /// Verifies the entered 6-digit OTP and marks the email as verified in Firestore.
  Future<String> verifyEmailOtp(String enteredOtp) async {
    try {
      if (_pendingVerificationOtp == null || _verificationOtpExpiry == null) {
        return 'No active verification OTP found. Please request a new OTP.';
      }
      if (DateTime.now().isAfter(_verificationOtpExpiry!)) {
        _pendingVerificationOtp = null;
        _verificationOtpExpiry = null;
        return 'OTP has expired. Please request a new verification code.';
      }
      if (enteredOtp.trim() != _pendingVerificationOtp) {
        return 'Invalid OTP code. Please enter the correct 6-digit code.';
      }

      // Mark verified in Firestore
      if (cloudUsername != null && cloudUsername!.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('gdrm_users')
              .doc(cloudUsername)
              .set({
            'isEmailVerified': true,
            'emailVerifiedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('[AppState] Notice updating Firestore email verification: $e');
        }
      }

      _pendingVerificationOtp = null;
      _verificationOtpExpiry = null;
      isEmailVerified = true;
      notifyListeners();
      return 'SUCCESS';
    } catch (e) {
      return 'Error verifying OTP: $e';
    }
  }

  /// Sends a 6-digit OTP to the user's email via Gmail SMTP for account deletion.
  Future<String> sendDeleteAccountOtpEmail() async {
    try {
      final email = cloudEmail ?? FirebaseAuth.instance.currentUser?.email;
      if (email == null || email.isEmpty) {
        return 'No registered email address found for the current account.';
      }

      final otp = SmtpEmailService.generateOtp();
      _pendingDeleteOtp = otp;
      _deleteOtpExpiry = DateTime.now().add(const Duration(minutes: 10));

      final success = await SmtpEmailService.sendOtp(
        recipientEmail: email,
        otp: otp,
        title: 'Confirm Account Deletion',
        subtitle: 'Permanent deletion of GDRM identity and cryptographic credentials',
      );

      if (success) {
        return 'SUCCESS';
      } else {
        return 'Failed to send deletion OTP email. Please try again.';
      }
    } catch (e) {
      return 'Error sending OTP: $e';
    }
  }

  /// Verifies deletion OTP and permanently removes user from Firestore and Firebase Auth.
  Future<String> verifyAndDeleteAccount(String enteredOtp) async {
    try {
      if (_pendingDeleteOtp == null || _deleteOtpExpiry == null) {
        return 'No active deletion OTP found. Please request a new OTP.';
      }
      if (DateTime.now().isAfter(_deleteOtpExpiry!)) {
        _pendingDeleteOtp = null;
        _deleteOtpExpiry = null;
        return 'Deletion OTP has expired. Please request a new verification code.';
      }
      if (enteredOtp.trim() != _pendingDeleteOtp) {
        return 'Invalid OTP code. Please enter the correct 6-digit code.';
      }

      // 1. Delete user record in Firestore
      if (cloudUsername != null && cloudUsername!.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('gdrm_users')
              .doc(cloudUsername)
              .delete();
        } catch (e) {
          debugPrint('[AppState] Error deleting Firestore user doc: $e');
        }
      }

      // 2. Delete user in Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.delete();
        } catch (e) {
          debugPrint('[AppState] Firebase Auth user delete notice: $e');
        }
      }

      _pendingDeleteOtp = null;
      _deleteOtpExpiry = null;
      logoutCloud();
      return 'SUCCESS';
    } catch (e) {
      return 'Error deleting account: $e';
    }
  }

  void logoutCloud() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    cloudUsername = null;
    cloudDisplayName = null;
    cloudEmail = null;
    cloudUid = null;
    _piracySub?.cancel();
    activePiracyAlerts = [];
    unreadPiracyAlertsCount = 0;
    notifyListeners();
  }

  // ── Manifest & Reader Core Framework ──────────────────────────────────────
  GdrmMetadata manifest = GdrmMetadata.empty;
  String? tempPdfPath;
  int pageNum = 0;
  int totalPages = 0;
  double zoomLevel = 1.0;
  bool isFileLoaded = false;
  String? readerError;

  Future<void> unloadGdrm() async {
    if (tempPdfPath != null) {
      try {
        await File(tempPdfPath!).delete();
      } catch (_) {}
    }
    tempPdfPath = null;
    manifest = GdrmMetadata.empty;
    pageNum = 0;
    totalPages = 0;
    zoomLevel = 1.0;
    isFileLoaded = false;
    readerError = null;
    notifyListeners();
  }

  Future<void> loadGdrm(GdrmParseResult result) async {
    if (tempPdfPath != null) {
      try {
        await File(tempPdfPath!).delete();
      } catch (_) {}
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/gdrm_preview_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(path).writeAsBytes(result.pdfBytes);

    tempPdfPath = path;
    manifest = result.metadata;
    pageNum = 0;
    zoomLevel = 1.0;
    isFileLoaded = true;
    readerError = null;
    notifyListeners();
  }

  void setTotalPages(int count) {
    totalPages = count;
    notifyListeners();
  }

  void nextPage() {
    if (pageNum < totalPages - 1) {
      pageNum++;
      notifyListeners();
    }
  }

  void prevPage() {
    if (pageNum > 0) {
      pageNum--;
      notifyListeners();
    }
  }

  void zoomIn() {
    zoomLevel *= 1.2;
    notifyListeners();
  }

  void zoomOut() {
    zoomLevel /= 1.2;
    if (zoomLevel < 0.2) zoomLevel = 0.2;
    notifyListeners();
  }

  void setReaderError(String msg) {
    readerError = msg;
    isFileLoaded = false;
    notifyListeners();
  }

  bool isPackerWorking = false;
  String? packerResult;

  void setPackerWorking(bool v) {
    isPackerWorking = v;
    notifyListeners();
  }

  void setPackerResult(String? msg) {
    packerResult = msg;
    notifyListeners();
  }
}