import 'package:flutter/material.dart';
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAddMealOverlay,
              icon: const Icon(Icons.add),
              label: const Text('Add New Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: widget.registeredMeals.isEmpty
              ? const Center(
                  child: Text(
                    'No meals scheduled yet.\nTap "Add New Meal" to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : MealList(
                  meals: widget.registeredMeals,
                  onRemove: (meal, context) => widget.onRemove(meal, context),
                ),
        ),
      ],
    );
  }
}
