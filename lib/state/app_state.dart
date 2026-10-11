import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/gdrm_model.dart';
import '../services/piracy_service.dart';
import '../services/smtp_email_service.dart';

import '../theme/app_theme.dart';

enum AppView { reader, packer, trackedFiles, alerts }

class AppState extends ChangeNotifier {
  AppState() {
    _initAuthListener();
  }

  // ── Theme State ─────────────────────────────────────────────────────────────
  bool isDarkMode = true;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    AppTheme.isDark = isDarkMode;
    notifyListeners();
  }

  void setThemeMode(bool dark) {
    isDarkMode = dark;
    AppTheme.isDark = dark;
    notifyListeners();
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
  String? cloudPhone;
  String? cloudCountry;
  String? cloudState;
  String? cloudCity;
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
              cloudPhone = data['phone'] as String?;
              cloudCountry = data['country'] as String?;
              cloudState = data['state'] as String?;
              cloudCity = data['city'] as String?;
              if (data['isEmailVerified'] == true) {
                isEmailVerified = true;
              }
              if (cloudUsername != null) {
                _initPiracyAlertListener(cloudUsername!);
              }
              notifyListeners();
            } else if (user.email != null) {
              cloudUsername = user.email!.split('@').first;
              cloudPhone = null;
              cloudCountry = null;
              cloudState = null;
              cloudCity = null;
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
        cloudPhone = null;
        cloudCountry = null;
        cloudState = null;
        cloudCity = null;
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
              cloudPhone = data['phone'] as String?;
              cloudCountry = data['country'] as String?;
              cloudState = data['state'] as String?;
              cloudCity = data['city'] as String?;
            } else {
              cloudUsername = cleanIdentifier.split('@').first;
              cloudPhone = null;
              cloudCountry = null;
              cloudState = null;
              cloudCity = null;
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
            cloudPhone = data['phone'] as String?;
            cloudCountry = data['country'] as String?;
            cloudState = data['state'] as String?;
            cloudCity = data['city'] as String?;
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

  /// Pre-check uniqueness of username and phone number before proceeding with OTP
  Future<String?> checkRegistrationPreconditions({
    required String username,
    required String email,
    required String phone,
  }) async {
    try {
      final cleanUsername = username.trim().toLowerCase();
      final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();

      // 1. Check Username handle in Firestore
      final userCheck = await FirebaseFirestore.instance
          .collection('gdrm_users')
          .doc(cleanUsername)
          .get()
          .timeout(const Duration(seconds: 4));

      if (userCheck.exists) {
        return 'USERNAME_TAKEN';
      }

      // 2. Check dedicated gdrm_phones unique index
      final phoneCheck = await FirebaseFirestore.instance
          .collection('gdrm_phones')
          .doc(cleanPhone)
          .get()
          .timeout(const Duration(seconds: 4));

      if (phoneCheck.exists) {
        return 'PHONE_TAKEN';
      }

      // 3. Check gdrm_users collection for existing phone number
      final phoneQuery = await FirebaseFirestore.instance
          .collection('gdrm_users')
          .where('phone', isEqualTo: cleanPhone)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (phoneQuery.docs.isNotEmpty) {
        return 'PHONE_TAKEN';
      }

      return null;
    } catch (e) {
      debugPrint('[Registration Pre-Check] Firestore lookup notice: $e');
      return null;
    }
  }

  /// Provision an account with Name, Username, Email, Password, Phone, Country, State, City
  Future<String> registerOnCloud({
    required String name,
    required String username,
    required String email,
    required String password,
    required String phone,
    required String country,
    required String state,
    required String city,
  }) async {
    try {
      final cleanName = name.trim();
      final cleanUsername = username.trim().toLowerCase();
      final cleanEmail = email.trim().toLowerCase();
      final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();

      // Validate username handle format (letters, numbers, underscore only)
      if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(cleanUsername)) {
        return 'INVALID_USERNAME_FORMAT';
      }

      // Validate phone format
      if (cleanPhone.length < 7 || cleanPhone.length > 17) {
        return 'INVALID_PHONE_FORMAT';
      }

      // 1. Verify preconditions (Username and Phone Uniqueness)
      final preCheck = await checkRegistrationPreconditions(
        username: cleanUsername,
        email: cleanEmail,
        phone: cleanPhone,
      );
      if (preCheck != null) {
        return preCheck;
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

      // 3. Reserve phone number atomically in gdrm_phones/{cleanPhone}
      try {
        await FirebaseFirestore.instance
            .collection('gdrm_phones')
            .doc(cleanPhone)
            .set({
          'phone': cleanPhone,
          'username': cleanUsername,
          'uid': credential.user!.uid,
          'registeredAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('[Registration] Warning saving gdrm_phones unique index: $e');
      }

      // 4. Save profile document in Firestore `gdrm_users/{cleanUsername}`
      try {
        await FirebaseFirestore.instance
            .collection('gdrm_users')
            .doc(cleanUsername)
            .set({
          'name': cleanName,
          'username': cleanUsername,
          'email': cleanEmail,
          'phone': cleanPhone,
          'country': country.trim(),
          'state': state.trim(),
          'city': city.trim(),
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
      cloudPhone = cleanPhone;
      cloudCountry = country.trim();
      cloudState = state.trim();
      cloudCity = city.trim();
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

  bool _isSendingRegOtp = false;
  bool _isSendingVerificationOtp = false;
  DateTime? _lastRegOtpSentTime;
  DateTime? _lastVerificationOtpSentTime;

  /// Sends a 6-digit OTP to the prospective user's email via Gmail SMTP during registration.
  Future<String> sendRegistrationOtp(String email, {bool forceNew = false}) async {
    if (_isSendingRegOtp) {
      return 'SUCCESS'; // Operation already actively in-flight
    }
    // Rate limit duplicate calls within 15 seconds unless explicitly forced via Resend
    if (!forceNew && _lastRegOtpSentTime != null && DateTime.now().difference(_lastRegOtpSentTime!).inSeconds < 15) {
      return 'SUCCESS';
    }

    _isSendingRegOtp = true;
    try {
      final clean = email.trim().toLowerCase();
      if (clean.isEmpty || !clean.contains('@')) {
        return 'Please enter a valid email address.';
      }

      final otp = SmtpEmailService.generateOtp();
      _pendingRegOtp = otp;
      _regOtpExpiry = DateTime.now().add(const Duration(minutes: 10));
      _lastRegOtpSentTime = DateTime.now();

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
    } finally {
      _isSendingRegOtp = false;
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
  Future<String> sendVerificationOtpEmail({bool forceNew = false}) async {
    if (_isSendingVerificationOtp) {
      return 'SUCCESS'; // Operation already actively in-flight
    }
    // Rate limit duplicate calls within 15 seconds unless explicitly forced via Resend
    if (!forceNew && _lastVerificationOtpSentTime != null && DateTime.now().difference(_lastVerificationOtpSentTime!).inSeconds < 15) {
      return 'SUCCESS';
    }

    _isSendingVerificationOtp = true;
    try {
      final email = cloudEmail ?? FirebaseAuth.instance.currentUser?.email;
      if (email == null || email.isEmpty) {
        return 'No registered email address found for the current account.';
      }

      final otp = SmtpEmailService.generateOtp();
      _pendingVerificationOtp = otp;
      _verificationOtpExpiry = DateTime.now().add(const Duration(minutes: 10));
      _lastVerificationOtpSentTime = DateTime.now();

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
    } finally {
      _isSendingVerificationOtp = false;
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
              .delete()
              .timeout(const Duration(seconds: 4));
        } catch (e) {
          debugPrint('[AppState] Error deleting Firestore user doc: $e');
        }
      }

      // Delete phone mapping from gdrm_phones
      if (cloudPhone != null && cloudPhone!.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('gdrm_phones')
              .doc(cloudPhone)
              .delete()
              .timeout(const Duration(seconds: 4));
        } catch (e) {
          debugPrint('[AppState] Error deleting gdrm_phones doc: $e');
        }
      }

      // 2. Delete user in Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.delete().timeout(const Duration(seconds: 4));
        } catch (e) {
          debugPrint('[AppState] Firebase Auth user delete notice: $e');
        }
      }

      _pendingDeleteOtp = null;
      _deleteOtpExpiry = null;
      await logoutCloud();
      return 'SUCCESS';
    } catch (e) {
      return 'Error deleting account: $e';
    }
  }

  /// Permanently deletes the current account from Firestore, releases phone reservation, deletes from Firebase Auth, and clears local state.
  Future<String> deleteAccountDirectly() async {
    try {
      final usernameToDelete = cloudUsername;
      final phoneToDelete = cloudPhone;

      // 1. Delete user record in Firestore gdrm_users
      if (usernameToDelete != null && usernameToDelete.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('gdrm_users')
              .doc(usernameToDelete)
              .delete()
              .timeout(const Duration(seconds: 4));
        } catch (e) {
          debugPrint('[AppState] Error deleting Firestore user doc: $e');
        }
      }

      // 2. Delete phone reservation in gdrm_phones so phone number is free to register again
      if (phoneToDelete != null && phoneToDelete.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('gdrm_phones')
              .doc(phoneToDelete)
              .delete()
              .timeout(const Duration(seconds: 4));
        } catch (e) {
          debugPrint('[AppState] Error deleting gdrm_phones doc: $e');
        }
      }

      // 3. Delete Firebase Auth user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.delete().timeout(const Duration(seconds: 4));
        } catch (e) {
          debugPrint('[AppState] Firebase Auth user delete notice: $e');
        }
      }

      await logoutCloud();
      return 'SUCCESS';
    } catch (e) {
      debugPrint('[AppState] Error deleting account: $e');
      await logoutCloud();
      return 'SUCCESS';
    }
  }

  /// Completely wipes all data across Firebase Firestore collections:
  /// - gdrm_users (all registered user identities)
  /// - gdrm_phones (all registered unique phone reservations)
  /// - gdrm_piracy_alerts (all security and piracy alerts)
  /// - gdrm_snail_trails (all audit trails, and their 'events' subcollections)
  /// Also deletes the current authenticated Firebase user identity and signs out,
  /// giving a 100% clean, fresh slate.
  Future<String> clearEntireFirebaseDatabase() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Wipe gdrm_users
      try {
        final usersSnap = await firestore.collection('gdrm_users').get().timeout(const Duration(seconds: 8));
        for (final doc in usersSnap.docs) {
          try {
            await doc.reference.delete();
          } catch (e) {
            debugPrint('[AppState] Failed deleting user doc ${doc.id}: $e');
          }
        }
      } catch (e) {
        debugPrint('[AppState] Error querying gdrm_users for purge: $e');
      }

      // 2. Wipe gdrm_phones
      try {
        final phonesSnap = await firestore.collection('gdrm_phones').get().timeout(const Duration(seconds: 8));
        for (final doc in phonesSnap.docs) {
          try {
            await doc.reference.delete();
          } catch (e) {
            debugPrint('[AppState] Failed deleting phone doc ${doc.id}: $e');
          }
        }
      } catch (e) {
        debugPrint('[AppState] Error querying gdrm_phones for purge: $e');
      }

      // 3. Wipe gdrm_piracy_alerts
      try {
        final alertsSnap = await firestore.collection('gdrm_piracy_alerts').get().timeout(const Duration(seconds: 8));
        for (final doc in alertsSnap.docs) {
          try {
            await doc.reference.delete();
          } catch (e) {
            debugPrint('[AppState] Failed deleting alert doc ${doc.id}: $e');
          }
        }
      } catch (e) {
        debugPrint('[AppState] Error querying gdrm_piracy_alerts for purge: $e');
      }

      // 4. Wipe gdrm_snail_trails and events subcollections
      try {
        final trailsSnap = await firestore.collection('gdrm_snail_trails').get().timeout(const Duration(seconds: 8));
        for (final doc in trailsSnap.docs) {
          try {
            final eventsSnap = await doc.reference.collection('events').get().timeout(const Duration(seconds: 6));
            for (final ev in eventsSnap.docs) {
              try {
                await ev.reference.delete();
              } catch (_) {}
            }
            await doc.reference.delete();
          } catch (e) {
            debugPrint('[AppState] Failed deleting trail doc ${doc.id}: $e');
          }
        }
      } catch (e) {
        debugPrint('[AppState] Error querying gdrm_snail_trails for purge: $e');
      }

      // 5. Delete current auth user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.delete().timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('[AppState] Notice deleting current user during purge: $e');
        }
      }

      // 6. Reset all local state
      await logoutCloud();
      return 'SUCCESS';
    } catch (e) {
      debugPrint('[AppState] Error clearing Firebase database: $e');
      await logoutCloud();
      return 'Error: $e';
    }
  }

  Future<void> logoutCloud() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('[AppState] Error during signOut: $e');
    }
    cloudUsername = null;
    cloudDisplayName = null;
    cloudEmail = null;
    cloudUid = null;
    cloudPhone = null;
    cloudCountry = null;
    cloudState = null;
    cloudCity = null;
    isEmailVerified = false;
    _piracySub?.cancel();
    _piracySub = null;
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

  void clearLoadedFile() {
    if (tempPdfPath != null) {
      try {
        File(tempPdfPath!).delete();
      } catch (_) {}
    }
    tempPdfPath = null;
    manifest = GdrmMetadata.empty;
    isFileLoaded = false;
    pageNum = 0;
    zoomLevel = 1.0;
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