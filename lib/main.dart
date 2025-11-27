import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SmartPetApp());
}

class SmartPetApp extends StatelessWidget {
  const SmartPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Smart Pet Test",
      home: const TestHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestHome extends StatefulWidget {
  const TestHome({super.key});
  @override
  State<TestHome> createState() => _TestHomeState();
}

class _TestHomeState extends State<TestHome> {
  final db = FirebaseDatabase.instance.ref();

  // FOOD SENSOR VARIABLES
  int dogFood = 0;
  int catFood = 0;
  double dogWeight = 0;
  double catWeight = 0;

  // WATER SENSOR VARIABLES
  bool dishEmpty = false;
  bool tankFull = false;
  int tankPercent = 0;
  bool waterLow = false;

  // MEALS
  Map<String, dynamic> meals = {};

  // PET PROFILES
  Map<String, dynamic> pets = {};

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  // ------------------ LOAD ALL DATA ------------------
  Future<void> loadAll() async {
    await loadSensors();
    await loadMeals();
    await loadPets();
  }

  // ------------------ SENSORS ------------------
  Future<void> loadSensors() async {
    final dogFoodSnap = await db.child("feeding/sensors/dog_food_level").get();
    final catFoodSnap = await db.child("feeding/sensors/cat_food_level").get();
    final dogWeightSnap = await db.child("feeding/sensors/dog_weight").get();
    final catWeightSnap = await db.child("feeding/sensors/cat_weight").get();

    final dishSnap = await db.child("water/sensors/dish_empty").get();
    final tankFullSnap = await db.child("water/sensors/tank_full").get();
    final tankPercentSnap = await db
        .child("water/sensors/tank_percentage")
        .get();
    final lowSnap = await db.child("water/alerts/water_low").get();

    setState(() {
      dogFood = (dogFoodSnap.value as int?) ?? 0;
      catFood = (catFoodSnap.value as int?) ?? 0;
      dogWeight = ((dogWeightSnap.value as num?) ?? 0).toDouble();
      catWeight = ((catWeightSnap.value as num?) ?? 0).toDouble();

      dishEmpty = dishSnap.value == true;
      tankFull = tankFullSnap.value == true;
      tankPercent = (tankPercentSnap.value as int?) ?? 0;
      waterLow = lowSnap.value == true;
    });
  }

  // ------------------ LOAD MEALS ------------------
  Future<void> loadMeals() async {
    final mealsSnap = await db.child("feeding/meals").get();
    if (mealsSnap.value is Map) {
      setState(() {
        meals = Map<String, dynamic>.from(mealsSnap.value as Map);
      });
    }
  }

  Future<void> deleteMeal(String id) async {
    await db.child("feeding/meals/$id").remove();
    loadMeals();
  }

  Future<void> addMeal() async {
    final id = db.child("feeding/meals").push().key;
    await db.child("feeding/meals/$id").set({
      "animal": "cat",
      "hour": 15,
      "minute": 20,
      "amount": 35,
      "days": "all",
    });
    loadMeals();
  }

  // ------------------ PET PROFILES ------------------
  Future<void> loadPets() async {
    final petsSnap = await db.child("profiles").get();
    if (petsSnap.value is Map) {
      setState(() {
        pets = Map<String, dynamic>.from(petsSnap.value as Map);
      });
    }
  }

  Future<void> addPet() async {
    final id = db.child("profiles").push().key;
    await db.child("profiles/$id").set({
      "name": "Snow",
      "type": "cat",
      "age": 2,
      "breed": "Persian",
      "weight": 4.2,
      "notes": "Loves tuna",
    });
    loadPets();
  }

  Future<void> deletePet(String id) async {
    await db.child("profiles/$id").remove();
    loadPets();
  }

  // ------------------ FOOD ACTIONS ------------------
  Future<void> feedDog() async {
    await db.child("feeding/commands/feed_dog").set(1);
  }

  Future<void> feedCat() async {
    await db.child("feeding/commands/feed_cat").set(1);
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Pet — FULL TEST PANEL")),
      body: RefreshIndicator(
        onRefresh: () async => loadAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= FOOD =================
              const Text(
                "=== FOOD SENSORS ===",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text("Dog Food Level: $dogFood%"),
              Text("Cat Food Level: $catFood%"),
              Text("Dog Weight: $dogWeight g"),
              Text("Cat Weight: $catWeight g"),
              const SizedBox(height: 20),

              Row(
                children: [
                  ElevatedButton(
                    onPressed: feedDog,
                    child: const Text("Feed Dog"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: feedCat,
                    child: const Text("Feed Cat"),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ================= WATER =================
              const Text(
                "=== WATER SYSTEM ===",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text("Dish Empty: $dishEmpty"),
              Text("Tank Full: $tankFull"),
              Text("Tank Percentage: $tankPercent%"),
              Text("Water Low (<10%): $waterLow"),
              const SizedBox(height: 30),

              // ================= PET PROFILES =================
              const Text(
                "=== PET PROFILES ===",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Column(
                children: pets.entries.map((e) {
                  final id = e.key;
                  final p = Map<String, dynamic>.from(e.value);

                  return Card(
                    child: ListTile(
                      title: Text("${p['name']} (${p['type']})"),
                      subtitle: Text(
                        "Age: ${p['age']}  | Breed: ${p['breed']} | Weight: ${p['weight']}\nNotes: ${p['notes']}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deletePet(id),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: addPet,
                child: const Text("Add Test Pet"),
              ),

              const SizedBox(height: 40),

              // ================= MEALS =================
              const Text(
                "=== MEALS ===",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Column(
                children: meals.entries.map((e) {
                  final id = e.key;
                  final m = Map<String, dynamic>.from(e.value);

                  return Card(
                    child: ListTile(
                      title: Text(
                        "${m['animal']} - ${m['hour']}:${m['minute']}",
                      ),
                      subtitle: Text(
                        "Amount: ${m['amount']}g | Days: ${m['days']}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteMeal(id),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: addMeal,
                child: const Text("Add Test Meal"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
