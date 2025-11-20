import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartpetcare/presentation/viewmodels/pet_profile_viewmodel.dart';
import 'package:smartpetcare/domain/entities/pet_profile.dart';
import 'package:smartpetcare/presentation/pages/pet_details_page.dart';

class PetProfilePage extends StatelessWidget {
  const PetProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProfileViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("SmartPet Care"), centerTitle: true),

          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: vm.pets.length,
                        itemBuilder: (context, i) {
                          final pet = vm.pets[i];
                          return _buildPetCard(context, pet);
                        },
                      ),
                    ),

                    // -------------------
                    // Add New Pet Button
                    // -------------------
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                        ),
                        onPressed: () {
                          _openAddPetDialog(context);
                        },
                        child: const Text("Add New Pet"),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPetCard(BuildContext context, PetProfile pet) {
    final vm = Provider.of<PetProfileViewModel>(context, listen: false);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PetDetailsPage(pet: pet)),
        );
      },
      child: Hero(
        tag: pet.id,
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: pet.imageUrl != null
                            ? NetworkImage(pet.imageUrl!)
                            : const AssetImage("assets/default_pet.png")
                                  as ImageProvider,
                      ),
                      title: Text(
                        pet.name,
                        style: const TextStyle(fontSize: 20),
                      ),
                      subtitle: Text("${pet.breed} • ${pet.weight} kg"),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            vm.editPet(pet);
                            _openAddPetDialog(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => vm.deletePet(pet.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add Pet Dialog
  void _openAddPetDialog(BuildContext context) {
    final vm = Provider.of<PetProfileViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Pet"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextButton.icon(
                  onPressed: () => vm.pickImage(),
                  icon: const Icon(Icons.photo),
                  label: const Text("Choose Image"),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: "Name"),
                  onChanged: (v) => vm.name = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: "Breed"),
                  onChanged: (v) => vm.breed = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: "Notes"),
                  onChanged: (v) => vm.notes = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: "Age"),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => vm.age = int.tryParse(v) ?? 0,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: "Weight"),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => vm.weight = double.tryParse(v) ?? 0,
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ChoiceChip(
                      label: const Text("Dog"),
                      selected: vm.type == "dog",
                      onSelected: (_) => vm.setType("dog"),
                    ),
                    ChoiceChip(
                      label: const Text("Cat"),
                      selected: vm.type == "cat",
                      onSelected: (_) => vm.setType("cat"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () async {
                await vm.savePet();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
