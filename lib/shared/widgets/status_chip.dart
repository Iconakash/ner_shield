import 'package:flutter/material.dart';

/// Encodes a status using label + icon + color (never color alone —
/// accessibility requirement, docs/ui-ux-plan.md).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    this.backgroundColor,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color? backgroundColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final effective = backgroundColor ?? color.withValues(alpha: 0.12);
    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: effective,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 15, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11 : 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Semantic status helpers for the standard road/segment vocabulary.
abstract final class RoadStatusVisuals {
  static const statusOpen = 'OPEN';
  static const statusPartial = 'PARTIAL';
  static const statusClosed = 'CLOSED';
  static const statusUnknown = 'UNKNOWN';

  static (String, IconData, Color) of(String status) {
    return switch (status.toUpperCase()) {
      'OPEN' || 'OPENED' => ('Open', Icons.check_circle_outline, const Color(0xFF1E7A3C)),
      'PARTIAL' => ('Partial', Icons.warning_amber_rounded, const Color(0xFF9A6A00)),
      'CLOSED' || 'BLOCKED' => ('Blocked', Icons.block, const Color(0xFFBA1A1A)),
      _ => ('Unknown', Icons.help_outline, const Color(0xFF5E5E66)),
    };
  }

  static StatusChip chip(String status) {
    final (label, icon, color) = of(status);
    return StatusChip(label: label, icon: icon, color: color);
  }
}

/// Severity helpers for the alert/incident vocabulary.
abstract final class SeverityVisuals {
  static (String, IconData, Color) of(String severity) {
    return switch (severity.toUpperCase()) {
      'LOW' || 'INFO' => ('Low', Icons.info_outline, const Color(0xFF00639C)),
      'MEDIUM' || 'WARNING' => ('Medium', Icons.warning_amber_rounded, const Color(0xFF9A6A00)),
      'HIGH' => ('High', Icons.error_outline, const Color(0xFFB54008)),
      'CRITICAL' => ('Critical', Icons.crisis_alert, const Color(0xFFBA1A1A)),
      _ => ('Unknown', Icons.help_outline, const Color(0xFF5E5E66)),
    };
  }

  static StatusChip chip(String severity) {
    final (label, icon, color) = of(severity);
    return StatusChip(label: label, icon: icon, color: color);
  }
}