import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:smartpetcare/firebase_options.dart';
import 'package:smartpetcare/core/theme/app_theme.dart';

import 'package:smartpetcare/data/repositories/firebase_pet_repository.dart';
import 'package:smartpetcare/data/repositories/firebase_profile_repository.dart';

import 'package:smartpetcare/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:smartpetcare/presentation/viewmodels/meals_viewmodel.dart';
import 'package:smartpetcare/presentation/viewmodels/pet_profile_viewmodel.dart';

import 'package:smartpetcare/presentation/pages/dashboard_page.dart';
import 'package:smartpetcare/presentation/pages/meals_page.dart';
import 'package:smartpetcare/presentation/pages/pet_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(FirebasePetRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => MealsViewModel(FirebasePetRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final vm = PetProfileViewModel(FirebaseProfileRepository());
            vm.loadPets(); // ⬅⬅⬅ The important modification
            return vm;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int index = 0;

  final pages = [
    const DashboardPage(),
    const MealsPage(),
    const PetProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SmartPet Care",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: pages[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu),
              label: "Meals",
            ),
            NavigationDestination(icon: Icon(Icons.pets), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
