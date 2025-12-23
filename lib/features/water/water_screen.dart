import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/loading_indicator.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _firebase = FirebaseService();

  // Sensor data
  bool dishEmpty = false;
  bool drainFull = false;
  bool tankFull = false;
  bool isDraining = false;
  bool waterLow = false;
  int tankPercentage = 0;

  // Subscriptions
  StreamSubscription<DatabaseEvent>? _subSensors;
  StreamSubscription<DatabaseEvent>? _subStatus;
  StreamSubscription<DatabaseEvent>? _subAlerts;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initListeners();
  }

  @override
  void dispose() {
    _subSensors?.cancel();
    _subStatus?.cancel();
    _subAlerts?.cancel();
    super.dispose();
  }

  void _initListeners() {
    _subSensors = _firebase.waterSensorsStream().listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null || !mounted) return;

      setState(() {
        dishEmpty = (data['dish_empty'] ?? false) == true;
        drainFull = (data['drain_full'] ?? false) == true;
        tankFull = (data['tank_full'] ?? false) == true;
        tankPercentage = (data['tank_percentage'] as int?) ?? 0;
        _isLoading = false;
      });
    });

    _subStatus = _firebase.waterStatusStream().listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null || !mounted) return;

      setState(() {
        isDraining = (data['is_draining'] ?? false) == true;
      });
    });

    _subAlerts = _firebase.waterAlertsStream().listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null || !mounted) return;

      setState(() {
        waterLow = (data['water_low'] ?? false) == true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("💧 Water System")),
        body: const LoadingIndicator(message: "Loading water data..."),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("💧 Water System"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Just triggers listeners
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTankCard(),
              const SizedBox(height: AppTheme.spacingLg),
              _buildStatusSection(),
              const SizedBox(height: AppTheme.spacingLg),
              _buildControlSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTankCard() {
    Color tankColor;
    IconData tankIcon;
    String tankStatus;

    if (tankPercentage < 20) {
      tankColor = AppTheme.severityHigh;
      tankIcon = Icons.water_drop_outlined;
      tankStatus = "Critical - Refill needed!";
    } else if (tankPercentage < 50) {
      tankColor = AppTheme.severityMedium;
      tankIcon = Icons.water_drop;
      tankStatus = "Low - Consider refilling";
    } else {
      tankColor = AppTheme.severityLow;
      tankIcon = Icons.water;
      tankStatus = "Good";
    }

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tankColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  tankIcon,
                  size: 48,
                  color: tankColor,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Water Tank",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tankStatus,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: tankColor,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                "$tankPercentage%",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tankColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: tankPercentage / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(tankColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "System Status",
          icon: Icons.monitor_heart,
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _buildStatusTile(
              "Tank Full",
              tankFull,
              Icons.check_circle_outline,
              Icons.radio_button_unchecked,
            ),
            _buildStatusTile(
              "Dish Empty",
              dishEmpty,
              Icons.warning_amber,
              Icons.check_circle_outline,
              invertColors: true,
            ),
            _buildStatusTile(
              "Drain Full",
              drainFull,
              Icons.warning_amber,
              Icons.check_circle_outline,
              invertColors: true,
            ),
            _buildStatusTile(
              "Water Low Alert",
              waterLow,
              Icons.notification_important,
              Icons.notifications_off_outlined,
              invertColors: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusTile(
    String title,
    bool isActive,
    IconData activeIcon,
    IconData inactiveIcon, {
    bool invertColors = false,
  }) {
    final showPositive = invertColors ? !isActive : isActive;
    final color = showPositive ? AppTheme.severityLow : Colors.grey;
    final icon = isActive ? activeIcon : inactiveIcon;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  isActive ? "Yes" : "No",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: showPositive
                            ? AppTheme.severityLow
                            : invertColors
                                ? AppTheme.severityMedium
                                : Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Controls",
          icon: Icons.tune,
        ),
        AppCard(
          color: isDraining
              ? AppTheme.warningColor.withValues(alpha: 0.1)
              : null,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDraining
                          ? AppTheme.warningColor.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDraining ? Icons.water : Icons.water_drop_outlined,
                      color: isDraining ? AppTheme.warningColor : Colors.grey,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Drain Control",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          isDraining
                              ? "Currently draining water..."
                              : "Tap to start draining",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isDraining,
                    onChanged: (value) => _firebase.setDrainControl(value),
                    activeTrackColor: AppTheme.warningColor,
                  ),
                ],
              ),
              if (isDraining) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "The drain system removes old water from the dish automatically when triggered. Monitor the drain tank level to avoid overflow.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
