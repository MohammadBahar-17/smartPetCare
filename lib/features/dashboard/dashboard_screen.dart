import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/firebase_service.dart';
import '../../services/ai_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/status_indicator.dart';
import '../../widgets/loading_indicator.dart';
import '../feeding/feeding_screen.dart';
import '../water/water_screen.dart';
import '../camera/camera_screen.dart';
import '../logs/logs_screen.dart';
import '../ai_chat/ai_chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firebase = FirebaseService();
  final _ai = AiService();

  // Sensor data
  int catFood = 0;
  int dogFood = 0;
  double catWeight = 0;
  double dogWeight = 0;
  int tankPercentage = 0;
  bool dishEmpty = false;
  bool entertainmentOn = false;
  bool isDraining = false;

  // AI data
  String aiAnswer = "";
  List<String> aiTips = [];
  String aiIntent = "summary";
  String aiSeverity = "low";
  List<String> aiActions = [];
  bool aiLoading = false;
  bool mealsAiLoading = false;

  // Subscriptions
  StreamSubscription<DatabaseEvent>? _subFoodSensors;
  StreamSubscription<DatabaseEvent>? _subWaterSensors;
  StreamSubscription<DatabaseEvent>? _subEntertainment;
  StreamSubscription<DatabaseEvent>? _subWaterStatus;

  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _initListeners();
    _loadSummary();
  }

  @override
  void dispose() {
    _subFoodSensors?.cancel();
    _subWaterSensors?.cancel();
    _subEntertainment?.cancel();
    _subWaterStatus?.cancel();
    super.dispose();
  }

  void _initListeners() {
    // Food sensors
    _subFoodSensors = _firebase.foodSensorsStream().listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null || !mounted) return;

      final newDogFood = (data["dog_food_level"] as int?) ?? 0;
      final newCatFood = (data["cat_food_level"] as int?) ?? 0;
      
      // Check if crossed critical threshold
      final wasCritical = dogFood <= AppConstants.criticalFoodThreshold || 
                          catFood <= AppConstants.criticalFoodThreshold;
      final nowCritical = newDogFood <= AppConstants.criticalFoodThreshold || 
                          newCatFood <= AppConstants.criticalFoodThreshold;
      final shouldRefresh = !_isInitialLoading && (wasCritical != nowCritical);

      setState(() {
        dogFood = newDogFood;
        catFood = newCatFood;
        dogWeight = ((data["dog_weight"] as num?) ?? 0).toDouble();
        catWeight = ((data["cat_weight"] as num?) ?? 0).toDouble();
        _isInitialLoading = false;
      });

      if (shouldRefresh) _loadSummary();
    });

    // Water sensors
    _subWaterSensors = _firebase.waterSensorsStream().listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null || !mounted) return;

      final newTank = (data["tank_percentage"] as int?) ?? 0;
      final newDishEmpty = (data["dish_empty"] ?? false) == true;
      
      // Check if crossed critical threshold or dish status changed
      final wasCritical = tankPercentage <= AppConstants.criticalWaterThreshold;
      final nowCritical = newTank <= AppConstants.criticalWaterThreshold;
      final dishChanged = dishEmpty != newDishEmpty;
      final shouldRefresh = !_isInitialLoading && ((wasCritical != nowCritical) || dishChanged);

      setState(() {
        tankPercentage = newTank;
        dishEmpty = newDishEmpty;
      });

      if (shouldRefresh) _loadSummary();
    });

    // Water status
    _subWaterStatus = _firebase.waterStatusStream().listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null || !mounted) return;

      setState(() {
        isDraining = (data["is_draining"] ?? false) == true;
      });
    });

    // Entertainment
    _subEntertainment = _firebase.entertainmentStream().listen((event) {
      if (!mounted) return;
      final newValue = event.snapshot.value == true;
      final changed = entertainmentOn != newValue;
      setState(() {
        entertainmentOn = newValue;
      });
      // Refresh AI summary when entertainment changes
      if (changed && !_isInitialLoading) {
        _loadSummary();
      }
    });
  }

  Future<void> _loadSummary() async {
    if (aiLoading) return;
    setState(() {
      aiLoading = true;
      aiAnswer = "";
      aiTips = [];
      aiActions = [];
    });

    try {
      final data = await _ai.ask("");
      if (!mounted) return;
      setState(() {
        aiAnswer = (data["answer"] ?? "").toString();
        aiTips = (data["tips"] as List? ?? [])
            .map((e) => e.toString())
            .toList();
        aiIntent = (data["intent"] ?? "summary").toString();
        aiSeverity = (data["severity"] ?? "low").toString();
        aiActions = (data["actions_suggested"] as List? ?? [])
            .map((e) => e.toString())
            .toList();
      });
    } catch (e) {
      if (mounted) {
        setState(() => aiAnswer = "Error loading summary: $e");
      }
    } finally {
      if (mounted) setState(() => aiLoading = false);
    }
  }

  Future<void> _generateMealsAi() async {
    if (mealsAiLoading) return;
    setState(() => mealsAiLoading = true);
    try {
      await _ai.generateMealsAi();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Meals generated successfully ✅"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => mealsAiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 8,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/smartpetcare.jpeg',
                  height: 28,
                  width: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  "SmartPetCare",
                  style: TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: const LoadingIndicator(message: "Loading dashboard..."),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/smartpetcare.jpeg',
                height: 28,
                width: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                "SmartPetCare",
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy, size: 22),
            tooltip: "AI Chat",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiChatScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history, size: 22),
            tooltip: "Logs",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LogsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: "Refresh",
            onPressed: _loadSummary,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSensorOverview(),
              const SizedBox(height: AppTheme.spacingMd),
              _buildQuickActions(),
              const SizedBox(height: AppTheme.spacingMd),
              if (aiTips.isNotEmpty) _buildTipsList(),
              if (aiActions.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMd),
                _buildActionsList(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSensorOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Sensor Overview", icon: Icons.sensors),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            StatusIndicator(
              label: "Cat Food",
              value: "$catFood%",
              icon: Icons.pets,
              isAlert: catFood < 20,
              color: catFood < 20
                  ? AppTheme.severityHigh
                  : AppTheme.successColor,
            ),
            StatusIndicator(
              label: "Dog Food",
              value: "$dogFood%",
              icon: Icons.pets,
              isAlert: dogFood < 20,
              color: dogFood < 20
                  ? AppTheme.severityHigh
                  : AppTheme.successColor,
            ),
            StatusIndicator(
              label: "Water Tank",
              value: "$tankPercentage%",
              icon: Icons.water_drop,
              isAlert: tankPercentage < 30,
              color: tankPercentage < 30
                  ? AppTheme.severityMedium
                  : AppTheme.successColor,
            ),
            StatusIndicator(
              label: "Entertainment",
              value: entertainmentOn ? "ON" : "OFF",
              icon: Icons.flashlight_on,
              color: entertainmentOn ? AppTheme.successColor : Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Quick Actions", icon: Icons.flash_on),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              const SizedBox(width: 4),
              QuickActionButton(
                icon: Icons.pets,
                label: "Feed Cat",
                onPressed: () async {
                  await _firebase.feedCat();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Feeding cat... 🐱"),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 16),
              QuickActionButton(
                icon: Icons.pets,
                label: "Feed Dog",
                onPressed: () async {
                  await _firebase.feedDog();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Feeding dog... 🐕"),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 16),
              QuickActionButton(
                icon: Icons.auto_awesome,
                label: "AI Meals",
                isLoading: mealsAiLoading,
                onPressed: _generateMealsAi,
              ),
              const SizedBox(width: 16),
              QuickActionButton(
                icon: entertainmentOn ? Icons.stop_circle : Icons.play_circle,
                label: "Entertainment Mode",
                color: entertainmentOn
                    ? AppTheme.successColor.withValues(alpha: 0.3)
                    : null,
                onPressed: () => _firebase.setEntertainment(!entertainmentOn),
              ),
              const SizedBox(width: 16),
              QuickActionButton(
                icon: Icons.videocam,
                label: "Camera",
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraScreen()),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Tips & Insights",
          icon: Icons.lightbulb_outline,
        ),
        ...aiTips.map(
          (tip) => AppCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_getTipIcon(tip), size: 20, color: _getTipColor(tip)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Recommended Actions",
          icon: Icons.checklist,
        ),
        ...aiActions.map(
          (action) => AppCard(
            padding: const EdgeInsets.all(12),
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(Icons.arrow_forward_ios, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        if (i == 0) return; // Already on dashboard
        Widget page;
        switch (i) {
          case 1:
            page = const FeedingScreen();
            break;
          case 2:
            page = const WaterScreen();
            break;
          case 3:
            page = const CameraScreen();
            break;
          default:
            return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: "Dashboard",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Feeding"),
        BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: "Water"),
        BottomNavigationBarItem(icon: Icon(Icons.videocam), label: "Camera"),
      ],
    );
  }

  IconData _getTipIcon(String tip) {
    if (tip.contains('🔴') || tip.contains('⚠')) return Icons.warning_rounded;
    if (tip.contains('🟠') || tip.contains('🟡')) return Icons.info_rounded;
    if (tip.contains('✅') || tip.contains('🟢')) {
      return Icons.check_circle_rounded;
    }
    return Icons.lightbulb_outline;
  }

  Color _getTipColor(String tip) {
    if (tip.contains('🔴') || tip.contains('⚠')) return AppTheme.severityHigh;
    if (tip.contains('🟠') || tip.contains('🟡')) {
      return AppTheme.severityMedium;
    }
    if (tip.contains('✅') || tip.contains('🟢')) return AppTheme.severityLow;
    return Colors.grey;
  }
}
