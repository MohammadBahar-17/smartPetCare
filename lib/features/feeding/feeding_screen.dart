import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/firebase_service.dart';
import '../../services/ai_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../profiles/profiles_screen.dart';

class FeedingScreen extends StatefulWidget {
  const FeedingScreen({super.key});

  @override
  State<FeedingScreen> createState() => _FeedingScreenState();
}

class _FeedingScreenState extends State<FeedingScreen> {
  final _firebase = FirebaseService();
  final _ai = AiService();

  // Sensor data
  int catFood = 0;
  int dogFood = 0;
  double catWeight = 0;
  double dogWeight = 0;

  // Meals and pets
  Map<String, dynamic> meals = {};
  Map<String, dynamic> pets = {};

  // Loading states
  bool _isLoading = true;
  bool _feedingCat = false;
  bool _feedingDog = false;
  bool _generatingMeals = false;

  // Subscriptions
  StreamSubscription<DatabaseEvent>? _subFoodSensors;

  @override
  void initState() {
    super.initState();
    _initListeners();
    _loadData();
  }

  @override
  void dispose() {
    _subFoodSensors?.cancel();
    super.dispose();
  }

  void _initListeners() {
    _subFoodSensors = _firebase.foodSensorsStream().listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null || !mounted) return;

      setState(() {
        dogFood = (data["dog_food_level"] as int?) ?? 0;
        catFood = (data["cat_food_level"] as int?) ?? 0;
        dogWeight = ((data["dog_weight"] as num?) ?? 0).toDouble();
        catWeight = ((data["cat_weight"] as num?) ?? 0).toDouble();
        _isLoading = false;
      });
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMeals(),
      _loadPets(),
    ]);
  }

  Future<void> _loadMeals() async {
    final data = await _firebase.getMeals();
    if (mounted) setState(() => meals = data);
  }

  Future<void> _loadPets() async {
    final data = await _firebase.getProfiles();
    if (mounted) setState(() => pets = data);
  }

  Future<void> _feedCat() async {
    if (_feedingCat) return;
    setState(() => _feedingCat = true);
    try {
      await _firebase.feedCat();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Feeding cat... 🐱"),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _feedingCat = false);
    }
  }

  Future<void> _feedDog() async {
    if (_feedingDog) return;
    setState(() => _feedingDog = true);
    try {
      await _firebase.feedDog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Feeding dog... 🐕"),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _feedingDog = false);
    }
  }

  Future<void> _generateMealsAi() async {
    if (_generatingMeals) return;
    setState(() => _generatingMeals = true);
    try {
      await _ai.generateMealsAi();
      await _loadMeals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Meals generated successfully ✅"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingMeals = false);
    }
  }

  Future<void> _addMeal() async {
    String selectedAnimal = "cat";
    TimeOfDay selectedTime = const TimeOfDay(hour: 15, minute: 20);
    final amountCtrl = TextEditingController(text: "35");
    Set<String> selectedDays = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};

    String _getDaysDisplayText(Set<String> days) {
      if (days.length == 7) return "Every Day";
      if (days.isEmpty) return "Select Days";
      final weekdays = {"Mon", "Tue", "Wed", "Thu", "Fri"};
      final weekend = {"Sat", "Sun"};
      if (days.length == 5 && days.containsAll(weekdays)) return "Weekdays";
      if (days.length == 2 && days.containsAll(weekend)) return "Weekend";
      return days.join(", ");
    }

    Future<void> _showDaysDialog(StateSetter setDialogState) async {
      final allDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
      final tempSelected = Set<String>.from(selectedDays);

      final result = await showDialog<Set<String>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDaysState) {
            final allSelected = tempSelected.length == 7;
            return AlertDialog(
              title: const Text("Select Days"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Select All checkbox
                  CheckboxListTile(
                    title: const Text("Every Day"),
                    subtitle: const Text("Select all days"),
                    value: allSelected,
                    onChanged: (val) {
                      setDaysState(() {
                        if (val == true) {
                          tempSelected.addAll(allDays);
                        } else {
                          tempSelected.clear();
                        }
                      });
                    },
                  ),
                  const Divider(),
                  // Individual days
                  ...allDays.map((day) => CheckboxListTile(
                    title: Text(_getDayFullName(day)),
                    value: tempSelected.contains(day),
                    dense: true,
                    onChanged: (val) {
                      setDaysState(() {
                        if (val == true) {
                          tempSelected.add(day);
                        } else {
                          tempSelected.remove(day);
                        }
                      });
                    },
                  )),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: tempSelected.isEmpty 
                      ? null 
                      : () => Navigator.pop(ctx, tempSelected),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        ),
      );

      if (result != null) {
        setDialogState(() => selectedDays = result);
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add New Meal"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animal Dropdown
                DropdownButtonFormField<String>(
                  value: selectedAnimal,
                  decoration: const InputDecoration(
                    labelText: "Animal",
                    prefixIcon: Icon(Icons.pets),
                  ),
                  items: const [
                    DropdownMenuItem(value: "cat", child: Text("🐱 Cat")),
                    DropdownMenuItem(value: "dog", child: Text("🐕 Dog")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedAnimal = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Time Picker Button
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Time",
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedTime.format(context),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount TextField
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Amount (grams)",
                    prefixIcon: Icon(Icons.scale),
                  ),
                ),
                const SizedBox(height: 16),

                // Days Selection - Opens Dialog
                InkWell(
                  onTap: () => _showDaysDialog(setDialogState),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Days",
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _getDaysDisplayText(selectedDays),
                            style: Theme.of(context).textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    // Convert selected days to string format
    String daysString;
    if (selectedDays.length == 7) {
      daysString = "all";
    } else if (selectedDays.containsAll({"Mon", "Tue", "Wed", "Thu", "Fri"}) && selectedDays.length == 5) {
      daysString = "weekdays";
    } else if (selectedDays.containsAll({"Sat", "Sun"}) && selectedDays.length == 2) {
      daysString = "weekend";
    } else {
      daysString = selectedDays.join(",");
    }

    await _firebase.addMeal(
      animal: selectedAnimal,
      hour: selectedTime.hour,
      minute: selectedTime.minute,
      amount: int.tryParse(amountCtrl.text) ?? 35,
      days: daysString,
    );
    await _loadMeals();
  }

  String _getDayFullName(String short) {
    switch (short) {
      case "Sun": return "Sunday";
      case "Mon": return "Monday";
      case "Tue": return "Tuesday";
      case "Wed": return "Wednesday";
      case "Thu": return "Thursday";
      case "Fri": return "Friday";
      case "Sat": return "Saturday";
      default: return short;
    }
  }

  Future<void> _deleteMeal(String id, String animal, String time) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Meal?"),
        content: Text("Remove $animal meal at $time?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.severityHigh,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _firebase.deleteMeal(id);
    await _loadMeals();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("🍗 Feeding")),
        body: const LoadingIndicator(message: "Loading feeding data..."),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🍗 Feeding"),
        actions: [
          IconButton(
            icon: const Icon(Icons.pets),
            tooltip: "Pet Profiles",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilesScreen()),
              );
              _loadPets(); // Refresh after returning
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSensorCards(),
              const SizedBox(height: AppTheme.spacingLg),
              _buildQuickActions(),
              const SizedBox(height: AppTheme.spacingLg),
              _buildMealsSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMeal,
        icon: const Icon(Icons.add),
        label: const Text("Add Meal"),
      ),
    );
  }

  Widget _buildSensorCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Food Levels",
          icon: Icons.sensors,
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildFoodCard(
              "Cat Food",
              "🐱",
              catFood,
              catWeight,
              AppConstants.lowFoodThreshold,
            ),
            _buildFoodCard(
              "Dog Food",
              "🐕",
              dogFood,
              dogWeight,
              AppConstants.lowFoodThreshold,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFoodCard(
    String title,
    String emoji,
    int level,
    double bowlWeight,
    int threshold,
  ) {
    final isLow = level < threshold;
    final isCritical = level < AppConstants.criticalFoodThreshold;

    return AppCard(
      color: isCritical
          ? AppTheme.severityHigh.withValues(alpha: 0.1)
          : isLow
              ? AppTheme.severityMedium.withValues(alpha: 0.1)
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (isCritical)
                const Icon(Icons.warning, color: AppTheme.severityHigh, size: 20)
              else if (isLow)
                const Icon(Icons.info, color: AppTheme.severityMedium, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$level%",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCritical
                      ? AppTheme.severityHigh
                      : isLow
                          ? AppTheme.severityMedium
                          : AppTheme.severityLow,
                ),
          ),
          Text(
            "Bowl: ${bowlWeight.toStringAsFixed(1)}g",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Quick Actions",
          icon: Icons.flash_on,
        ),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.pets,
                label: "Feed Cat 🐱",
                isLoading: _feedingCat,
                onPressed: _feedCat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.pets,
                label: "Feed Dog 🐕",
                isLoading: _feedingDog,
                onPressed: _feedDog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _ActionButton(
            icon: Icons.auto_awesome,
            label: "Generate Meals with AI",
            isLoading: _generatingMeals,
            onPressed: _generateMealsAi,
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMealsSection() {
    // Group meals by animal
    final catMeals = <MapEntry<String, dynamic>>[];
    final dogMeals = <MapEntry<String, dynamic>>[];

    for (final entry in meals.entries) {
      final m = Map<String, dynamic>.from(entry.value);
      final animal = (m['animal'] ?? '').toString().toLowerCase();
      if (animal == 'cat') {
        catMeals.add(entry);
      } else {
        dogMeals.add(entry);
      }
    }

    // Sort by time
    catMeals.sort((a, b) {
      final aTime = (a.value['hour'] ?? 0) * 60 + (a.value['minute'] ?? 0);
      final bTime = (b.value['hour'] ?? 0) * 60 + (b.value['minute'] ?? 0);
      return aTime.compareTo(bTime);
    });
    dogMeals.sort((a, b) {
      final aTime = (a.value['hour'] ?? 0) * 60 + (a.value['minute'] ?? 0);
      final bTime = (b.value['hour'] ?? 0) * 60 + (b.value['minute'] ?? 0);
      return aTime.compareTo(bTime);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Scheduled Meals",
          icon: Icons.schedule,
        ),
        if (meals.isEmpty)
          const EmptyState(
            icon: Icons.restaurant_menu,
            title: "No meals scheduled",
            subtitle: "Add a meal or generate with AI",
          )
        else ...[
          if (catMeals.isNotEmpty) ...[
            _buildAnimalMealsSection("🐱 Cat Meals", catMeals),
            const SizedBox(height: 16),
          ],
          if (dogMeals.isNotEmpty)
            _buildAnimalMealsSection("🐕 Dog Meals", dogMeals),
        ],
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildAnimalMealsSection(
    String title,
    List<MapEntry<String, dynamic>> mealsList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...mealsList.map((entry) {
          final id = entry.key;
          final m = Map<String, dynamic>.from(entry.value);
          final timeStr = Helpers.formatTime(m['hour'] ?? 0, m['minute'] ?? 0);

          return AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    timeStr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${m['amount']}g",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        "Days: ${m['days'] ?? 'all'}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.severityHigh,
                  onPressed: () => _deleteMeal(id, m['animal'] ?? '', timeStr),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}
