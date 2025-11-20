import 'package:flutter/material.dart';

const _daysOrder = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
const _daysLabels = {
  'sun': 'Sun',
  'mon': 'Mon',
  'tue': 'Tue',
  'wed': 'Wed',
  'thu': 'Thu',
  'fri': 'Fri',
  'sat': 'Sat',
};

class DaySelector extends StatelessWidget {
  final List<String> selectedDays;
  final ValueChanged<List<String>> onChanged;

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  bool _isSelected(String day) => selectedDays.contains(day);

  void _toggleDay(String day) {
    final newList = List<String>.from(selectedDays);
    if (newList.contains(day)) {
      newList.remove(day);
    } else {
      newList.add(day);
    }
    onChanged(newList);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final d in _daysOrder)
          FilterChip(
            label: Text(_daysLabels[d]!),
            selected: _isSelected(d),
            onSelected: (_) => _toggleDay(d),
          ),
      ],
    );
  }
}
