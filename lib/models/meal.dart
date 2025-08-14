import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Meal {
  final String id;
  final DateTime date;
  final double amount;
  final String title;
  final TimeOfDay time;

  Meal({
    required this.date,
    required this.amount,
    required this.title,
    required this.time,
  }) : id = uuid.v4();
}
