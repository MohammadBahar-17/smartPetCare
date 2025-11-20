class SensorsSnapshot {
  final double dogWeight;
  final double catWeight;
  final double dogDistance;
  final double catDistance;
  final int dogFoodLevel; // %
  final int catFoodLevel; // %

  SensorsSnapshot({
    required this.dogWeight,
    required this.catWeight,
    required this.dogDistance,
    required this.catDistance,
    required this.dogFoodLevel,
    required this.catFoodLevel,
  });

  factory SensorsSnapshot.fromFirebase(Map data) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return double.tryParse(v.toString()) ?? 0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return SensorsSnapshot(
      dogWeight: toDouble(data["dog_weight"]),
      catWeight: toDouble(data["cat_weight"]),
      dogDistance: toDouble(data["dog_distance"]),
      catDistance: toDouble(data["cat_distance"]),
      dogFoodLevel: toInt(data["dog_food_level"]),
      catFoodLevel: toInt(data["cat_food_level"]),
    );
  }
}
