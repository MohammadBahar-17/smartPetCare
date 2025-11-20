import 'package:firebase_database/firebase_database.dart';
import 'package:smartpetcare/domain/entities/pet_profile.dart';
import 'package:smartpetcare/domain/repositories/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  final _db = FirebaseDatabase.instance.ref("profiles");

  @override
  Future<List<PetProfile>> getAllPets() async {
    final ref = _db.child("pets");
    final snap = await ref.get();

    if (!snap.exists) return [];

    return snap.children.map((c) {
      return PetProfile.fromMap(
        c.key!,
        Map<String, dynamic>.from(c.value as Map),
      );
    }).toList();
  }

  @override
  Future<String> savePetProfile(PetProfile pet) async {
    final ref = _db.child("pets").push();
    final newId = ref.key;

    await ref.set(pet.toMap());

    return newId!;
  }

  @override
  Future<void> updatePetProfile(PetProfile pet) async {
    await _db.child("pets/${pet.id}").update(pet.toMap());
  }

  @override
  Future<void> deletePet(String id) async {
    await _db.child("pets/$id").remove();
  }
}
