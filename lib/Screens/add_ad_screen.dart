import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_style.dart';
import '../services/api_service.dart';
import '../widgets/loading_overlay.dart';

class AddAdScreen extends StatefulWidget {
  const AddAdScreen({super.key});

  @override
  State<AddAdScreen> createState() => _AddAdScreenState();
}

class _AddAdScreenState extends State<AddAdScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final ageController = TextEditingController();
  final healthController = TextEditingController();
  final locationController = TextEditingController();

  bool vaccinated = false;

  /// 🔹 category ثابتة
  String category = 'dogs';

  /// 🔹 نوع الإعلان
  String adType = 'sale'; // sale | adoption

  List<File> images = [];
  File? idCard;

  bool isLoading = false;
  final picker = ImagePicker();

  Future<void> pickImages() async {
    if (images.length >= 4) return;
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => images.add(File(picked.path)));
    }
  }

  Future<void> pickIdCard() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => idCard = File(picked.path));
    }
  }

  Future<void> submitAd() async {
    if (!_formKey.currentState!.validate()) return;

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    if (idCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Card is required')),
      );
      return;
    }

    setState(() => isLoading = true);

    final success = await ApiService.addAd(
      name: nameController.text.trim(),
      description: descController.text.trim(),
      price: adType == 'sale' ? priceController.text.trim() : null,
      category: category,
      images: images,
      idCard: idCard!,
      isAdoption: adType == 'adoption',
      age: category == 'food' ? null : ageController.text.trim(),
      vaccinated: category == 'food' ? null : vaccinated,
      healthStatus: category == 'food' ? null : healthController.text.trim(),
      location: category == 'food' ? null : locationController.text.trim(),
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add ad')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: AppStyle.scaffold,
        appBar: AppStyle.primaryAppBar(context, title: 'Add New Ad'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Category'),
                DropdownButtonFormField(
                  value: category,
                  decoration: _decoration(),
                  items: const [
                    DropdownMenuItem(value: 'dogs', child: Text('Dogs')),
                    DropdownMenuItem(value: 'cats', child: Text('Cats')),
                    DropdownMenuItem(value: 'food', child: Text('Food')),
                  ],
                  onChanged: (v) => setState(() => category = v!),
                ),
                _label('Ad Type'),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile(
                        value: 'sale',
                        groupValue: adType,
                        onChanged: (v) => setState(() => adType = v!),
                        title: const Text('For Sale'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile(
                        value: 'adoption',
                        groupValue: adType,
                        onChanged: (v) => setState(() => adType = v!),
                        title: const Text('Adoption'),
                      ),
                    ),
                  ],
                ),
                _label('Name'),
                _input(nameController, 'Enter name'),
                if (category != 'food') ...[
                  _label('Age'),
                  _input(ageController, 'e.g. 1'),
                  _label('Location'),
                  _input(locationController, 'e.g. Cairo'),
                  _label('Health Status'),
                  _input(healthController, 'Healthy / Needs care'),
                  CheckboxListTile(
                    value: vaccinated,
                    onChanged: (v) => setState(() => vaccinated = v!),
                    title: const Text('Vaccinated'),
                  ),
                ],
                _label('Upload ID Card'),
                _imageBox(
                  file: idCard,
                  text: 'Select ID Card',
                  onTap: pickIdCard,
                ),
                if (adType == 'sale') ...[
                  _label('Price'),
                  _input(priceController, 'Enter price'),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'This ad is for adoption 🐾',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                _label('Description'),
                _input(descController, 'Write description', maxLines: 4),
                _label('Images (max 4)'),
                Wrap(
                  spacing: 10,
                  children: [
                    ...images.map(
                      (img) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          img,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (images.length < 4)
                      GestureDetector(
                        onTap: pickImages,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyle.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: submitAd,
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
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
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppStyle.textPrimary,
          ),
        ),
      );

  Widget _input(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: _decoration().copyWith(hintText: hint),
    );
  }

  Widget _imageBox({
    required File? file,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppStyle.surfaceTint),
        ),
        child: file == null
            ? Center(child: Text(text))
            : Image.file(file, fit: BoxFit.cover),
      ),
    );
  }
}
