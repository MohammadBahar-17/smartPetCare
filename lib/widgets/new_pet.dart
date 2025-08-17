import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Missing Data',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Please fill in all fields with valid data.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: GoogleFonts.poppins()),
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
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      lastDate: DateTime.now(),
    );
    setState(() {
      _selectedDateOfBirth = date;
    });
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF6B73FF)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Pet',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B73FF),
              ),
            ),
            const SizedBox(height: 20),

            // Pet Name
            TextField(
              controller: _nameController,
              maxLength: 50,
              style: GoogleFonts.poppins(),
              decoration: _inputDecoration('Pet Name', Icons.pets),
            ),
            const SizedBox(height: 12),

            // Pet Type
            Text(
              'Pet Type',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<PetKind>(
                    title: Text('Cat', style: GoogleFonts.poppins()),
                    value: PetKind.cat,
                    groupValue: _selectedKind,
                    activeColor: const Color(0xFFFF6B9D),
                    onChanged: (value) =>
                        setState(() => _selectedKind = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<PetKind>(
                    title: Text('Dog', style: GoogleFonts.poppins()),
                    value: PetKind.dog,
                    groupValue: _selectedKind,
                    activeColor: const Color(0xFFFF6B9D),
                    onChanged: (value) =>
                        setState(() => _selectedKind = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gender
            Text(
              'Gender',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<PetSex>(
                    title: Text('Male', style: GoogleFonts.poppins()),
                    value: PetSex.male,
                    groupValue: _selectedSex,
                    activeColor: const Color(0xFF6B73FF),
                    onChanged: (value) => setState(() => _selectedSex = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<PetSex>(
                    title: Text('Female', style: GoogleFonts.poppins()),
                    value: PetSex.female,
                    groupValue: _selectedSex,
                    activeColor: const Color(0xFF6B73FF),
                    onChanged: (value) => setState(() => _selectedSex = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Age & Weight
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(),
                    decoration: _inputDecoration(
                      'Age (years)',
                      Icons.calendar_today,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(),
                    decoration: _inputDecoration(
                      'Weight (kg)',
                      Icons.monitor_weight,
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
              style: GoogleFonts.poppins(),
              decoration: _inputDecoration('Breed', Icons.category),
            ),
            const SizedBox(height: 12),

            // Photo Picker
            Row(
              children: [
                _selectedImage != null
                    ? CircleAvatar(
                        radius: 36,
                        backgroundImage: FileImage(_selectedImage!),
                      )
                    : const CircleAvatar(
                        radius: 36,
                        child: Icon(Icons.pets, size: 30),
                      ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_camera),
                  label: Text('Add Photo', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date Picker
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _presentDatePicker,
                icon: const Icon(Icons.cake, color: Color(0xFF6B73FF)),
                label: Text(
                  _selectedDateOfBirth == null
                      ? 'Select Date of Birth'
                      : 'Born: ${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.year}',
                  style: GoogleFonts.poppins(),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: const BorderSide(color: Color(0xFF6B73FF)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save / Cancel
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B9D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Save Pet',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
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
