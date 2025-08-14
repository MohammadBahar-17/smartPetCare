import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../widgets/pet_list.dart';
import '../widgets/new_pet.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({
    super.key,
    required this.registeredPets,
    required this.onAdd,
    required this.onRemove,
  });

  final void Function(Pet pet, BuildContext context) onRemove;
  final List<Pet> registeredPets;
  final void Function(Pet pet) onAdd;

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  void _openAddPetOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: NewPet(onAddPet: widget.onAdd),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAddPetOverlay,
              icon: const Icon(Icons.add),
              label: const Text('Add New Pet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: widget.registeredPets.isEmpty
              ? const Center(
                  child: Text(
                    'No pets registered yet.\nTap "Add New Pet" to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : PetList(
                  pets: widget.registeredPets,
                  onRemove: (pet, context) => widget.onRemove(pet, context),
                ),
        ),
      ],
    );
  }
}
