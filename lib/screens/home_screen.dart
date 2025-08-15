import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/camera_preview.dart';
import '../widgets/control_card.dart';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🐾 Title
            Text(
              'Pet Monitor & Control',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 20),

            // 📹 Camera Feed Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE5B4), Color(0xFFFFF8F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.videocam,
                        color: Color(0xFF9C27B0),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Live Camera Feed',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: const CameraPreviewWidget(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🥣 Food Control Card
            ControlCard(
              title: "Food Dispenser",
              icon: Icons.food_bank,
              buttonText: "Feed Now",
              level: foodLevel,
              levelColor: const Color(0xFFFF6B9D),
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

            // 💧 Water Control Card
            ControlCard(
              title: "Water Dispenser",
              icon: Icons.water_drop,
              buttonText: "Water Now",
              level: waterLevel,
              levelColor: const Color(0xFF6B73FF),
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
