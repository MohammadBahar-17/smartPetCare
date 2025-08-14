import 'package:flutter/material.dart';

import '../widgets/camera_preview.dart';
import '../widgets/control_card.dart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
              'Pet Monitor & Control',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 20),

            // 📹 CAMERA FEED CARD
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.videocam, color: Colors.green, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Live Camera Feed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const CameraPreviewWidget(), // 👈 Using separate camera widget
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

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
                    content: Text('Feeding your pet...'),
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
