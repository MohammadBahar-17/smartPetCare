import 'package:flutter/material.dart';

class FoodCard extends StatelessWidget {
  final String label;
  final int percentage;
  final Color color;

  const FoodCard({
    super.key,
    required this.label,
    required this.percentage,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(color),
            ),
            const SizedBox(width: 20),
            Text("$label: $percentage%", style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
