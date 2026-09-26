import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/shared_widgets.dart';
import 'global_auth_screen.dart';

class CloudAuthScreen extends StatefulWidget {
  final String targetUsername;

  const CloudAuthScreen({super.key, required this.targetUsername});

  @override
  State<CloudAuthScreen> createState() => _CloudAuthScreenState();
}

class _CloudAuthScreenState extends State<CloudAuthScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameCtrl.text = widget.targetUsername;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final state = context.read<AppState>();
    final result = await state.loginToCloud(_usernameCtrl.text, _passwordCtrl.text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result == 'SUCCESS') {
      if (state.cloudUsername?.toLowerCase() == widget.targetUsername.toLowerCase()) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage =
              'Signed in as @${state.cloudUsername}, but this file requires user @${widget.targetUsername}.';
        });
      }
    } else {
      setState(() {
        _errorMessage = result;
      });
    }
  }

  Future<void> _openRegister() async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const GlobalAuthScreen(startInRegisterMode: true),
      ),
    );

    if (registered == true && mounted) {
      final state = context.read<AppState>();
      if (state.cloudUsername?.toLowerCase() == widget.targetUsername.toLowerCase()) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.fgLight, size: 18),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.bgGlassSidebar,
              border: Border.all(color: AppTheme.borderGlass),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.colorCyan.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.colorCyan.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.lock_person_rounded, color: AppTheme.colorCyan, size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'USERNAME RECIPIENT LOCK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.fgLight,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.colorCyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.colorCyan.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'This .gdrm document is encrypted exclusively for recipient:',
                        style: TextStyle(color: AppTheme.fgMuted, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '@${widget.targetUsername}',
                        style: const TextStyle(
                          color: AppTheme.colorCyan,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (state.isCloudAuthenticated) ...[
                  Text(
                    'Currently logged in as @${state.cloudUsername}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.fgMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                ],

                LabeledTextField(
                  label: 'Receiver Username or Email',
                  controller: _usernameCtrl,
                  hint: 'e.g. ${widget.targetUsername}',
                ),
                LabeledTextField(
                  label: 'Account Password',
                  controller: _passwordCtrl,
                  hint: '••••••••',
                ),
                const SizedBox(height: 14),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                CyanActionButton(
                  label: 'VERIFY RECIPIENT & UNLOCK',
                  onTap: _handleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _openRegister,
                    child: const Text(
                      'Need an account? Register with this username',
                      style: TextStyle(
                        color: AppTheme.colorCyan,
                        fontSize: 12,
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