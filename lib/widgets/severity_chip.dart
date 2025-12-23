import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SeverityChip extends StatelessWidget {
  final String severity;
  final bool showIcon;

  const SeverityChip({
    super.key,
    required this.severity,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getSeverityColor(severity);
    final icon = _getIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            severity.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.warning_rounded;
      case 'medium':
        return Icons.info_rounded;
      case 'low':
      default:
        return Icons.check_circle_rounded;
    }
  }
}
