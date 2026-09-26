import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PiracyScreen extends StatefulWidget {
  const PiracyScreen({super.key});

  @override
  State<PiracyScreen> createState() => _PiracyScreenState();
}

class _PiracyScreenState extends State<PiracyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Pulsing warning icon ────────────────────────────────────────
            AnimatedBuilder(
              animation: _glow,
              builder: (_, __) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.08 * _glow.value),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.35 * _glow.value),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.gpp_bad_rounded,
                  size: 64,
                  color: Colors.red.withOpacity(0.6 + 0.4 * _glow.value),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Headline ────────────────────────────────────────────────────
            const Text(
              'PIRACY DETECTED',
              style: TextStyle(
                color: Colors.red,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),

            // ── Subtext ─────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'This file has already been activated on a different device.\n'
                'Sharing or redistributing GDRM-protected content is a violation\n'
                'of the licensing agreement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.fgMuted,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Info panel ──────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: Colors.redAccent, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'File is locked to its original recipient device.\n'
                      'Contact the content owner for a new licensed copy.',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ── Close button ────────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.bgGlassPanel,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderGlass),
                ),
                child: const Text(
                  'CLOSE FILE',
                  style: TextStyle(
                    color: AppTheme.fgMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
