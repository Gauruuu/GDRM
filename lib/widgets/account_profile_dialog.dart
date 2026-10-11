import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../screens/global_auth_screen.dart';
import '../screens/piracy_alerts_screen.dart';
import 'shared_widgets.dart';

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
          color: AppTheme.bgGlassPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.colorCyan.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowDeep,
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
                  backgroundColor: AppTheme.colorCyan.withValues(alpha: 0.2),
                  child: Text(
                    state.cloudDisplayName?.isNotEmpty == true
                        ? state.cloudDisplayName![0].toUpperCase()
                        : (state.cloudUsername?.isNotEmpty == true
                            ? state.cloudUsername![0].toUpperCase()
                            : 'U'),
                    style: TextStyle(
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
                        style: TextStyle(
                          color: AppTheme.fgLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        state.cloudUsername != null ? '@${state.cloudUsername}' : 'Unauthenticated',
                        style: TextStyle(
                          color: AppTheme.colorCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppTheme.fgMuted, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: AppTheme.borderGlass),
            const SizedBox(height: 14),

            // ── Email & Verification Status ──
            if (state.cloudEmail != null && state.cloudEmail!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderGlass),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: AppTheme.fgMuted, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('REGISTERED EMAIL', style: TextStyle(color: AppTheme.fgMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(
                            state.cloudEmail!,
                            style: TextStyle(color: AppTheme.fgLight, fontSize: 13, fontWeight: FontWeight.w500),
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
                              ? Colors.greenAccent.withValues(alpha: 0.15)
                              : AppTheme.colorCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: state.isEmailVerified
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : AppTheme.colorCyan.withValues(alpha: 0.5),
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
                              state.isEmailVerified ? 'VERIFIED' : 'VERIFY EMAIL',
                              style: TextStyle(
                                color: state.isEmailVerified ? Colors.greenAccent : AppTheme.colorCyan,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
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

            // ── Mobile Number ──
            if (state.cloudPhone != null && state.cloudPhone!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderGlass),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone_iphone_rounded, color: AppTheme.fgMuted, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MOBILE NUMBER', style: TextStyle(color: AppTheme.fgMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(
                            state.cloudPhone!,
                            style: TextStyle(color: AppTheme.fgLight, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Text('LINKED', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Location Details (Country, State, City) ──
            if ((state.cloudCountry != null && state.cloudCountry!.isNotEmpty) ||
                (state.cloudCity != null && state.cloudCity!.isNotEmpty)) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderGlass),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: AppTheme.fgMuted, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('JURISDICTION / LOCATION', style: TextStyle(color: AppTheme.fgMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (state.cloudCity != null && state.cloudCity!.isNotEmpty) state.cloudCity,
                              if (state.cloudState != null && state.cloudState!.isNotEmpty) state.cloudState,
                              if (state.cloudCountry != null && state.cloudCountry!.isNotEmpty) state.cloudCountry,
                            ].join(', '),
                            style: TextStyle(color: AppTheme.fgLight, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],


            // ── Piracy & Threat Alert Quick Action ──
            if (state.cloudUsername != null)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PiracyAlertsScreen(senderUsername: state.cloudUsername!),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: state.unreadPiracyAlertsCount > 0
                        ? Colors.redAccent.withValues(alpha: 0.12)
                        : (AppTheme.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: state.unreadPiracyAlertsCount > 0
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : AppTheme.borderGlass,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.unreadPiracyAlertsCount > 0 ? Icons.warning_amber_rounded : Icons.shield_outlined,
                        color: state.unreadPiracyAlertsCount > 0 ? Colors.redAccent : AppTheme.colorCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PIRACY & INCIDENT ALERTS',
                              style: TextStyle(
                                color: state.unreadPiracyAlertsCount > 0 ? Colors.redAccent : AppTheme.fgLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              state.unreadPiracyAlertsCount > 0
                                  ? '${state.unreadPiracyAlertsCount} unread piracy / failed auth warning(s)'
                                  : 'Real-time copyright enforcement logs',
                              style: TextStyle(
                                color: state.unreadPiracyAlertsCount > 0 ? Colors.redAccent : AppTheme.fgMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.unreadPiracyAlertsCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
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
            Divider(color: AppTheme.borderGlass),
            const SizedBox(height: 14),

            // ── Primary Actions: Switch User & Sign Out ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.colorCyan,
                      side: BorderSide(color: AppTheme.colorCyan.withValues(alpha: 0.5)),
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
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.18),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('SIGN OUT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      Navigator.pop(context);
                      await state.logoutCloud();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.bgGlassPanel,
                            content: Row(
                              children: [
                                const Icon(Icons.logout_rounded, color: Colors.orangeAccent, size: 16),
                                const SizedBox(width: 8),
                                Text('Signed out successfully. Now in Guest mode.',
                                    style: TextStyle(color: AppTheme.fgLight, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── App Version Banner: GDRM V The Milky Way Update ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const GdrmVLogoBadge(size: 22, showGlow: false),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'GDRM V — THE MILKY WAY UPDATE (v5.0.0)',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
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
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DELETE GDRM ACCOUNT',
                          style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        Text(
                          'Erase credentials, release mobile number, & re-register',
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
                      _showConfirmDeleteAccountDialog(context, state);
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

  void _showConfirmDeleteAccountDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgGlassPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text('Delete Account & Re-Register', style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permanently delete account @${state.cloudUsername ?? ""}?',
              style: TextStyle(color: AppTheme.fgLight, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'This will erase your account credentials, release your mobile number and username in the cloud registry, and redirect you to register a fresh new account.',
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 11.5, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('CANCEL', style: TextStyle(color: AppTheme.fgMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx); // close confirmation
              Navigator.pop(context); // close profile modal

              await state.deleteAccountDirectly();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.bgGlassPanel,
                    content: Row(
                      children: [
                        const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Text('Account deleted. Redirecting to registration...',
                            style: TextStyle(color: AppTheme.fgLight, fontSize: 12)),
                      ],
                    ),
                  ),
                );

                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GlobalAuthScreen(startInRegisterMode: true)),
                );
              }
            },
            child: const Text('DELETE & CREATE NEW ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
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
              backgroundColor: AppTheme.bgGlassPanel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppTheme.colorCyan, width: 1.5),
              ),
              title: Row(
                children: [
                  Icon(Icons.mark_email_read_rounded, color: AppTheme.colorCyan, size: 22),
                  const SizedBox(width: 10),
                  Text('Verify Email with OTP', style: TextStyle(color: AppTheme.fgLight, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We sent a 6-digit verification code via Gmail SMTP to:',
                    style: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: AppTheme.colorCyan, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (isSending)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                        hintStyle: TextStyle(color: AppTheme.fgMuted.withValues(alpha: 0.4), letterSpacing: 8),
                        counterText: '',
                        filled: true,
                        fillColor: AppTheme.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.borderGlass),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.colorCyan, width: 1.5),
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
                  child: Text('CANCEL', style: TextStyle(color: AppTheme.fgMuted)),
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
                    child: Text('RESEND CODE', style: TextStyle(color: AppTheme.colorCyan, fontSize: 11)),
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
                                SnackBar(
                                  backgroundColor: AppTheme.isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                                  content: const Text('✓ Email verified successfully via SMTP OTP!', style: TextStyle(color: Colors.greenAccent)),
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
}
