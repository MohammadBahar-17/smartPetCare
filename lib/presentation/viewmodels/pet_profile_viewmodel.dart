import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartpetcare/domain/entities/pet_profile.dart';
import 'package:smartpetcare/domain/repositories/profile_repository.dart';

class PetProfileViewModel extends ChangeNotifier {
  final ProfileRepository repository;
  final db = FirebaseDatabase.instance.ref("profiles");

  List<PetProfile> pets = [];
  bool isLoading = false;

  // Temporary fields for the form
  String name = "";
  String breed = "";
  String notes = "";
  int age = 0;
  double weight = 0.0;
  String type = "dog";

  Uint8List? imageBytes;
  String? imageUrl;

  PetProfileViewModel(this.repository);

  // Load all pets
  Future<void> loadPets() async {
    isLoading = true;
    notifyListeners();

    pets = await repository.getAllPets();

    isLoading = false;
    notifyListeners();
  }

  Future pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    imageBytes = await file.readAsBytes();
    notifyListeners();
  }

  Future<String?> uploadImage(String petId) async {
    if (imageBytes == null) return null;

    final ref = FirebaseStorage.instance.ref().child("pets_images/$petId.jpg");

    await ref.putData(imageBytes!, SettableMetadata(contentType: "image/jpeg"));

    return await ref.getDownloadURL();
  }

  // Save new pet
  Future<void> savePet() async {
    final profile = PetProfile(
      id: "",
      name: name,
      breed: breed,
      notes: notes,
      age: age,
      weight: weight,
      type: type,
      imageUrl: null,
    );

    // 1) خزّن الحيوان وخذ الـ ID
    final newId = await repository.savePetProfile(profile);

    // 2) إذا فيه صورة… نرفعها
    String? url;
    if (imageBytes != null) {
      url = await uploadImage(newId);
    }

    // 3) حدّث الحيوان مع الصورة
    await repository.updatePetProfile(
      PetProfile(
        id: newId,
        name: name,
        breed: breed,
        notes: notes,
        age: age,
        weight: weight,
        type: type,
        imageUrl: url,
      ),
    );

    // 4) أعِد تحميل الحيوانات
    await loadPets();
  }

  Future<void> deletePet(String id) async {
    await repository.deletePet(id);
    await loadPets();
  }

  void editPet(PetProfile pet) {
    // For now, we just print to console or similar, as the user didn't specify the full edit flow
    // But to avoid errors in UI, we need this method.
    // Ideally, this should populate the fields and open the dialog.
    name = pet.name;
    breed = pet.breed;
    notes = pet.notes;
    age = pet.age;
    weight = pet.weight;
    type = pet.type;
    imageUrl = pet.imageUrl;
    notifyListeners();
  }

  // Set pet type
  void setType(String newType) {
    type = newType;
    notifyListeners();
  }
}
