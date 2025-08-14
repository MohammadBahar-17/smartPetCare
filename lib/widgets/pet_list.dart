import 'package:flutter/material.dart';
import '../models/pet.dart';

class PetList extends StatelessWidget {
  const PetList({required this.pets, super.key, required this.onRemove});
  final Function(Pet pet, BuildContext context) onRemove;
  final List<Pet> pets;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return Dismissible(
                key: ValueKey(pet.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                confirmDismiss: (direction) async {
                  onRemove(pet, context);
                  return false; // Prevent automatic dismissal
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: pet.kind == PetKind.dog
                                  ? Colors.blue[100]
                                  : Colors.green[100],
                              child: pet.photo != null
                                  ? ClipOval(
                                      child: Image.asset(
                                        pet.photo!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            pet.kind == PetKind.dog
                                                ? Icons.pets
                                                : Icons
                                                      .pets_outlined, // Cat icon
                                            size: 30,
                                            color: pet.kind == PetKind.dog
                                                ? Colors.blue[700]
                                                : Colors.green[700],
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      pet.kind == PetKind.dog
                                          ? Icons.pets
                                          : Icons.pets_outlined, // Cat icon
                                      size: 30,
                                      color: pet.kind == PetKind.dog
                                          ? Colors.blue[700]
                                          : Colors.green[700],
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        pet.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: pet.kind == PetKind.dog
                                              ? Colors.blue[50]
                                              : Colors.green[50],
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          pet.kindDisplay,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: pet.kind == PetKind.dog
                                                ? Colors.blue[700]
                                                : Colors.green[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pet.breed,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoChip(
                                icon: Icons.calendar_today,
                                label: '${pet.age} years',
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InfoChip(
                                icon: pet.sex == PetSex.male
                                    ? Icons.male
                                    : Icons.female,
                                label: pet.sexDisplay,
                                color: pet.sex == PetSex.male
                                    ? Colors.blue
                                    : Colors.pink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InfoChip(
                                icon: Icons.monitor_weight,
                                label: '${pet.weight} kg',
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Born: ${pet.dateOfBirth.day.toString().padLeft(2, '0')}/${pet.dateOfBirth.month.toString().padLeft(2, '0')}/${pet.dateOfBirth.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
