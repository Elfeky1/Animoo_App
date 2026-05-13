import 'package:flutter/material.dart';

import '../core/theme/app_style.dart';
import '../services/api_service.dart';
import 'add_pet_screen.dart';
import 'pet_details_screen.dart';

class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> {
  bool isLoading = true;
  List pets = [];

  @override
  void initState() {
    super.initState();
    fetchPets();
  }

  Future<void> fetchPets() async {
    final data = await ApiService.getMyPets();
    if (!mounted) return;

    setState(() {
      pets = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.scaffold,
      appBar: AppStyle.primaryAppBar(context, title: 'My Pets'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppStyle.primary,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPetScreen()),
          );
          fetchPets();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Pet', style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: AppStyle.surfaceTint,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppStyle.accent.withOpacity(0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.pets_rounded,
                            size: 42,
                            color: AppStyle.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'No pets yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppStyle.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start by adding your first pet profile and keep all care details in one place.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppStyle.textMuted,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppStyle.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddPetScreen(),
                              ),
                            );
                            fetchPets();
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Pet'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchPets,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: pets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _petCard(pets[index]),
                  ),
                ),
    );
  }

  Widget _petCard(Map pet) {
    final image = pet['image']?.toString();
    final hasImage = image != null && image.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PetDetailsScreen(pet: pet),
          ),
        );
        fetchPets();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppStyle.cardDecoration(radius: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasImage
                  ? Image.network(
                      '${ApiService.baseUrl}/uploads/$image',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: AppStyle.surfaceTint,
                      child: const Icon(Icons.pets, color: AppStyle.primary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppStyle.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_titleCase(pet['type'])}${_buildBreedSuffix(pet['breed'])}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((pet['age'] ?? '').toString().isNotEmpty)
                        _miniPill(Icons.cake_outlined, '${pet['age']} years'),
                      if ((pet['weight'] ?? '').toString().isNotEmpty)
                        _miniPill(Icons.monitor_weight_outlined, '${pet['weight']} kg'),
                      if (_extractFoodTimes(pet).isNotEmpty)
                        _miniPill(
                          Icons.restaurant_outlined,
                          '${pet['mealsPerDay'] ?? _extractFoodTimes(pet).length} meals',
                        ),
                      if ((pet['vaccineReminderDate'] ?? '').toString().isNotEmpty)
                        _miniPill(Icons.vaccines_outlined, pet['vaccineReminderDate']),
                    ],
                  ),
                  if (_extractFoodTimes(pet).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _extractFoodTimes(pet)
                          .map(
                            (time) => _miniPill(Icons.schedule, time),
                          )
                          .toList(),
                    ),
                  ],
                  if ((pet['notes'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      pet['notes'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPetScreen(pet: pet),
                    ),
                  );
                  fetchPets();
                  return;
                }

                if (value == 'delete') {
                  await _deletePet(pet);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePet(Map pet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Delete ${pet['name']} from your pets?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.deletePet(pet['_id']);
    if (!mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pet deleted')),
    );
    fetchPets();
  }

  Widget _miniPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppStyle.surfaceTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppStyle.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppStyle.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return 'Pet';
    return text[0].toUpperCase() + text.substring(1);
  }

  String _buildBreedSuffix(dynamic value) {
    final breed = value?.toString() ?? '';
    return breed.isEmpty ? '' : ' - $breed';
  }

  List<String> _extractFoodTimes(Map pet) {
    final raw = pet['foodReminderTimes'];
    if (raw is List) {
      return raw.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
    }
    return [];
  }
}
