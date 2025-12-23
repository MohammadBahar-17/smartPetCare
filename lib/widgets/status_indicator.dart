import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StatusIndicator extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final bool isAlert;

  const StatusIndicator({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? 
        (isAlert ? AppTheme.severityHigh : Theme.of(context).colorScheme.primary);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: displayColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: displayColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: displayColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
