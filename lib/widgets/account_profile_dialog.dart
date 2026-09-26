import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../screens/global_auth_screen.dart';
import '../screens/piracy_alerts_screen.dart';

/// Opens the GDRM Account Profile & Settings dialog on any platform (Desktop / Mobile).
void showAccountProfileDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogCtx) => const AccountProfileDialog(),
  );
}

class AccountProfileDialog extends StatelessWidget {
  const AccountProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark slate glass
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.colorCyan.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header & Close ──
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.colorCyan.withOpacity(0.2),
                  child: Text(
                    state.cloudDisplayName?.isNotEmpty == true
                        ? state.cloudDisplayName![0].toUpperCase()
                        : (state.cloudUsername?.isNotEmpty == true
                            ? state.cloudUsername![0].toUpperCase()
                            : 'U'),
                    style: const TextStyle(
                      color: AppTheme.colorCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.cloudDisplayName?.isNotEmpty == true
                            ? state.cloudDisplayName!
                            : (state.cloudUsername ?? 'GDRM User'),
                        style: const TextStyle(
                          color: AppTheme.fgLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        state.cloudUsername != null ? '@${state.cloudUsername}' : 'Unauthenticated',
                        style: const TextStyle(
                          color: AppTheme.colorCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.fgMuted, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: AppTheme.borderGlass),
            const SizedBox(height: 14),

            // ── Email & Verification Status ──
            if (state.cloudEmail != null && state.cloudEmail!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderGlass),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: AppTheme.fgMuted, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('REGISTERED EMAIL', style: TextStyle(color: AppTheme.fgMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(
                            state.cloudEmail!,
                            style: const TextStyle(color: AppTheme.fgLight, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _showVerifyEmailOtpDialog(context, state);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: state.isEmailVerified
                              ? Colors.greenAccent.withOpacity(0.15)
                              : AppTheme.colorCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: state.isEmailVerified
                                ? Colors.greenAccent.withOpacity(0.5)
                                : AppTheme.colorCyan.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              state.isEmailVerified ? Icons.check_circle_rounded : Icons.mark_email_read_rounded,
                              size: 13,
                              color: state.isEmailVerified ? Colors.greenAccent : AppTheme.colorCyan,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              state.isEmailVerified ? 'Verified' : 'Verify Email (OTP)',
                              style: TextStyle(
                                color: state.isEmailVerified ? Colors.greenAccent : AppTheme.colorCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Piracy & Security Alerts Button ──
            if (state.cloudUsername != null)
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PiracyAlertsScreen(senderUsername: state.cloudUsername!),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: state.unreadPiracyAlertsCount > 0
                        ? Colors.redAccent.withOpacity(0.12)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
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
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'SECURITY & PIRACY ALERTS',
                          style: TextStyle(
                            color: state.unreadPiracyAlertsCount > 0
                                ? Colors.redAccent
                                : AppTheme.fgLight,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (state.unreadPiracyAlertsCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.unreadPiracyAlertsCount} NEW',
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

            const SizedBox(height: 20),
            const Divider(color: AppTheme.borderGlass),
            const SizedBox(height: 14),

            // ── Primary Actions: Switch User & Sign Out ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.colorCyan,
                      side: BorderSide(color: AppTheme.colorCyan.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('SWITCH USER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GlobalAuthScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.18),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('SIGN OUT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      state.logoutCloud();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── App Version Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.colorCyan.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.colorCyan.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.colorCyan, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'GDRM IV — ASTEROID BELT (v4.0.0)',
                    style: TextStyle(
                      color: AppTheme.colorCyan,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Danger Zone: Delete Account Option ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DELETE GDRM ACCOUNT',
                          style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        Text(
                          'Erase credentials & identity with SMTP OTP verification',
                          style: TextStyle(color: AppTheme.fgMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      _showDeleteAccountOtpDialog(context, state);
                    },
                    child: const Text('DELETE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerifyEmailOtpDialog(BuildContext context, AppState state) {
    final email = state.cloudEmail ?? '';
    final otpCtrl = TextEditingController();
    bool isSending = true;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (isSending) {
              Future.microtask(() async {
                final res = await state.sendVerificationOtpEmail();
                if (ctx.mounted) {
                  setModalState(() {
                    isSending = false;
                    if (res != 'SUCCESS') {
                      errorText = res;
                    }
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.colorCyan, width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.mark_email_read_rounded, color: AppTheme.colorCyan, size: 22),
                  SizedBox(width: 10),
                  Text('Verify Email with OTP', style: TextStyle(color: AppTheme.fgLight, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'We sent a 6-digit verification code via Gmail SMTP to:',
                    style: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(color: AppTheme.colorCyan, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (isSending)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(color: AppTheme.colorCyan),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: '000000',
                        hintStyle: TextStyle(color: AppTheme.fgMuted.withOpacity(0.4), letterSpacing: 8),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.borderGlass),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.colorCyan, width: 1.5),
                        ),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                    ],
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.fgMuted)),
                ),
                if (!isSending)
                  TextButton(
                    onPressed: () async {
                      setModalState(() {
                        isSending = true;
                        errorText = null;
                      });
                      final res = await state.sendVerificationOtpEmail();
                      if (ctx.mounted) {
                        setModalState(() {
                          isSending = false;
                          if (res != 'SUCCESS') {
                            errorText = res;
                          } else {
                            errorText = 'A new code has been sent!';
                          }
                        });
                      }
                    },
                    child: const Text('RESEND CODE', style: TextStyle(color: AppTheme.colorCyan, fontSize: 11)),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorCyan,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: isSending
                      ? null
                      : () async {
                          final code = otpCtrl.text.trim();
                          if (code.length != 6) {
                            setModalState(() => errorText = 'Please enter all 6 digits of the OTP code.');
                            return;
                          }
                          final res = await state.verifyEmailOtp(code);
                          if (res == 'SUCCESS') {
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF1E293B),
                                  content: Text('✓ Email verified successfully via SMTP OTP!', style: TextStyle(color: Colors.greenAccent)),
                                ),
                              );
                            }
                          } else {
                            setModalState(() => errorText = res);
                          }
                        },
                  child: const Text('VERIFY', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountOtpDialog(BuildContext context, AppState state) {
    final email = state.cloudEmail ?? '';
    final otpCtrl = TextEditingController();
    bool isSending = true;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (isSending) {
              Future.microtask(() async {
                final res = await state.sendDeleteAccountOtpEmail();
                if (ctx.mounted) {
                  setModalState(() {
                    isSending = false;
                    if (res != 'SUCCESS') {
                      errorText = res;
                    }
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                  SizedBox(width: 10),
                  Text('Delete Account Permanently', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ CAUTION: This will permanently delete your GDRM registered identity, account handle, and cryptographic credentials. This action cannot be reversed.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'To confirm deletion, enter the 6-digit OTP sent to:',
                    style: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(color: AppTheme.colorCyan, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (isSending)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(color: Colors.redAccent),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: '000000',
                        hintStyle: TextStyle(color: AppTheme.fgMuted.withOpacity(0.4), letterSpacing: 8),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.borderGlass),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                        ),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                    ],
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.fgMuted)),
                ),
                if (!isSending)
                  TextButton(
                    onPressed: () async {
                      setModalState(() {
                        isSending = true;
                        errorText = null;
                      });
                      final res = await state.sendDeleteAccountOtpEmail();
                      if (ctx.mounted) {
                        setModalState(() {
                          isSending = false;
                          if (res != 'SUCCESS') {
                            errorText = res;
                          } else {
                            errorText = 'A new deletion code has been sent!';
                          }
                        });
                      }
                    },
                    child: const Text('RESEND CODE', style: TextStyle(color: AppTheme.colorCyan, fontSize: 11)),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSending
                      ? null
                      : () async {
                          final code = otpCtrl.text.trim();
                          if (code.length != 6) {
                            setModalState(() => errorText = 'Please enter all 6 digits of the OTP code.');
                            return;
                          }
                          final res = await state.verifyAndDeleteAccount(code);
                          if (res == 'SUCCESS') {
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            if (context.mounted) {
                              Navigator.pop(context); // close profile modal
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF1E293B),
                                  content: Text('✓ Account permanently deleted.', style: TextStyle(color: Colors.redAccent)),
                                ),
                              );
                            }
                          } else {
                            setModalState(() => errorText = res);
                          }
                        },
                  child: const Text('PERMANENTLY DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
