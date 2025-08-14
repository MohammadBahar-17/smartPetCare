import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/pet.dart';

class NewPet extends StatefulWidget {
  const NewPet({required this.onAddPet, super.key});
  final void Function(Pet pet) onAddPet;

  @override
  State<NewPet> createState() => _NewPetState();
}

class _NewPetState extends State<NewPet> {
  File? _selectedImage;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _breedController = TextEditingController();

  PetKind _selectedKind = PetKind.cat;
  PetSex _selectedSex = PetSex.male;
  DateTime? _selectedDateOfBirth;

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _save() {
    final enteredName = _nameController.text.trim();
    final enteredAge = int.tryParse(_ageController.text.trim());
    final enteredWeight = double.tryParse(_weightController.text.trim());
    final enteredBreed = _breedController.text.trim();

    if (enteredName.isEmpty ||
        enteredAge == null ||
        enteredAge <= 0 ||
        enteredWeight == null ||
        enteredWeight <= 0 ||
        enteredBreed.isEmpty ||
        _selectedDateOfBirth == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Missing Data'),
          content: const Text('Please fill in all fields with valid data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    widget.onAddPet(
      Pet(
        name: enteredName,
        sex: _selectedSex,
        age: enteredAge,
        weight: enteredWeight,
        kind: _selectedKind,
        dateOfBirth: _selectedDateOfBirth!,
        breed: enteredBreed,
        photo: _selectedImage?.path,
      ),
    );
    Navigator.pop(context);
  }

  void _presentDatePicker() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(
        const Duration(days: 365 * 20),
      ), // 20 years ago
      lastDate: DateTime.now(),
    );
    setState(() {
      _selectedDateOfBirth = date;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Pet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Pet Name
            TextField(
              controller: _nameController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: 'Pet Name',
                hintText: 'e.g., Fluffy, Max',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pets),
              ),
            ),
            const SizedBox(height: 8),

            // Kind Selection
            const Text(
              'Pet Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<PetKind>(
                    title: const Text('Cat'),
                    value: PetKind.cat,
                    groupValue: _selectedKind,
                    onChanged: (value) =>
                        setState(() => _selectedKind = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<PetKind>(
                    title: const Text('Dog'),
                    value: PetKind.dog,
                    groupValue: _selectedKind,
                    onChanged: (value) =>
                        setState(() => _selectedKind = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sex Selection
            const Text(
              'Gender',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<PetSex>(
                    title: const Text('Male'),
                    value: PetSex.male,
                    groupValue: _selectedSex,
                    onChanged: (value) => setState(() => _selectedSex = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<PetSex>(
                    title: const Text('Female'),
                    value: PetSex.female,
                    groupValue: _selectedSex,
                    onChanged: (value) => setState(() => _selectedSex = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Age and Weight
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age (years)',
                      hintText: 'e.g., 3',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      hintText: 'e.g., 4.5',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Breed
            TextField(
              controller: _breedController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: 'Breed',
                hintText: 'e.g., Persian, Golden Retriever',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 8),

            // Pet Photo
            Row(
              children: [
                _selectedImage != null
                    ? CircleAvatar(
                        radius: 32,
                        backgroundImage: FileImage(_selectedImage!),
                      )
                    : const CircleAvatar(
                        radius: 32,
                        child: Icon(Icons.pets, size: 32),
                      ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Add Photo'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date of Birth
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _presentDatePicker,
                icon: const Icon(Icons.cake),
                label: _selectedDateOfBirth == null
                    ? const Text('Select Date of Birth')
                    : Text(
                        'Born: ${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.year}',
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Save and Cancel buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Pet'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
