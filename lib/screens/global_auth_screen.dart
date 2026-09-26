import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/shared_widgets.dart';

class GlobalAuthScreen extends StatefulWidget {
  final bool startInRegisterMode;

  const GlobalAuthScreen({super.key, this.startInRegisterMode = false});

  @override
  State<GlobalAuthScreen> createState() => _GlobalAuthScreenState();
}

class _GlobalAuthScreenState extends State<GlobalAuthScreen> {
  late bool _isRegisterMode;
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  String? _statusMessage;
  Color _statusColor = Colors.redAccent;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.startInRegisterMode;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim().toLowerCase();
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text.trim();

    if (_isRegisterMode) {
      if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
        setState(() {
          _statusMessage = 'All fields (Name, Username, Email, Password) are required.';
          _statusColor = Colors.redAccent;
        });
        return;
      }

      if (username.length < 3) {
        setState(() {
          _statusMessage = 'Username must be at least 3 characters long.';
          _statusColor = Colors.redAccent;
        });
        return;
      }

      if (password.length < 6) {
        setState(() {
          _statusMessage = 'Password must be at least 6 characters.';
          _statusColor = Colors.redAccent;
        });
        return;
      }

      if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(username)) {
        setState(() {
          _statusMessage = 'Username must contain only letters, numbers, and underscores (3-24 chars).';
          _statusColor = Colors.redAccent;
        });
        return;
      }

      if (!email.contains('@') || !email.contains('.')) {
        setState(() {
          _statusMessage = 'Please enter a valid email address.';
          _statusColor = Colors.redAccent;
        });
        return;
      }

      // Trigger registration email OTP verification directly
      await _showRegistrationOtpDialog(
        name: name,
        username: username,
        email: email,
        password: password,
      );
    } else {
      // ── Login Mode ──
      final identifier = _usernameCtrl.text.trim();
      if (identifier.isEmpty || password.isEmpty) {
        setState(() {
          _statusMessage = 'Username/Email and Password are required.';
          _statusColor = Colors.redAccent;
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _statusMessage = null;
      });

      try {
        final state = context.read<AppState>();
        final result = await state.loginToCloud(identifier, password);

        if (!mounted) return;

        if (result == 'SUCCESS') {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _statusColor = Colors.redAccent;
            _statusMessage = result;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _statusColor = Colors.redAccent;
            _statusMessage = 'An error occurred: $e';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _showRegistrationOtpDialog({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final state = context.read<AppState>();
    final otpCtrl = TextEditingController();
    bool isSending = true;
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (isSending) {
              Future.microtask(() async {
                final res = await state.sendRegistrationOtp(email);
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
                  Text('Verify Email to Register',
                      style: TextStyle(color: AppTheme.fgLight, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To complete your GDRM account creation, enter the 6-digit verification code sent to:',
                    style: TextStyle(color: AppTheme.fgMuted, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 6),
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
                        hintStyle: TextStyle(color: AppTheme.fgMuted.withValues(alpha: 0.4), letterSpacing: 8),
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
                      final res = await state.sendRegistrationOtp(email);
                      if (ctx.mounted) {
                        setModalState(() {
                          isSending = false;
                          if (res != 'SUCCESS') {
                            errorText = res;
                          } else {
                            errorText = 'A fresh verification code has been sent!';
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
                          final isValid = state.validateRegistrationOtp(code);
                          if (!isValid) {
                            setModalState(() => errorText = 'Invalid or expired OTP code. Please try again.');
                            return;
                          }

                          setModalState(() => isSending = true);

                          final regResult = await state.registerOnCloud(
                            name: name,
                            username: username,
                            email: email,
                            password: password,
                          );

                          if (regResult == 'SUCCESS') {
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppTheme.bgGlassPanel,
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Welcome, $name! Account @$username verified & created.',
                                          style: const TextStyle(color: AppTheme.fgLight, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                              Navigator.of(context).pop(true);
                            }
                          } else {
                            setModalState(() {
                              isSending = false;
                              if (regResult == 'USERNAME_TAKEN') {
                                errorText = 'Username @$username is already taken.';
                              } else if (regResult == 'EMAIL_TAKEN') {
                                errorText = 'This email is already in use.';
                              } else {
                                errorText = regResult;
                              }
                            });
                          }
                        },
                  child: const Text('VERIFY & CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleForgotPassword() async {
    final resetCtrl = TextEditingController(text: _usernameCtrl.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgGlassSidebar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.colorCyan),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppTheme.colorCyan),
            SizedBox(width: 8),
            Text('Reset Account Password', style: TextStyle(color: AppTheme.fgLight, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered Username handle or Email address. We will dispatch a password recovery link to your inbox free of charge.',
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetCtrl,
              style: const TextStyle(color: AppTheme.fgLight, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'e.g. gaurav or gaurav@example.com',
                labelText: 'Username or Email',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppTheme.fgMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colorCyan, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, resetCtrl.text.trim()),
            child: const Text('SEND RESET LINK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || !mounted) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final state = context.read<AppState>();
    final res = await state.sendPasswordResetEmail(result);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.startsWith('SUCCESS')) {
        final email = res.split(':').last;
        _statusColor = Colors.greenAccent;
        _statusMessage = '✓ Password reset email sent to $email. Please check your inbox / spam folder.';
      } else {
        _statusColor = Colors.redAccent;
        _statusMessage = res;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.fgLight, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 12),
          child: Container(
            width: 440,
            padding: EdgeInsets.all(isWide ? 28 : 20),
            decoration: BoxDecoration(
              color: AppTheme.bgGlassSidebar,
              border: Border.all(color: AppTheme.borderGlass),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.colorCyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.colorCyan.withOpacity(0.4)),
                    ),
                    child: Icon(
                      _isRegisterMode ? Icons.person_add_alt_1_rounded : Icons.shield_rounded,
                      color: AppTheme.colorCyan,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isRegisterMode ? 'CREATE GDRM IDENTITY' : 'GDRM SYSTEM LOGIN',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.fgLight,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRegisterMode
                      ? 'Register your custom preferred username handle for secure file locking'
                      : 'Authenticate to access username-locked files and cryptographic services',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.fgMuted, fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 16),

                // ── Mode Switcher Tab ──
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.bgMain,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderGlass),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isRegisterMode = false;
                            _statusMessage = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isRegisterMode ? AppTheme.colorCyan.withOpacity(0.18) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: !_isRegisterMode ? Border.all(color: AppTheme.colorCyan.withOpacity(0.5)) : null,
                            ),
                            child: Text(
                              'SIGN IN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !_isRegisterMode ? AppTheme.colorCyan : AppTheme.fgMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isRegisterMode = true;
                            _statusMessage = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isRegisterMode ? AppTheme.colorCyan.withOpacity(0.18) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: _isRegisterMode ? Border.all(color: AppTheme.colorCyan.withOpacity(0.5)) : null,
                            ),
                            child: Text(
                              'REGISTER',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isRegisterMode ? AppTheme.colorCyan : AppTheme.fgMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                if (_isRegisterMode) ...[
                  LabeledTextField(
                    label: 'Full Name',
                    controller: _nameCtrl,
                    hint: 'e.g. Gaurav Sharma',
                  ),
                  LabeledTextField(
                    label: 'Preferred Username Handle',
                    controller: _usernameCtrl,
                    hint: 'e.g. gaurav (lowercase, numbers, _)',
                  ),
                  LabeledTextField(
                    label: 'Email Address',
                    controller: _emailCtrl,
                    hint: 'e.g. gaurav@example.com',
                  ),
                ] else ...[
                  LabeledTextField(
                    label: 'Username or Email Address',
                    controller: _usernameCtrl,
                    hint: 'e.g. gaurav or gaurav@example.com',
                  ),
                ],

                LabeledTextField(
                  label: 'Account Password',
                  controller: _passwordCtrl,
                  hint: '••••••••',
                ),

                if (!_isRegisterMode) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppTheme.colorCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                if (_statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                CyanActionButton(
                  label: _isRegisterMode ? 'CREATE GDRM IDENTITY' : 'SIGN IN TO ECOSYSTEM',
                  onTap: _handleSubmit,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _statusMessage = null;
                      });
                    },
                    child: Text(
                      _isRegisterMode
                          ? 'Already registered? Sign In instead'
                          : "Don't have an identity handle? Register Account",
                      style: const TextStyle(
                        color: AppTheme.colorCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}