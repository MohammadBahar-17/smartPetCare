import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartpetcare/presentation/viewmodels/meals_viewmodel.dart';
import 'package:smartpetcare/presentation/widgets/add_meal_sheet.dart';
import 'package:smartpetcare/presentation/widgets/meal_card.dart';

class MealsPage extends StatelessWidget {
  const MealsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealsViewModel>();

    return Scaffold(
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: vm.meals.length,
              itemBuilder: (ctx, i) {
                final m = vm.meals[i];
                return MealCard(
                  meal: m,
                  onEdit: () => AddMealSheet.show(context, meal: m),
                  onDelete: () => vm.deleteMeal(m.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddMealSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
