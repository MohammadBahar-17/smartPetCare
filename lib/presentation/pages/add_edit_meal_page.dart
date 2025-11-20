import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartpetcare/core/enums/pet_type.dart';
import 'package:smartpetcare/core/utils/day_utils.dart';
import 'package:smartpetcare/domain/entities/meal.dart';
import 'package:smartpetcare/presentation/viewmodels/meals_viewmodel.dart';
import 'package:smartpetcare/presentation/widgets/action_button.dart';
import 'package:smartpetcare/presentation/widgets/day_selector.dart';

class AddEditMealPage extends StatefulWidget {
  final Meal? existing;

  const AddEditMealPage({super.key, this.existing});

  @override
  State<AddEditMealPage> createState() => _AddEditMealPageState();
}

class _AddEditMealPageState extends State<AddEditMealPage> {
  late PetType _petType;
  late TimeOfDay _time;
  final _amountController = TextEditingController();
  List<String> _days = List.from([
    'sun',
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
    'sat',
  ]);

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final m = widget.existing!;
      _petType = m.pet;
      _time = TimeOfDay(hour: m.hour, minute: m.minute);
      _amountController.text = m.amount.toStringAsFixed(0);
      if (m.days.isNotEmpty) {
        // Convert int days to string days
        _days = m.days.map((d) => DayUtils.dayKeys[d]).toList();
      }
    } else {
      _petType = PetType.dog;
      _time = const TimeOfDay(hour: 12, minute: 0);
      _amountController.text = '100';
    }
  }

  Future<void> _save() async {
    if (_amountController.text.isEmpty) return;

    final amount = double.tryParse(_amountController.text) ?? 0;

    final vm = context.read<MealsViewModel>();
    final meal = Meal(
      id: widget.existing?.id ?? '',
      pet: _petType,
      hour: _time.hour,
      minute: _time.minute,
      amount: amount,
      days: _days.map((d) => DayUtils.dayKeys.indexOf(d)).toList(),
    );

    if (widget.existing == null) {
      await vm.repo.addMeal(meal);
    } else {
      await vm.repo.addMeal(meal);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Meal' : 'Edit Meal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Pet Type
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Dog'),
                  selected: _petType == PetType.dog,
                  onSelected: (v) => setState(() => _petType = PetType.dog),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Cat'),
                  selected: _petType == PetType.cat,
                  onSelected: (v) => setState(() => _petType = PetType.cat),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Time
          ListTile(
            title: const Text('Time'),
            trailing: Text(
              _time.format(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (t != null) setState(() => _time = t);
            },
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 20),

          // Amount
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (grams)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Days
          const Text(
            'Repeat on',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DaySelector(
            selectedDays: _days,
            onChanged: (list) => setState(() => _days = list),
          ),
          const SizedBox(height: 30),

          // Save
          ActionButton(
            label: 'Save Meal',
            icon: Icons.save,
            onTap: _save,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}
