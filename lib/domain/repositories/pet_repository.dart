import '../entities/meal.dart';
import '../entities/sensors_snapshot.dart';
import 'package:smartpetcare/core/enums/pet_type.dart';

abstract class PetRepository {
  // Sensors
  Stream<SensorsSnapshot> watchSensors();
  Future<SensorsSnapshot?> getSensorsOnce();

  // Feed now
  Future<void> triggerFeed(PetType pet);

  // Meals
  Stream<List<Meal>> watchMeals();
  Future<List<Meal>> getMealsOnce();
  Future<String> addMeal(Meal meal);
  Future<void> updateMeal(Meal meal);
  Future<void> deleteMeal(String id);
}
