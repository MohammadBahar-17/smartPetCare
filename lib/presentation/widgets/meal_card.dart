import 'package:flutter/material.dart';
import 'package:smartpetcare/core/enums/pet_type.dart';
import 'package:smartpetcare/core/utils/day_utils.dart';
import 'package:smartpetcare/domain/entities/meal.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MealCard({
    super.key,
    required this.meal,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _petIcon(PetType type) {
    switch (type) {
      case PetType.dog:
        return Icons.pets;
      case PetType.cat:
        return Icons.pets_outlined;
    }
  }

  String _timeLabel(int h, int m) {
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _daysLabel(List<int> days) {
    if (days.isEmpty) return 'All days';
    if (days.length == 7) return 'All days';
    return days.map((d) => DayUtils.dayKeys[d]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                child: Icon(_petIcon(meal.pet), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timeLabel(meal.hour, meal.minute),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.amount.toStringAsFixed(0)} g • ${_daysLabel(meal.days)}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
