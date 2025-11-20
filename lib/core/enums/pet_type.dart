enum PetType { cat, dog }

extension PetTypeX on PetType {
  String get label {
    switch (this) {
      case PetType.cat:
        return "Cat";
      case PetType.dog:
        return "Dog";
    }
  }

  String get firebaseValue => name; // "cat" or "dog"

  static PetType fromFirebase(String value) {
    switch (value) {
      case "dog":
        return PetType.dog;
      case "cat":
      default:
        return PetType.cat;
    }
  }
}
