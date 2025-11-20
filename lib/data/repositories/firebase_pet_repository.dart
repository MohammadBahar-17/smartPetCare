import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:smartpetcare/core/enums/pet_type.dart';
import 'package:smartpetcare/domain/entities/meal.dart';
import 'package:smartpetcare/domain/entities/sensors_snapshot.dart';
import 'package:smartpetcare/domain/repositories/pet_repository.dart';

class FirebasePetRepository implements PetRepository {
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  DatabaseReference get _sensorsRef => _root.child("sensors");
  DatabaseReference get _commandsRef => _root.child("commands");
  DatabaseReference get _mealsRef => _root.child("meals");

  @override
  Stream<SensorsSnapshot> watchSensors() {
    return _sensorsRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) {
        return SensorsSnapshot(
          dogWeight: 0,
          catWeight: 0,
          dogDistance: 0,
          catDistance: 0,
          dogFoodLevel: 0,
          catFoodLevel: 0,
        );
      }
      return SensorsSnapshot.fromFirebase(
        Map<String, dynamic>.from(data as Map),
      );
    });
  }

  @override
  Future<SensorsSnapshot?> getSensorsOnce() async {
    final snap = await _sensorsRef.get();
    if (!snap.exists) return null;
    return SensorsSnapshot.fromFirebase(
      Map<String, dynamic>.from(snap.value as Map),
    );
  }

  @override
  Future<void> triggerFeed(PetType pet) async {
    if (pet == PetType.dog) {
      await _commandsRef.child("feed_dog").set(1);
    } else {
      await _commandsRef.child("feed_cat").set(1);
    }
  }

  @override
  Stream<List<Meal>> watchMeals() {
    return _mealsRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Meal>[];

      final map = Map<String, dynamic>.from(data as Map);
      final List<Meal> meals = [];
      map.forEach((key, value) {
        meals.add(
          Meal.fromFirebase(key, Map<String, dynamic>.from(value as Map)),
        );
      });

      // ترتيب حسب الوقت
      meals.sort((a, b) {
        final ta = a.hour * 60 + a.minute;
        final tb = b.hour * 60 + b.minute;
        return ta.compareTo(tb);
      });

      return meals;
    });
  }

  @override
  Future<List<Meal>> getMealsOnce() async {
    final snap = await _mealsRef.get();
    if (!snap.exists) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);

    final List<Meal> meals = [];
    map.forEach((key, value) {
      meals.add(
        Meal.fromFirebase(key, Map<String, dynamic>.from(value as Map)),
      );
    });

    meals.sort((a, b) {
      final ta = a.hour * 60 + a.minute;
      final tb = b.hour * 60 + b.minute;
      return ta.compareTo(tb);
    });

    return meals;
  }

  @override
  Future<String> addMeal(Meal meal) async {
    final ref = _mealsRef.push();
    await ref.set(meal.toFirebaseMap());
    return ref.key!;
  }

  @override
  Future<void> updateMeal(Meal meal) async {
    if (meal.id.isEmpty) return;
    await _mealsRef.child(meal.id).set(meal.toFirebaseMap());
  }

  @override
  Future<void> deleteMeal(String id) async {
    await _mealsRef.child(id).remove();
  }
}
