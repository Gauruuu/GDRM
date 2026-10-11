import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Glass Panel ───────────────────────────────────────────────────────────────
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.bgGlassPanel,
        border: Border.all(color: AppTheme.borderGlass),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}

// ── Nav Button ────────────────────────────────────────────────────────────────
class NavButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const NavButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: active ? AppTheme.bgGlassPanel : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          hoverColor: AppTheme.bgGlassPanel.withValues(alpha: 0.6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: active
                  ? Border.all(color: AppTheme.borderGlass)
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? AppTheme.fgLight : AppTheme.fgMuted,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Manifest Indicator ────────────────────────────────────────────────────────
class ManifestIndicator extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final bool isMono;

  const ManifestIndicator({
    super.key,
    required this.title,
    required this.value,
    this.valueColor,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: TextStyle(
              color: AppTheme.fgMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.fgLight,
              fontSize: 11,
              fontWeight: isMono ? FontWeight.normal : FontWeight.bold,
              fontFamily: isMono ? 'monospace' : null,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ── Toolbar Button ────────────────────────────────────────────────────────────
class ToolbarButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? fgColor;
  final IconData? icon;

  const ToolbarButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fgColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFg = fgColor ?? AppTheme.fgLight;
    return Material(
      color: AppTheme.bgGlassPanel,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        hoverColor: AppTheme.borderGlass,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.borderGlass),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: effectiveFg, size: 14),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: effectiveFg,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Labeled Text Field ────────────────────────────────────────────────────────
class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? prefixText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixText,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppTheme.fgMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          readOnly: readOnly,
          style: TextStyle(color: AppTheme.fgLight, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: TextStyle(
              color: AppTheme.colorCyan,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            suffixIcon: suffixIcon,
          ),
          cursorColor: AppTheme.colorCyan,
        ),
      ],
    );
  }
}

// ── Cyan Action Button ────────────────────────────────────────────────────────
class CyanActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const CyanActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Dashed Container ─────────────────────────────────────────────────────────
class DashedContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final BorderRadius borderRadius;

  const DashedContainer({
    super.key,
    required this.child,
    this.color,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
    this.dash = 6.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color ?? AppTheme.borderGlass,
        strokeWidth: strokeWidth,
        gap: gap,
        dash: dash,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final BorderRadius borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dash,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = borderRadius.toRRect(Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    ));

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dash <= metric.length) ? dash : metric.length - distance;
        canvas.drawPath(metric.extractPath(distance, distance + length), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.borderRadius != borderRadius;
}

// ── GDRM V — The Milky Way Update Brand Assets ────────────────────────────────
class GdrmVLogoBadge extends StatelessWidget {
  final double size;
  final bool showGlow;

  const GdrmVLogoBadge({
    super.key,
    this.size = 48,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  blurRadius: size * 0.3,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          'assets/images/gdrm_v_emblem.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback vector rendering in case asset is loading
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 1.5),
              ),
              child: Center(
                child: Text(
                  'V',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontSize: size * 0.52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class GdrmVWordmark extends StatelessWidget {
  final double height;

  const GdrmVWordmark({
    super.key,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/gdrm_v_banner.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GDRM',
              style: TextStyle(
                color: AppTheme.fgLight,
                fontSize: height * 0.65,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'V',
              style: TextStyle(
                color: const Color(0xFF10B981),
                fontSize: height * 0.75,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

