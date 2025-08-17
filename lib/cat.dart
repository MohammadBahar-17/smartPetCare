import 'package:flutter/material.dart';
import 'package:smart_pet_care/screens/ai_chat.dart';
import 'package:smart_pet_care/screens/home_screen.dart';
import 'package:smart_pet_care/screens/pets_screen.dart';
import 'package:smart_pet_care/screens/schedule_meals_screen.dart';
import 'package:smart_pet_care/screens/notifications_screen.dart';
import 'package:smart_pet_care/theme/app_theme.dart';
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
      photo:
          'https://images.unsplash.com/photo-1472491235688-bdc81a63246e?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8Y2F0fGVufDB8fDB8fHww',
    ),
    Pet(
      name: 'Buddy',
      sex: PetSex.female,
      age: 2,
      weight: 12.5,
      kind: PetKind.dog,
      dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 2)),
      breed: 'Golden Retriever',
      photo:
          'https://plus.unsplash.com/premium_photo-1694819488591-a43907d1c5cc?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8ZG9nfGVufDB8fDB8fHww',
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
      title: 'Smart Pet Care',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(registeredMeals: [], registeredPets: []),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.registeredMeals,
    required this.registeredPets,
  });

  final List<Meal> registeredMeals;
  final List<Pet> registeredPets;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late List<Meal> _registeredMeals;
  late List<Pet> _registeredPets;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _registeredMeals = List.from(widget.registeredMeals);
    _registeredPets = List.from(widget.registeredPets);

    // Add sample data if empty
    if (_registeredMeals.isEmpty) {
      _registeredMeals.addAll([
        Meal(
          date: DateTime.now(),
          amount: 100,
          title: 'Morning Meal',
          time: const TimeOfDay(hour: 7, minute: 30),
        ),
        Meal(
          date: DateTime.now(),
          amount: 150,
          title: 'Evening Meal',
          time: const TimeOfDay(hour: 18, minute: 0),
        ),
      ]);
    }

    if (_registeredPets.isEmpty) {
      _registeredPets.addAll([
        Pet(
          name: 'Whiskers',
          sex: PetSex.male,
          age: 3,
          weight: 4.2,
          kind: PetKind.cat,
          dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 3)),
          breed: 'Persian',
          photo:
              'https://images.unsplash.com/photo-1472491235688-bdc81a63246e?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8Y2F0fGVufDB8fDB8fHww',
        ),
        Pet(
          name: 'Buddy',
          sex: PetSex.female,
          age: 2,
          weight: 12.5,
          kind: PetKind.dog,
          dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 2)),
          breed: 'Golden Retriever',
          photo:
              'https://plus.unsplash.com/premium_photo-1694819488591-a43907d1c5cc?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8ZG9nfGVufDB8fDB8fHww',
        ),
      ]);
    }
  }

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
        backgroundColor: AppTheme.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 3),
        content: const Text(
          'Meal deleted',
          style: TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppTheme.coralPink,
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
        backgroundColor: AppTheme.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 3),
        content: Text(
          '${pet.name} deleted',
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppTheme.coralPink,
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Header
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: AppTheme.cardRadius,
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Pet Care',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Your pet\'s companion',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Navigation
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    const HomeScreen(),
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
                    const AiChatScreen(),
                    const NotificationsScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.schedule_rounded, 'Meals'),
                _buildNavItem(2, Icons.pets_rounded, 'Pets'),
                _buildNavItem(3, Icons.smart_toy_rounded, 'AI'),
                _buildNavItem(4, Icons.notifications_rounded, 'Alerts'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
