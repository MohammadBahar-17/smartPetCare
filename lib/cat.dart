import 'package:smart_pet_care/screens/home_screen.dart';
import 'package:smart_pet_care/screens/schedule_meals_screen.dart';
import 'package:smart_pet_care/screens/pets_screen.dart';
import 'package:flutter/material.dart';

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

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[900],
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 3),
        content: const Text(
          'Meal deleted',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.greenAccent,
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

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[900],
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 3),
        content: Text(
          '${pet.name} deleted',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.greenAccent,
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
      title: 'Cat Care System',
      theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
      home: DefaultTabController(
        length: 4, // Changed from 3 to 4
        child: Scaffold(
          appBar: AppBar(
            title: const Center(child: Text('Pet Care System')),
            backgroundColor: Colors.orange[400],
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              const TabBar(
                labelColor: Colors.orange,
                unselectedLabelColor: Colors.grey,
                isScrollable: true, // Added to handle 4 tabs better
                tabs: [
                  Tab(icon: Icon(Icons.home), text: 'Home'),
                  Tab(icon: Icon(Icons.schedule), text: 'Schedule Meals'),
                  Tab(icon: Icon(Icons.pets), text: 'Pets'), // New tab
                  Tab(icon: Icon(Icons.smart_toy), text: 'Ask AI'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    const HomeScreen(),
                    ScheduleMealsScreen(
                      onAdd: _addMeals,
                      onRemove: _removeMeals,
                      registeredMeals: _registeredMeals,
                    ),
                    PetsScreen(
                      // New pets screen
                      onAdd: _addPets,
                      onRemove: _removePets,
                      registeredPets: _registeredPets,
                    ),
                    const Center(
                      child: Text(
                        'AI Assistant Coming Soon!',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
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
