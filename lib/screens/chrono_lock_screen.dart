import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChronoLockScreen extends StatefulWidget {
  final DateTime unlockAtUtc;

  const ChronoLockScreen({super.key, required this.unlockAtUtc});

  @override
  State<ChronoLockScreen> createState() => _ChronoLockScreenState();
}

class _ChronoLockScreenState extends State<ChronoLockScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _remaining = Duration.zero;
  bool _unlocked = false;

  late AnimationController _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  void _updateRemaining() {
    final now = DateTime.now().toUtc();
    final diff = widget.unlockAtUtc.difference(now);
    if (!mounted) return;
    setState(() {
      if (diff.isNegative) {
        _remaining = Duration.zero;
        _unlocked = true;
        _timer.cancel();
      } else {
        _remaining = diff;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String _twoDigit(int n) => n.toString().padLeft(2, '0');

  String get _localUnlockLabel {
    final local = widget.unlockAtUtc.toLocal();
    final d = _twoDigit(local.day);
    final m = _twoDigit(local.month);
    final h = _twoDigit(local.hour);
    final min = _twoDigit(local.minute);
    return '$d/$m/${local.year}  $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final color = _unlocked ? Colors.greenAccent : AppTheme.colorAmber;

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _glow,
              builder: (_, __) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.08 * _glow.value),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35 * _glow.value),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  _unlocked
                      ? Icons.lock_open_rounded
                      : Icons.lock_clock_rounded,
                  size: 64,
                  color: color.withOpacity(0.6 + 0.4 * _glow.value),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              _unlocked ? 'DOCUMENT UNLOCKED' : 'CHRONOLOCK ACTIVE',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _unlocked
                    ? 'The unlock time has passed. Close this screen and\nreopen the file to view it.'
                    : 'This document is time-locked by its sender and\ncannot be opened yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.fgMuted,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 28),

            if (!_unlocked) _countdownPanel(),
            if (!_unlocked) const SizedBox(height: 16),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgGlassPanel,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderGlass),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded,
                      color: AppTheme.colorAmber, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Available at\n$_localUnlockLabel',
                      style: const TextStyle(
                        color: AppTheme.fgLight,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.bgGlassPanel,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderGlass),
                ),
                child: const Text(
                  'CLOSE',
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

  Widget _countdownPanel() {
    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (d > 0) _timeBlock(d, 'DAYS'),
        if (d > 0) _colon(),
        _timeBlock(h, 'HRS'),
        _colon(),
        _timeBlock(m, 'MIN'),
        _colon(),
        _timeBlock(s, 'SEC'),
      ],
    );
  }

  Widget _timeBlock(int value, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.bgGlassPanel,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.colorAmber.withOpacity(0.4)),
          ),
          child: Text(
            _twoDigit(value),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.colorAmber,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: AppTheme.fgMuted, fontSize: 9, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _colon() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(':',
          style: TextStyle(
              color: AppTheme.fgMuted,
              fontSize: 20,
              fontWeight: FontWeight.bold)),
    );
  }
}
