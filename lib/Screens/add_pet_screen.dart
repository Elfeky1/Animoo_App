import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_style.dart';
import '../services/api_service.dart';

class AddPetScreen extends StatefulWidget {
  final Map? pet;

  const AddPetScreen({super.key, this.pet});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final vaccineReminderController = TextEditingController();
  final notesController = TextEditingController();
  final picker = ImagePicker();

  String selectedType = 'dog';
  String selectedGender = 'unknown';
  int mealsPerDay = 1;
  List<TextEditingController> foodTimeControllers = [TextEditingController()];
  File? selectedImage;
  bool isSaving = false;

  bool get isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    if (pet != null) {
      nameController.text = pet['name']?.toString() ?? '';
      breedController.text = pet['breed']?.toString() ?? '';
      ageController.text = pet['age']?.toString() ?? '';
      weightController.text = pet['weight']?.toString() ?? '';
      vaccineReminderController.text =
          pet['vaccineReminderDate']?.toString() ?? '';
      notesController.text = pet['notes']?.toString() ?? '';
      selectedType = pet['type']?.toString() ?? 'dog';
      selectedGender = pet['gender']?.toString() ?? 'unknown';
      mealsPerDay = _safeMealsPerDay(pet['mealsPerDay']);
      final existingTimes = _extractFoodTimes(pet);
      foodTimeControllers = List.generate(
        mealsPerDay,
        (index) => TextEditingController(
          text: index < existingTimes.length ? existingTimes[index] : '',
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    ageController.dispose();
    weightController.dispose();
    vaccineReminderController.dispose();
    notesController.dispose();
    for (final controller in foodTimeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      selectedImage = File(picked.path);
    });
  }

  Future<void> pickFoodReminderTime(int index) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (result == null) return;

    setState(() {
      foodTimeControllers[index].text = result.format(context);
    });
  }

  Future<void> pickVaccineReminderDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (result == null) return;

    final month = result.month.toString().padLeft(2, '0');
    final day = result.day.toString().padLeft(2, '0');
    setState(() {
      vaccineReminderController.text = '${result.year}-$month-$day';
    });
  }

  void updateMealsPerDay(int count) {
    final oldControllers = foodTimeControllers;
    final newControllers = List.generate(
      count,
      (index) => TextEditingController(
        text: index < oldControllers.length ? oldControllers[index].text : '',
      ),
    );

    setState(() {
      mealsPerDay = count;
      foodTimeControllers = newControllers;
    });

    for (final controller in oldControllers) {
      if (!newControllers.contains(controller)) {
        controller.dispose();
      }
    }
  }

  Future<void> savePet() async {
    if (!formKey.currentState!.validate() || isSaving) return;

    setState(() => isSaving = true);

    final foodTimes = foodTimeControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final success = isEditing
        ? await ApiService.updatePet(
            id: widget.pet!['_id'],
            name: nameController.text.trim(),
            type: selectedType,
            breed: breedController.text.trim(),
            age: ageController.text.trim(),
            weight: weightController.text.trim(),
            gender: selectedGender,
            mealsPerDay: mealsPerDay,
            foodReminderTimes: foodTimes,
            vaccineReminderDate: vaccineReminderController.text.trim(),
            notes: notesController.text.trim(),
            image: selectedImage,
          )
        : await ApiService.addPet(
            name: nameController.text.trim(),
            type: selectedType,
            breed: breedController.text.trim(),
            age: ageController.text.trim(),
            weight: weightController.text.trim(),
            gender: selectedGender,
            mealsPerDay: mealsPerDay,
            foodReminderTimes: foodTimes,
            vaccineReminderDate: vaccineReminderController.text.trim(),
            notes: notesController.text.trim(),
            image: selectedImage,
          );

    if (!mounted) return;

    setState(() => isSaving = false);

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing ? 'Failed to update pet' : 'Failed to save pet'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingImage = widget.pet?['image']?.toString();
    final hasExistingImage = existingImage != null && existingImage.isNotEmpty;

    return Scaffold(
      backgroundColor: AppStyle.scaffold,
      appBar: AppStyle.primaryAppBar(
        context,
        title: isEditing ? 'Edit Pet' : 'Add Pet',
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppStyle.primary, Color(0xff2b5d95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppStyle.primary.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: selectedImage != null
                            ? Image.file(selectedImage!, fit: BoxFit.cover)
                            : hasExistingImage
                                ? Image.network(
                                    '${ApiService.baseUrl}/uploads/$existingImage',
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.pets_rounded,
                                    size: 42,
                                    color: Colors.white,
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Update your pet profile' : 'Create a pet profile',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEditing
                              ? 'Refresh details, reminders, and notes for your lovely pet.'
                              : 'Add the basics, feeding schedule, and reminders in one simple form.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.86),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: pickImage,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(hasExistingImage || selectedImage != null
                              ? 'Change Photo'
                              : 'Add Photo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Basic Info',
              subtitle: 'Add the main details so your pet profile looks complete.',
              icon: Icons.badge_outlined,
              child: Column(
                children: [
                  _field(
                    controller: nameController,
                    label: 'Pet Name',
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _dropdownField(
                    label: 'Pet Type',
                    value: selectedType,
                    items: const {
                      'dog': 'Dog',
                      'cat': 'Cat',
                      'bird': 'Bird',
                      'other': 'Other',
                    },
                    onChanged: (value) => setState(() => selectedType = value!),
                  ),
                  const SizedBox(height: 12),
                  _field(controller: breedController, label: 'Breed'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: ageController,
                          label: 'Age',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: weightController,
                          label: 'Weight',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _dropdownField(
                    label: 'Gender',
                    value: selectedGender,
                    items: const {
                      'unknown': 'Unknown',
                      'male': 'Male',
                      'female': 'Female',
                    },
                    onChanged: (value) => setState(() => selectedGender = value!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Care Schedule',
              subtitle: 'Set meals and reminder dates so you never miss a thing.',
              icon: Icons.schedule_rounded,
              child: Column(
                children: [
                  _dropdownField(
                    label: 'Meals Per Day',
                    value: mealsPerDay.toString(),
                    items: const {
                      '1': '1 meal',
                      '2': '2 meals',
                      '3': '3 meals',
                      '4': '4 meals',
                      '5': '5 meals',
                    },
                    onChanged: (value) {
                      if (value == null) return;
                      updateMealsPerDay(int.parse(value));
                    },
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    foodTimeControllers.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == foodTimeControllers.length - 1 ? 0 : 12,
                      ),
                      child: _pickerField(
                        controller: foodTimeControllers[index],
                        label: 'Meal ${index + 1} Time',
                        hint: 'Pick a time',
                        icon: Icons.access_time,
                        onTap: () => pickFoodReminderTime(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _pickerField(
                    controller: vaccineReminderController,
                    label: 'Vaccine Reminder Date',
                    hint: 'Pick a date',
                    icon: Icons.calendar_month_outlined,
                    onTap: pickVaccineReminderDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Extra Notes',
              subtitle: 'Anything special like allergies, habits, or care tips.',
              icon: Icons.edit_note_rounded,
              child: _field(
                controller: notesController,
                label: 'Notes',
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyle.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: isSaving ? null : savePet,
                child: Text(
                  isSaving
                      ? (isEditing ? 'Updating...' : 'Saving...')
                      : (isEditing ? 'Update Pet' : 'Save Pet'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppStyle.surfaceTint.withOpacity(0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppStyle.primary),
        ),
        labelStyle: const TextStyle(color: AppStyle.textMuted),
        hintStyle: const TextStyle(color: AppStyle.textMuted),
      ),
    );
  }

  Widget _pickerField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: Icon(icon, color: AppStyle.primary),
        filled: true,
        fillColor: AppStyle.surfaceTint.withOpacity(0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppStyle.primary),
        ),
        labelStyle: const TextStyle(color: AppStyle.textMuted),
        hintStyle: const TextStyle(color: AppStyle.textMuted),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required Map<String, String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppStyle.surfaceTint.withOpacity(0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppStyle.primary),
        ),
        labelStyle: const TextStyle(color: AppStyle.textMuted),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppStyle.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppStyle.surfaceTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppStyle.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppStyle.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppStyle.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  int _safeMealsPerDay(dynamic value) {
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 1 || parsed > 5) return 1;
    return parsed;
  }

  List<String> _extractFoodTimes(Map pet) {
    final raw = pet['foodReminderTimes'];

    if (raw is List) {
      return raw.map((item) => item.toString()).toList();
    }

    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        }
      } catch (_) {}
    }

    return [];
  }
}
