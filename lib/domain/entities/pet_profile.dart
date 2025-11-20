class PetProfile {
  final String id;
  final String name;
  final String breed;
  final String notes;
  final int age;
  final double weight;
  final String type;
  final String? imageUrl;

  PetProfile({
    required this.id,
    required this.name,
    required this.breed,
    required this.notes,
    required this.age,
    required this.weight,
    required this.type,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "breed": breed,
      "notes": notes,
      "age": age,
      "weight": weight,
      "type": type,
      "imageUrl": imageUrl,
    };
  }

  factory PetProfile.fromMap(String id, Map<String, dynamic> data) {
    return PetProfile(
      id: id,
      name: data["name"],
      breed: data["breed"],
      notes: data["notes"],
      age: data["age"],
      weight: (data["weight"] ?? 0).toDouble(),
      type: data["type"],
      imageUrl: data["imageUrl"],
    );
  }
}
