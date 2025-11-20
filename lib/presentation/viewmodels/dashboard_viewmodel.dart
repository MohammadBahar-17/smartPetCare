import 'package:flutter/material.dart';
import 'package:smartpetcare/core/enums/pet_type.dart';
import 'package:smartpetcare/domain/entities/sensors_snapshot.dart';
import 'package:smartpetcare/domain/repositories/pet_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final PetRepository repo;

  SensorsSnapshot? sensors;
  bool loading = true;

  DashboardViewModel(this.repo) {
    _start();
  }

  void _start() {
    repo.watchSensors().listen((snap) {
      sensors = snap;
      loading = false;
      notifyListeners();
    });
  }

  Future<void> feedDog() async {
    await repo.triggerFeed(PetType.dog);
  }

  Future<void> feedCat() async {
    await repo.triggerFeed(PetType.cat);
  }
}
