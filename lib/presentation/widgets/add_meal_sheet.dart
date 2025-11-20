import 'package:flutter/material.dart';
import 'package:smartpetcare/domain/entities/meal.dart';
import 'package:smartpetcare/presentation/pages/add_edit_meal_page.dart';

class AddMealSheet {
  static Future<void> show(BuildContext context, {Meal? meal}) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddEditMealPage(existing: meal)));
  }
}
