import 'package:flutter/material.dart';
import 'package:smartpetcare/domain/entities/pet_profile.dart';

class PetDetailsPage extends StatelessWidget {
  final PetProfile pet;

  const PetDetailsPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pet.name)),
      body: Column(
        children: [
          Hero(
            tag: pet.id,
            child: CircleAvatar(
              radius: 80,
              backgroundImage: pet.imageUrl != null
                  ? NetworkImage(pet.imageUrl!)
                  : const AssetImage("assets/default_pet.png") as ImageProvider,
            ),
          ),
          const SizedBox(height: 20),
          Text(pet.breed, style: const TextStyle(fontSize: 22)),
          Text("Age: ${pet.age}"),
          Text("Weight: ${pet.weight} kg"),
          Text("Notes: ${pet.notes}"),
        ],
      ),
    );
  }
}
