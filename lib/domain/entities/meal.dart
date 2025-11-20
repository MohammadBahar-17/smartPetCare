import 'package:smartpetcare/core/enums/pet_type.dart';
import 'package:smartpetcare/core/utils/day_utils.dart';

class Meal {
  final String id;
  final PetType pet;
  final int hour;
  final int minute;
  final double amount;
  final List<int> days; // 0..6

  Meal({
    required this.id,
    required this.pet,
    required this.hour,
    required this.minute,
    required this.amount,
    required this.days,
  });

  String get timeLabel =>
      "${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")}";

  String get daysLabel {
    if (days.length == 7) return "Every day";
    return days.map((d) => DayUtils.dayShortLabels[d]).join(" · ");
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      "animal": pet.firebaseValue, // "cat" أو "dog"
      "hour": hour,
      "minute": minute,
      "amount": amount,
      "days": DayUtils.encodeDays(days), // "all" أو "sun,mon"
    };
  }

  factory Meal.fromFirebase(String id, Map data) {
    return Meal(
      id: id,
      pet: PetTypeX.fromFirebase(data["animal"] ?? "cat"),
      hour: (data["hour"] ?? 0) as int,
      minute: (data["minute"] ?? 0) as int,
      amount: (data["amount"] ?? 0).toDouble(),
      days: DayUtils.decodeDays(data["days"] as String?),
    );
  }

  Meal copyWith({
    String? id,
    PetType? pet,
    int? hour,
    int? minute,
    double? amount,
    List<int>? days,
  }) {
    return Meal(
      id: id ?? this.id,
      pet: pet ?? this.pet,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      amount: amount ?? this.amount,
      days: days ?? this.days,
    );
  }
}
