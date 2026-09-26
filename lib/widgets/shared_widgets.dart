import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Glass Panel ───────────────────────────────────────────────────────────────
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppTheme.bgGlassPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
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
          hoverColor: AppTheme.bgGlassPanel.withOpacity(0.6),
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
  final Color valueColor;
  final bool isMono;

  const ManifestIndicator({
    super.key,
    required this.title,
    required this.value,
    this.valueColor = AppTheme.fgLight,
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
            style: const TextStyle(
              color: AppTheme.fgMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
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
  final Color fgColor;
  final IconData? icon;

  const ToolbarButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fgColor = AppTheme.fgLight,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(icon, color: fgColor, size: 14),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
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

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.fgMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.fgLight, fontSize: 13),
          decoration: InputDecoration(hintText: hint),
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
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.bgGlassPanel,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.colorCyan.withOpacity(0.7)),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.colorCyan,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.colorCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
