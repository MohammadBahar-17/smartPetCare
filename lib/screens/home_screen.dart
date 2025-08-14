import 'package:flutter/material.dart';

import '../widgets/control_card.dart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final double foodLevel = 0.65;
  final double waterLevel = 0.35;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Manual Control Panel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 30),

            // 🥣 FOOD CONTROL CARD
            ControlCard(
              title: "Food Dispenser",
              icon: Icons.food_bank,
              buttonText: "Feed Now",
              level: foodLevel,
              levelColor: Colors.orange,
              levelLabel: "Food Level",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feeding your cat...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // 💧 WATER CONTROL CARD
            ControlCard(
              title: "Water Dispenser",
              icon: Icons.water_drop,
              buttonText: "Water Now",
              level: waterLevel,
              levelColor: Colors.blueAccent,
              levelLabel: "Water Level",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dispensing water...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
