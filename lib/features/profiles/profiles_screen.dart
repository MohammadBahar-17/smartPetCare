import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final _firebase = FirebaseService();

  Map<String, dynamic> pets = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    try {
      final data = await _firebase.getProfiles();
      if (mounted) setState(() => pets = data);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addPet() async {
    final nameCtrl = TextEditingController();
    String selectedType = "cat";
    final ageCtrl = TextEditingController(text: "1");
    final breedCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: "4.0");
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add New Pet"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: "Name",
                      prefixIcon: Icon(Icons.pets),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Type Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: "Type",
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: "cat", child: Text("🐱 Cat")),
                      DropdownMenuItem(value: "dog", child: Text("🐕 Dog")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Age
                  TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Age (years)",
                      prefixIcon: Icon(Icons.cake),
                      suffixText: "years",
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Weight
                  TextField(
                    controller: weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Weight",
                      prefixIcon: Icon(Icons.scale),
                      suffixText: "kg",
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Breed
                  TextField(
                    controller: breedCtrl,
                    decoration: const InputDecoration(
                      labelText: "Breed (optional)",
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Notes (optional)",
                      prefixIcon: Icon(Icons.note),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await _firebase.addProfile(
      name: nameCtrl.text.trim(),
      type: selectedType,
      age: int.tryParse(ageCtrl.text) ?? 1,
      breed: breedCtrl.text.trim(),
      weight: double.tryParse(weightCtrl.text) ?? 4.0,
      notes: notesCtrl.text.trim(),
    );
    await _loadPets();
  }

  Future<void> _deletePet(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Pet?"),
        content: Text("Remove $name from profiles?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.severityHigh,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _firebase.deleteProfile(id);
    await _loadPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🐾 Pet Profiles"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _loadPets,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: "Loading profiles...")
          : RefreshIndicator(
              onRefresh: _loadPets,
              child: pets.isEmpty
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: 400,
                        child: EmptyState(
                          icon: Icons.pets,
                          title: "No pets yet",
                          subtitle: "Add your first pet to get started",
                        ),
                      ),
                    )
                  : _buildPetsList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPet,
        icon: const Icon(Icons.add),
        label: const Text("Add Pet"),
      ),
    );
  }

  Widget _buildPetsList() {
    // Group by type
    final cats = <MapEntry<String, dynamic>>[];
    final dogs = <MapEntry<String, dynamic>>[];

    for (final entry in pets.entries) {
      final p = Map<String, dynamic>.from(entry.value);
      final type = (p['type'] ?? '').toString().toLowerCase();
      if (type == 'cat') {
        cats.add(entry);
      } else {
        dogs.add(entry);
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cats.isNotEmpty) ...[
            const SectionHeader(
              title: "Cats",
              icon: Icons.pets,
            ),
            ...cats.map((e) => _buildPetCard(e.key, e.value)),
            const SizedBox(height: 20),
          ],
          if (dogs.isNotEmpty) ...[
            const SectionHeader(
              title: "Dogs",
              icon: Icons.pets,
            ),
            ...dogs.map((e) => _buildPetCard(e.key, e.value)),
          ],
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildPetCard(String id, dynamic data) {
    final p = Map<String, dynamic>.from(data);
    final name = p['name'] ?? 'Unknown';
    final type = (p['type'] ?? 'pet').toString().toLowerCase();
    final age = p['age'] ?? 0;
    final breed = p['breed'] ?? '';
    final weight = p['weight'] ?? 0.0;
    final notes = p['notes'] ?? '';

    final emoji = type == 'cat' ? '🐱' : '🐕';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (breed.isNotEmpty)
                      Text(
                        breed,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.severityHigh,
                onPressed: () => _deletePet(id, name),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _buildInfoChip(Icons.cake, "$age years"),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.scale, "${weight}kg"),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
