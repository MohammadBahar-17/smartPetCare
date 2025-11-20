import 'package:smartpetcare/domain/entities/pet_profile.dart';

abstract class ProfileRepository {
  Future<List<PetProfile>> getAllPets();
  Future<String> savePetProfile(PetProfile profile);
  Future<void> updatePetProfile(PetProfile profile);
  Future<void> deletePet(String id);
}
