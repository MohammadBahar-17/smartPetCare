import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum PetKind { dog, cat }

enum PetSex { male, female }

class Pet {
  final String id;
  final String name;
  final PetSex sex;
  final int age;
  final double weight;
  final PetKind kind;
  final String? photo; // Path to photo or null
  final DateTime dateOfBirth;
  final String breed;

  Pet({
    required this.name,
    required this.sex,
    required this.age,
    required this.weight,
    required this.kind,
    this.photo,
    required this.dateOfBirth,
    required this.breed,
  }) : id = uuid.v4();

  String get kindDisplay => kind == PetKind.dog ? 'Dog' : 'Cat';
  String get sexDisplay => sex == PetSex.male ? 'Male' : 'Female';
}
