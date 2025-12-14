import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartCat Water System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WaterScreen(),
    );
  }
}

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  bool dishEmpty = false;
  bool drainFull = false;
  bool tankFull = false;
  bool isDraining = false;
  bool waterLow = false;

  int tankPercentage = 0;

  @override
  void initState() {
    super.initState();
    listenToFirebase();
  }

  void listenToFirebase() {
    db.child('water/sensors').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      setState(() {
        dishEmpty = data['dish_empty'] ?? false;
        drainFull = data['drain_full'] ?? false;
        tankFull = data['tank_full'] ?? false;
        tankPercentage = data['tank_percentage'] ?? 0;
      });
    });

    db.child('water/status').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      setState(() {
        isDraining = data['is_draining'] ?? false;
      });
    });

    db.child('water/alerts').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      setState(() {
        waterLow = data['water_low'] ?? false;
      });
    });
  }

  void toggleDrain(bool value) {
    db.child('water/controls/drain_button').set(value);
  }

  Widget statusTile(String title, bool value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Icon(
          value ? Icons.check_circle : Icons.cancel,
          color: value ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💧 Water & Drain System'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ===== Tank =====
          Card(
            child: ListTile(
              title: const Text('Tank Level'),
              subtitle: Text('$tankPercentage %'),
              trailing: Icon(
                tankFull ? Icons.water : Icons.water_drop_outlined,
                color: tankFull ? Colors.blue : Colors.grey,
              ),
            ),
          ),

          statusTile('Tank Full', tankFull),
          statusTile('Dish Empty', dishEmpty),
          statusTile('Drain Full', drainFull),
          statusTile('Water Low Alert', waterLow),
          statusTile('Currently Draining', isDraining),

          const SizedBox(height: 20),

          // ===== Drain Button =====
          Card(
            color: Colors.orange.shade100,
            child: SwitchListTile(
              title: const Text(
                'Drain Control',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Manual drain from Firebase'),
              value: isDraining,
              onChanged: (value) {
                toggleDrain(value);
              },
              secondary: const Icon(Icons.power),
            ),
          ),
        ],
      ),
    );
  }
}
