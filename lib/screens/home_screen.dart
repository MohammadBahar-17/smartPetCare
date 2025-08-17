import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_camera_widget.dart';
import '../widgets/control_card.dart';
import '../widgets/quick_stats.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final double foodLevel = 0.65;
  final double waterLevel = 0.35;

  bool entertainmentOn = false; // Track ON/OFF state

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.warmGradient,
                borderRadius: AppTheme.cardRadius,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_getTimeOfDay()}!',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your pets are doing great today',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('🐾', style: TextStyle(fontSize: 32)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats
            const QuickStats(),
            const SizedBox(height: 24),

            // Camera Feed Card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: AppTheme.cardRadius,
                boxShadow: AppTheme.cardShadow,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Live Camera Feed',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: AppTheme.buttonRadius,
                    child: const SmartCameraWidget(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Control Cards Row
            Row(
              children: [
                Expanded(
                  child: ControlCard(
                    title: "Food",
                    icon: Icons.restaurant_rounded,
                    buttonText: "Feed Now",
                    level: foodLevel,
                    levelColor: AppTheme.warmYellow,
                    levelLabel: "Food Level",
                    isCompact: true,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('🍽️ Feeding your pet...'),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.buttonRadius,
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ControlCard(
                    title: "Water",
                    icon: Icons.water_drop_rounded,
                    buttonText: "Refill",
                    level: waterLevel,
                    levelColor: AppTheme.lightBlue,
                    levelLabel: "Water Level",
                    isCompact: true,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('💧 Dispensing water...'),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.buttonRadius,
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Entertainment System
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: AppTheme.cardRadius,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: entertainmentOn
                              ? AppTheme.success.withOpacity(0.2)
                              : AppTheme.textLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.smart_toy_rounded,
                          color: entertainmentOn
                              ? AppTheme.success
                              : AppTheme.textLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Entertainment System',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entertainmentOn
                                  ? 'System Active'
                                  : 'System Inactive',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: entertainmentOn
                                        ? AppTheme.success
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entertainmentOn
                                  ? 'Keeping your pet entertained'
                                  : 'Tap to activate entertainment',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: entertainmentOn,
                        activeColor: AppTheme.success,
                        onChanged: (value) {
                          setState(() {
                            entertainmentOn = value;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                entertainmentOn
                                    ? '🎮 Entertainment System activated'
                                    : '⏸️ Entertainment System deactivated',
                              ),
                              backgroundColor: entertainmentOn
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.buttonRadius,
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
