import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/meal_list.dart';
import '../models/meal.dart';
import '../widgets/new_meal.dart';

class ScheduleMealsScreen extends StatefulWidget {
  const ScheduleMealsScreen({
    super.key,
    required this.registeredMeals,
    required this.onAdd,
    required this.onRemove,
  });

  final void Function(Meal meal, BuildContext context) onRemove;
  final List<Meal> registeredMeals;
  final void Function(Meal meal) onAdd;

  @override
  State<ScheduleMealsScreen> createState() => _ScheduleMealsScreenState();
}

class _ScheduleMealsScreenState extends State<ScheduleMealsScreen> {
  void _openAddMealOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: NewMeal(onAddMeals: widget.onAdd),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Column(
        children: [
          // Header Section
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: AppTheme.cardRadius,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.warmGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meal Schedule',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Manage your pet\'s feeding times',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openAddMealOverlay,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Add New Meal',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.white),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.warmYellow,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.buttonRadius,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Meals List
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: AppTheme.cardRadius,
                boxShadow: AppTheme.cardShadow,
              ),
              child: widget.registeredMeals.isEmpty
                  ? _buildEmptyState(context)
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Text(
                                'Scheduled Meals',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.warmYellow.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${widget.registeredMeals.length} meals',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppTheme.warmYellow,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: MealList(
                            meals: widget.registeredMeals,
                            onRemove: (meal, context) =>
                                widget.onRemove(meal, context),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.warmYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              size: 48,
              color: AppTheme.warmYellow,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No meals scheduled yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first meal to start scheduling your pet\'s feeding routine',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _openAddMealOverlay,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add First Meal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.warmYellow,
              side: BorderSide(color: AppTheme.warmYellow),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
