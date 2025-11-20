import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartpetcare/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:smartpetcare/presentation/widgets/action_button.dart';
import 'package:smartpetcare/presentation/widgets/food_card.dart';
import 'package:smartpetcare/presentation/widgets/info_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();

    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final s = vm.sensors;
    if (s == null) {
      return const Center(child: Text("No data"));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Dashboard",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        FoodCard(
          label: "Dog Food",
          percentage: s.dogFoodLevel,
          color: Colors.blue,
        ),
        FoodCard(
          label: "Cat Food",
          percentage: s.catFoodLevel,
          color: Colors.orange,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: InfoCard(
                title: "Dog Weight",
                value: "${s.dogWeight.toStringAsFixed(1)} kg",
                icon: Icons.monitor_weight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InfoCard(
                title: "Cat Weight",
                value: "${s.catWeight.toStringAsFixed(1)} kg",
                icon: Icons.monitor_weight_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: "Feed Dog",
                icon: Icons.pets,
                onTap: vm.feedDog,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ActionButton(
                label: "Feed Cat",
                icon: Icons.pets_outlined,
                onTap: vm.feedCat,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
