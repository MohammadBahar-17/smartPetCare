import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_pet_care/screens/ai_chat.dart';
import 'package:smart_pet_care/screens/home_screen.dart';
import 'package:smart_pet_care/screens/pets_screen.dart';
import 'package:smart_pet_care/screens/schedule_meals_screen.dart';
import 'models/meal.dart';
import 'models/pet.dart';

class Cat extends StatefulWidget {
  const Cat({super.key});

  @override
  State<Cat> createState() => _CatState();
}

class _CatState extends State<Cat> {
  final List<Meal> _registeredMeals = [
    Meal(
      date: DateTime.now(),
      amount: 100,
      title: 'First Meal',
      time: const TimeOfDay(hour: 7, minute: 30),
    ),
    Meal(
      date: DateTime.now(),
      amount: 150,
      title: 'Second Meal',
      time: const TimeOfDay(hour: 18, minute: 0),
    ),
  ];

  final List<Pet> _registeredPets = [
    Pet(
      name: 'Whiskers',
      sex: PetSex.male,
      age: 3,
      weight: 4.2,
      kind: PetKind.cat,
      dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 3)),
      breed: 'Persian',
    ),
    Pet(
      name: 'Buddy',
      sex: PetSex.female,
      age: 2,
      weight: 12.5,
      kind: PetKind.dog,
      dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 2)),
      breed: 'Golden Retriever',
    ),
  ];

  void _addMeals(Meal meal) {
    setState(() {
      _registeredMeals.add(meal);
    });
  }

  void _removeMeals(Meal meal, BuildContext context) {
    final deletedIndex = _registeredMeals.indexOf(meal);
    setState(() {
      _registeredMeals.remove(meal);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 3),
        content: const Text(
          'Meal deleted',
          style: TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.pinkAccent,
          onPressed: () {
            setState(() {
              _registeredMeals.insert(deletedIndex, meal);
            });
          },
        ),
      ),
    );
  }

  void _addPets(Pet pet) {
    setState(() {
      _registeredPets.add(pet);
    });
  }

  void _removePets(Pet pet, BuildContext context) {
    final deletedIndex = _registeredPets.indexOf(pet);
    setState(() {
      _registeredPets.remove(pet);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 3),
        content: Text(
          '${pet.name} deleted',
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.pinkAccent,
          onPressed: () {
            setState(() {
              _registeredPets.insert(deletedIndex, pet);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care System',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          backgroundColor: const Color(0xFFFFF8F0), // soft warm background
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, bottom: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B73FF), Color(0xFF9DD5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "Pet Care System",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // 🐾 Modern Tab Bar
              const TabBar(
                labelColor: Color(0xFF9C27B0),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF9C27B0),
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.home), text: 'Home'),
                  Tab(icon: Icon(Icons.schedule), text: 'Schedule Meals'),
                  Tab(icon: Icon(Icons.pets), text: 'Pets'),
                  Tab(icon: Icon(Icons.smart_toy), text: 'Ask AI'),
                  Tab(icon: Icon(Icons.add_alert), text: 'notifications'),
                ],
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    HomeScreen(),
                    ScheduleMealsScreen(
                      onAdd: _addMeals,
                      onRemove: _removeMeals,
                      registeredMeals: _registeredMeals,
                    ),
                    PetsScreen(
                      onAdd: _addPets,
                      onRemove: _removePets,
                      registeredPets: _registeredPets,
                    ),
                    AiChatScreen(),
                    Center(child: Text('No Notifications today')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
