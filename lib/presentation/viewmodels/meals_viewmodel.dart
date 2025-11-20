import 'package:flutter/material.dart';
import 'package:smartpetcare/domain/entities/meal.dart';
import 'package:smartpetcare/domain/repositories/pet_repository.dart';

class MealsViewModel extends ChangeNotifier {
  final PetRepository repo;

  List<Meal> meals = [];
  bool loading = true;

  MealsViewModel(this.repo) {
    _watch();
  }

  void _watch() {
    repo.watchMeals().listen((list) {
      meals = list;
      loading = false;
      notifyListeners();
    });
  }

  Future<void> deleteMeal(String id) async {
    await repo.deleteMeal(id);
  }
}
