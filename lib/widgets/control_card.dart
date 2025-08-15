import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ControlCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String buttonText;
  final double level;
  final Color levelColor;
  final String levelLabel;
  final VoidCallback onPressed;

  const ControlCard({
    super.key,
    required this.title,
    required this.icon,
    required this.buttonText,
    required this.level,
    required this.levelColor,
    required this.levelLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Create a soft gradient using levelColor
    final gradientColors = [
      levelColor.withOpacity(0.9),
      levelColor.withOpacity(0.6),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              Icon(icon, size: 28, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Level Label
          Text(
            levelLabel,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 6),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: level,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 6),

          // Level Percentage
          Text(
            '${(level * 100).toInt()}% full',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20, color: levelColor),
              label: Text(
                buttonText,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: levelColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: levelColor,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
