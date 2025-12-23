import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:smartpetcare/services/ai_service.dart';

import 'screens/logs_screen.dart';

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
      title: "Smart Pet Panel",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainHome(),
    );
  }
}

class MainHome extends StatefulWidget {
  const MainHome({super.key});

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int index = 0;

  final pages = const [FoodScreen(), WaterScreen(), CameraStreamPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Food"),
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: "Water"),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: "Camera"),
        ],
      ),
    );
  }
}

// ============================================================================
// =============================== FOOD SCREEN ================================
// ============================================================================
class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final db = FirebaseDatabase.instance.ref();

  int dogFood = 0;
  int catFood = 0;
  double dogWeight = 0;
  double catWeight = 0;
  bool entertainmentOn = false;
  final _qController = TextEditingController();
  final _ai = AiService();

  String aiAnswer = "";
  List<String> aiTips = [];
  String aiIntent = "summary";
  String aiSeverity = "low";
  List<String> aiActions = [];
  bool aiLoading = false;
  bool mealsAiLoading = false;

  StreamSubscription<DatabaseEvent>? _subFoodSensors;
  bool showFoodAlert = false;
  String foodAlertText = "";

  bool _lastFoodAlertState = false;

  List<String> dashboardTips = [];
  bool dashboardOk = true;

  Future<void> logCommand(String type, Map<String, dynamic> extra) async {
    await db.child("logs/commands").push().set({
      "type": type,
      "ts": ServerValue.timestamp,
      ...extra,
    });
  }

  Future<void> logAlert(String type, Map<String, dynamic> extra) async {
    await db.child("logs/alerts").push().set({
      "type": type,
      "ts": ServerValue.timestamp,
      ...extra,
    });
  }

  void buildDashboardTips() {
    final tips = <String>[];

    if (catFood < 20) {
      tips.add("Cat food low: $catFood% (Please refill soon)");
    }
    if (dogFood < 20) {
      tips.add("Dog food low: $dogFood% (Please refill soon)");
    }

    if (tips.isEmpty) tips.add("All readings normal ✅");

    setState(() {
      dashboardTips = tips;
      dashboardOk = tips.length == 1 && tips.first.contains("normal");
    });
  }

  Widget dashboardCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard — Current Status",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Cat Food: $catFood%"),
            Text("Dog Food: $dogFood%"),
            const Divider(),
            const Text(
              "Auto-generated Tips:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...dashboardTips.map((t) => Text("• $t")).toList(),
          ],
        ),
      ),
    );
  }

  Color sevColor(String s) {
    if (s == "high") return Colors.red;
    if (s == "medium") return Colors.orange;
    return Colors.green;
  }

  void applyAiData(Map<String, dynamic> data) {
    aiAnswer = (data["answer"] ?? "").toString();
    aiTips = (data["tips"] as List? ?? []).map((e) => e.toString()).toList();
    aiIntent = (data["intent"] ?? "summary").toString();
    aiSeverity = (data["severity"] ?? "low").toString();
    aiActions = (data["actions_suggested"] as List? ?? [])
        .map((e) => e.toString())
        .toList();
  }

  Widget aiPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AI Assistant",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qController,
              decoration: const InputDecoration(
                labelText: "Ask your question",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: aiLoading
                      ? null
                      : () async {
                          final q = _qController.text.trim();

                          setState(() {
                            aiLoading = true;
                            aiAnswer = "";
                            aiTips = [];
                            aiIntent = "summary";
                            aiSeverity = "low";
                            aiActions = [];
                          });

                          try {
                            final data = await _ai.ask(q);
                            setState(() => applyAiData(data));
                          } catch (e) {
                            setState(() => aiAnswer = "Error: $e");
                          } finally {
                            setState(() => aiLoading = false);
                          }
                        },
                  child: Text(aiLoading ? "..." : "Ask"),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: aiLoading
                      ? null
                      : () async {
                          setState(() {
                            aiLoading = true;
                            aiAnswer = "";
                            aiTips = [];
                            aiIntent = "summary";
                            aiSeverity = "low";
                            aiActions = [];
                            _qController.clear();
                          });

                          try {
                            final data = await _ai.ask("");
                            setState(() => applyAiData(data));
                          } catch (e) {
                            setState(() => aiAnswer = "Error: $e");
                          } finally {
                            setState(() => aiLoading = false);
                          }
                        },
                  child: const Text("Status Summary"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(aiAnswer),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text("Severity: $aiSeverity"),
                  backgroundColor: sevColor(aiSeverity).withOpacity(0.15),
                ),
                Text("Intent: $aiIntent"),
              ],
            ),
            const SizedBox(height: 8),
            ...aiTips.map((t) => Text("• $t")).toList(),
            if (aiActions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                "Recommendations:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...aiActions.map((a) => Text("• $a")),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> meals = {};
  Map<String, dynamic> pets = {};

  @override
  void initState() {
    super.initState();
    listenFoodSensors();
    loadMeals();
    loadPets();
  }

  @override
  void dispose() {
    _subFoodSensors?.cancel();
    _qController.dispose();
    super.dispose();
  }

  void listenFoodSensors() {
    _subFoodSensors?.cancel();
    _subFoodSensors = db.child("feeding/sensors").onValue.listen((event) async {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      final dog = (data["dog_food_level"] as int?) ?? 0;
      final cat = (data["cat_food_level"] as int?) ?? 0;
      final dogW = ((data["dog_weight"] as num?) ?? 0).toDouble();
      final catW = ((data["cat_weight"] as num?) ?? 0).toDouble();

      final shouldAlert = (cat < 20) || (dog < 20);
      String alertText = "";
      if (shouldAlert) {
        final parts = <String>[];
        if (cat < 20) parts.add("Cat food low: $cat%");
        if (dog < 20) parts.add("Dog food low: $dog%");
        alertText = parts.join(" | ");
      }

      if (shouldAlert && !_lastFoodAlertState) {
        try {
          await logAlert("low_food", {"cat_food": cat, "dog_food": dog});
        } catch (e) {
          debugPrint("logAlert error: $e");
        }
      }
      _lastFoodAlertState = shouldAlert;

      if (!mounted) return;
      setState(() {
        dogFood = dog;
        catFood = cat;
        dogWeight = dogW;
        catWeight = catW;
        showFoodAlert = shouldAlert;
        foodAlertText = alertText;
      });

      if (mounted) {
        buildDashboardTips();
      }
    });
  }

  Future<void> loadAll() async {
    await loadMeals();
    await loadPets();
  }

  Future<void> loadFoodSensors() async {
    final dogFoodSnap = await db.child("feeding/sensors/dog_food_level").get();
    final catFoodSnap = await db.child("feeding/sensors/cat_food_level").get();
    final dogWeightSnap = await db.child("feeding/sensors/dog_weight").get();
    final catWeightSnap = await db.child("feeding/sensors/cat_weight").get();

    if (!mounted) return;
    setState(() {
      dogFood = (dogFoodSnap.value as int?) ?? 0;
      catFood = (catFoodSnap.value as int?) ?? 0;
      dogWeight = ((dogWeightSnap.value as num?) ?? 0).toDouble();
      catWeight = ((catWeightSnap.value as num?) ?? 0).toDouble();
    });
  }

  Future<void> loadMeals() async {
    final mealsSnap = await db.child("feeding/meals").get();
    if (!mounted) return;

    if (mealsSnap.value is Map) {
      setState(() {
        meals = Map<String, dynamic>.from(mealsSnap.value as Map);
      });
    } else {
      setState(() => meals = {});
    }
  }

  Future<void> addMeal() async {
    final animalCtrl = TextEditingController(text: "cat");
    final hourCtrl = TextEditingController(text: "15");
    final minCtrl = TextEditingController(text: "20");
    final amountCtrl = TextEditingController(text: "35");
    final daysCtrl = TextEditingController(text: "all");

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Meal"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: animalCtrl,
                decoration: const InputDecoration(labelText: "Animal (cat/dog)"),
              ),
              TextField(
                controller: hourCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Hour"),
              ),
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Minutes"),
              ),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount (grams)"),
              ),
              TextField(
                controller: daysCtrl,
                decoration: const InputDecoration(labelText: "Days (all/weekdays/...)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Add"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final id = db.child("feeding/meals").push().key;
    await db.child("feeding/meals/$id").set({
      "animal": animalCtrl.text.trim(),
      "hour": int.tryParse(hourCtrl.text) ?? 15,
      "minute": int.tryParse(minCtrl.text) ?? 20,
      "amount": int.tryParse(amountCtrl.text) ?? 35,
      "days": daysCtrl.text.trim(),
    });
    loadMeals();
  }

  Future<void> deleteMeal(String id) async {
    await db.child("feeding/meals/$id").remove();
    loadMeals();
  }

  Future<void> generateMealsAi() async {
    if (mealsAiLoading) return;
    setState(() => mealsAiLoading = true);
    try {
      await _ai.generateMealsAi();
      await loadMeals();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Meals generated successfully ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => mealsAiLoading = false);
    }
  }

  Future<void> loadPets() async {
    final petsSnap = await db.child("profiles").get();
    if (!mounted) return;

    if (petsSnap.value is Map) {
      setState(() {
        pets = Map<String, dynamic>.from(petsSnap.value as Map);
      });
    } else {
      setState(() => pets = {});
    }
  }

  Future<void> addPet() async {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: "cat");
    final ageCtrl = TextEditingController(text: "1");
    final breedCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: "4.0");
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Pet"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(labelText: "Type (cat/dog)"),
              ),
              TextField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Age"),
              ),
              TextField(
                controller: breedCtrl,
                decoration: const InputDecoration(labelText: "Breed"),
              ),
              TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Weight (kg)"),
              ),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: "Notes"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Add"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final id = db.child("profiles").push().key;
    await db.child("profiles/$id").set({
      "name": nameCtrl.text.trim(),
      "type": typeCtrl.text.trim(),
      "age": int.tryParse(ageCtrl.text) ?? 1,
      "breed": breedCtrl.text.trim(),
      "weight": double.tryParse(weightCtrl.text) ?? 4.0,
      "notes": notesCtrl.text.trim(),
    });
    loadPets();
  }

  Future<void> deletePet(String id) async {
    await db.child("profiles/$id").remove();
    loadPets();
  }

  Future<void> feedDog() async {
    await db.child("feeding/commands/feed_dog").set(1);
  }

  Future<void> feedCat() async {
    await db.child("feeding/commands/feed_cat").set(1);
  }

  Future<void> feedCatNow() async {
    await db.child("feeding/commands/feed_cat").set(1);

    try {
      await logCommand("feed_cat", {"source": "flutter"});
    } catch (e) {
      debugPrint("logCommand error: $e");
    }

    await Future.delayed(const Duration(seconds: 1));
    await db.child("feeding/commands/feed_cat").set(0);
  }

  Widget entertainmentButton() {
    return SwitchListTile(
      title: const Text(
        "Entertainment System",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(entertainmentOn ? "ON" : "OFF"),
      value: entertainmentOn,
      onChanged: (value) {
        FirebaseDatabase.instance
            .ref("entertainment/commands/system_on")
            .set(value);

        setState(() {
          entertainmentOn = value;
        });
      },
      secondary: const Icon(Icons.toys),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🍗 Food / Meals / Profiles"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => loadAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dashboardCard(),
              const SizedBox(height: 16),
              if (showFoodAlert)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: const Text("Automatic Alert"),
                    subtitle: Text(foodAlertText),
                  ),
                ),
              const Text(
                "=== FOOD SENSORS ===",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text("Dog Food Level in the tank: $dogFood%"),
              Text("Cat Food Level in the tank: $catFood%"),
              Text("Dog Bowl Weight: $dogWeight g"),
              Text("Cat Bowl Weight: $catWeight g"),
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
              const SizedBox(height: 10),

              const SizedBox(height: 10),
              const Text(
                "=== PET PROFILES ===",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...pets.entries.map((e) {
                final id = e.key;
                final p = Map<String, dynamic>.from(e.value);

                return Card(
                  child: ListTile(
                    title: Text("${p['name']} (${p['type']})"),
                    subtitle: Text(
                      "Age: ${p['age']} | Breed: ${p['breed']} | Weight: ${p['weight']}\nNotes: ${p['notes']}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => deletePet(id),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: addPet,
                child: const Text("Add Pet"),
              ),
              const SizedBox(height: 40),

              const Text(
                "=== MEALS ===",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...meals.entries.map((e) {
                final id = e.key;
                final m = Map<String, dynamic>.from(e.value);

                final hh = (m['hour'] ?? 0).toString().padLeft(2, '0');
                final mm = (m['minute'] ?? 0).toString().padLeft(2, '0');

                return Card(
                  child: ListTile(
                    title: Text("${m['animal']} - $hh:$mm"),
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: addMeal,
                child: const Text("Add Meal"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: mealsAiLoading ? null : generateMealsAi,
                child: Text(
                  mealsAiLoading
                      ? "Generating meals..."
                      : "Generate Meals with AI",
                ),
              ),
              aiPanel(),
              entertainmentButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// =============================== WATER SCREEN ===============================
// ============================================================================
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

  StreamSubscription<DatabaseEvent>? _subSensors;
  StreamSubscription<DatabaseEvent>? _subStatus;
  StreamSubscription<DatabaseEvent>? _subAlerts;

  @override
  void initState() {
    super.initState();
    listenToFirebase();
  }

  @override
  void dispose() {
    _subSensors?.cancel();
    _subStatus?.cancel();
    _subAlerts?.cancel();
    super.dispose();
  }

  void listenToFirebase() {
    _subSensors = db.child('water/sensors').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      if (!mounted) return;
      setState(() {
        dishEmpty = (data['dish_empty'] ?? false) == true;
        drainFull = (data['drain_full'] ?? false) == true;
        tankFull = (data['tank_full'] ?? false) == true;
        tankPercentage = (data['tank_percentage'] as int?) ?? 0;
      });
    });

    _subStatus = db.child('water/status').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      if (!mounted) return;
      setState(() {
        isDraining = (data['is_draining'] ?? false) == true;
      });
    });

    _subAlerts = db.child('water/alerts').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      if (!mounted) return;
      setState(() {
        waterLow = (data['water_low'] ?? false) == true;
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
          Card(
            color: Colors.orange.shade100,
            child: SwitchListTile(
              title: const Text(
                'Drain Control',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Manual drain from Firebase'),
              value: isDraining,
              onChanged: toggleDrain,
              secondary: const Icon(Icons.power),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// =============================== CAMERA SCREEN ==============================
// ============================================================================
enum ImageFilterMode { none, grayscale, invert }

class CameraStreamPage extends StatefulWidget {
  const CameraStreamPage({super.key});

  @override
  State<CameraStreamPage> createState() => _CameraStreamPageState();
}

class _CameraStreamPageState extends State<CameraStreamPage> {
  final String deviceId = "cam001";
  final String baseUrl = "https://esp32cam-cloud-relay.onrender.com";

  final storage = const FlutterSecureStorage();
  StreamController<Uint8List>? _frameController;
  HttpClient? _ioClient;

  bool _streaming = false;
  String _status = "Idle";
  List<int> _buffer = [];
  ImageFilterMode _filterMode = ImageFilterMode.none;

  static const int _minJpegSize = 800;

  @override
  void initState() {
    super.initState();
    _frameController = StreamController<Uint8List>.broadcast();
    _ioClient = HttpClient();
  }

  @override
  void dispose() {
    _stopStream();
    _frameController?.close();
    _ioClient?.close(force: true);
    super.dispose();
  }

  Future<void> saveToken(String token) async =>
      await storage.write(key: "session_token", value: token);
  Future<String?> readToken() async => await storage.read(key: "session_token");
  Future<void> deleteToken() async =>
      await storage.delete(key: "session_token");

  Future<bool> requestOtp() async {
    final url = Uri.parse("$baseUrl/api/device/$deviceId/request_start");
    try {
      final resp = await http.post(url);
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        return j["ok"] == true;
      }
    } catch (e) {
      debugPrint("requestOtp error: $e");
    }
    return false;
  }

  Future<String?> verifyOtp(String code) async {
    final url = Uri.parse("$baseUrl/api/device/$deviceId/verify");
    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"code": code}),
      );
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        return j["token"];
      } else {
        debugPrint("verify failed: ${resp.statusCode} ${resp.body}");
      }
    } catch (e) {
      debugPrint("verify error: $e");
    }
    return null;
  }

  int indexOfBytes(List<int> data, List<int> pattern, [int start = 0]) {
    for (int i = start; i <= data.length - pattern.length; i++) {
      bool ok = true;
      for (int j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return i;
    }
    return -1;
  }

  Future<bool> _validateJpeg(Uint8List bytes) async {
    try {
      if (bytes.length < _minJpegSize) return false;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image.width > 0 && frame.image.height > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _extractFramesAndAdd(List<int> chunk) async {
    _buffer.addAll(chunk);

    while (true) {
      int start = indexOfBytes(_buffer, [0xFF, 0xD8]);
      if (start < 0) {
        if (_buffer.length > 2 * 1024 * 1024) {
          _buffer = _buffer.sublist(_buffer.length - 512);
        }
        break;
      }

      int end = indexOfBytes(_buffer, [0xFF, 0xD9], start + 2);
      if (end < 0) {
        if (_buffer.length > 2 * 1024 * 1024) {
          _buffer = _buffer.sublist(start);
        }
        break;
      }

      final frameBytes = _buffer.sublist(start, end + 2);
      _buffer = _buffer.sublist(end + 2);

      try {
        final u = Uint8List.fromList(frameBytes);
        final valid = await _validateJpeg(u);
        if (valid) {
          _frameController?.add(u);
        } else {
          debugPrint("Dropped invalid frame (size=${u.length})");
        }
      } catch (e) {
        debugPrint("Frame processing error: $e");
      }
    }
  }

  Future<void> _startStreamWithToken(String token) async {
    _stopStream();
    if (!mounted) return;

    setState(() {
      _streaming = true;
      _status = "Connecting...";
    });
    _buffer = [];

    try {
      final url = Uri.parse("$baseUrl/stream/$deviceId");
      final req = await _ioClient!.getUrl(url);
      req.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
      req.headers.set(HttpHeaders.acceptHeader, "multipart/x-mixed-replace");

      final resp = await req.close();
      if (!mounted) return;

      if (resp.statusCode != 200) {
        setState(() {
          _streaming = false;
          _status = "Stream failed (${resp.statusCode})";
        });
        await resp.drain();
        return;
      }

      setState(() => _status = "Streaming");

      await for (List<int> chunk in resp) {
        if (!_streaming) break;
        await _extractFramesAndAdd(chunk);
      }
    } catch (e) {
      debugPrint("Stream connection error: $e");
      if (mounted) {
        setState(() => _status = "Error: $e");
      }
    } finally {
      _streaming = false;
      if (mounted) {
        setState(() {
          if (_status == "Streaming") _status = "Stopped";
        });
      }
    }
  }

  void _stopStream() {
    _streaming = false;
    if (mounted) setState(() => _status = "Stopped");
  }

  Future<void> openStreamFlow() async {
    final otpRequested = await showDialog<bool>(
      context: context,
      builder: (ctx) => RequestOtpDialog(onRequestOtp: requestOtp),
    );
    if (otpRequested != true) return;
    if (!mounted) return;

    final code = await showDialog<String?>(
      context: context,
      builder: (ctx) => EnterOtpDialog(),
    );
    if (code == null || code.isEmpty) return;

    final token = await verifyOtp(code);
    if (token == null) {
      if (mounted) setState(() => _status = "Verify failed");
      return;
    }

    await saveToken(token);
    await _startStreamWithToken(token);
  }

  Future<void> closeAndRevoke() async {
    final token = await readToken();
    if (token != null) {
      try {
        final url = Uri.parse("$baseUrl/api/device/$deviceId/revoke");
        final resp = await http.post(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );
        debugPrint("revoke resp: ${resp.statusCode} ${resp.body}");
      } catch (e) {
        debugPrint("revoke error: $e");
      }
    }
    await deleteToken();
    _stopStream();
    if (mounted) setState(() => _status = "Closed & token revoked");
  }

  ColorFilter getColorFilter(ImageFilterMode mode) {
    switch (mode) {
      case ImageFilterMode.grayscale:
        return const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case ImageFilterMode.invert:
        return const ColorFilter.matrix([
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ]);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }

  @override
  Widget build(BuildContext context) {
    // page-specific dark look, without changing whole app theme
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("📷 SmartPetCare Camera"),
          actions: [
            PopupMenuButton<ImageFilterMode>(
              onSelected: (m) => setState(() => _filterMode = m),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: ImageFilterMode.none,
                  child: Text("No Filter"),
                ),
                PopupMenuItem(
                  value: ImageFilterMode.grayscale,
                  child: Text("Grayscale"),
                ),
                PopupMenuItem(
                  value: ImageFilterMode.invert,
                  child: Text("Invert"),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await deleteToken();
                if (mounted) setState(() => _status = "Logged out");
              },
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            SizedBox(
              width: 360,
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: StreamBuilder<Uint8List>(
                  stream: _frameController?.stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: Text(
                          _status,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      );
                    }
                    final imageBytes = snapshot.data!;
                    return ColorFiltered(
                      colorFilter: getColorFilter(_filterMode),
                      child: Image.memory(
                        imageBytes,
                        gaplessPlayback: true,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, error, stack) {
                          debugPrint("Image.memory error: $error");
                          return const Center(
                            child: Text(
                              "Invalid image",
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Status: $_status",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _streaming ? null : openStreamFlow,
                  child: const Text("Open Stream"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _streaming ? closeAndRevoke : null,
                  child: const Text("Close Stream"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// =============================== OTP DIALOGS ================================
// ============================================================================
class RequestOtpDialog extends StatefulWidget {
  final Future<bool> Function() onRequestOtp;
  const RequestOtpDialog({super.key, required this.onRequestOtp});

  @override
  State<RequestOtpDialog> createState() => _RequestOtpDialogState();
}

class _RequestOtpDialogState extends State<RequestOtpDialog> {
  String msg = "Send OTP to your registered email.";
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Request OTP"),
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: loading
              ? null
              : () async {
                  setState(() {
                    loading = true;
                    msg = "Sending...";
                  });
                  final ok = await widget.onRequestOtp();
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() {
                      loading = false;
                      msg = "Failed to send OTP";
                    });
                  }
                },
          child: const Text("Request OTP"),
        ),
      ],
    );
  }
}

class EnterOtpDialog extends StatelessWidget {
  final controller = TextEditingController();
  EnterOtpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter OTP"),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: "Enter code"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text("Verify"),
        ),
      ],
    );
  }
}
