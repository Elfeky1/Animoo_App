import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/loading_overlay.dart';

class EditAdScreen extends StatefulWidget {
  const EditAdScreen({super.key});

  @override
  State<EditAdScreen> createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final ageController = TextEditingController();
  final healthController = TextEditingController();
  final locationController = TextEditingController();

  bool vaccinated = false;

  /// sale | adoption
  String adType = 'sale';

  /// dogs | cats | food
  String category = 'dogs';

  List<File> newImages = [];
  List oldImages = [];

  bool isLoading = false;
  final picker = ImagePicker();

  late Map ad;
  bool initialized = false;

  // ================= INIT =================
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;

    ad = ModalRoute.of(context)!.settings.arguments as Map;

    nameController.text = ad['name'] ?? '';
    descController.text = ad['description'] ?? '';
    priceController.text = ad['price'] ?? '';
    ageController.text = ad['age']?.toString() ?? '';
    healthController.text = ad['healthStatus'] ?? '';
    locationController.text = ad['location'] ?? '';
    vaccinated = ad['vaccinated'] ?? false;

    category = ad['category'] ?? 'dogs';
    adType = ad['isAdoption'] == true ? 'adoption' : 'sale';

    oldImages = List.from(ad['images'] ?? []);

    initialized = true;
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    if (newImages.length + oldImages.length >= 4) return;

    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        newImages.add(File(picked.path));
      });
    }
  }

  Future<void> pickImageFromCamera() async {
    if (newImages.length + oldImages.length >= 4) return;

    final XFile? picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        newImages.add(File(picked.path));
      });
    }
  }

  Future<void> showImageSourcePicker() async {
    if (newImages.length + oldImages.length >= 4) return;

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Open camera'),
                onTap: () {
                  Navigator.pop(context);
                  pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= SUBMIT =================
  Future<void> submitEdit() async {
    if (!_formKey.currentState!.validate()) return;
    if (oldImages.isEmpty && newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please keep at least one image')),
      );
      return;
    }

    setState(() => isLoading = true);

    final success = await ApiService.updateAd(
      id: ad['_id'],
      name: nameController.text.trim(),
      description: descController.text.trim(),
      price: adType == 'sale' ? priceController.text.trim() : null,
      category: category,
      isAdoption: adType == 'adoption',
      existingImages: oldImages,
      newImages: newImages,
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
        const SnackBar(content: Text('Failed to update ad')),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xfff2f2f2),
        appBar: AppBar(
          backgroundColor: const Color(0xff24394a),
          title: const Text('Edit Ad'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Ad Type'),
                Wrap(
                  spacing: 10,
                  children: [
                    _chip('For Sale', 'sale'),
                    _chip('Adoption', 'adoption'),
                  ],
                ),
                _label('Name'),
                _input(nameController),
                if (adType == 'sale') ...[
                  _label('Price'),
                  _input(priceController),
                ] else ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
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
                _input(descController, maxLines: 4),
                if (category != 'food') ...[
                  _label('Age'),
                  _input(ageController),
                  _label('Location'),
                  _input(locationController),
                  _label('Health Status'),
                  _input(healthController),
                  CheckboxListTile(
                    value: vaccinated,
                    onChanged: (v) => setState(() => vaccinated = v!),
                    title: const Text('Vaccinated'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
                _label('Images'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...oldImages.map(
                      (img) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              '${ApiService.baseUrl}/uploads/$img',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => oldImages.remove(img));
                              },
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...newImages.map(
                      (img) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              img,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => newImages.remove(img));
                              },
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (oldImages.length + newImages.length < 4)
                      GestureDetector(
                        onTap: showImageSourcePicker,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ),
                  ],
                ),
                if (oldImages.length + newImages.length < 4)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Add from gallery or camera',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff24394a),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: submitEdit,
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white, fontSize: 18),
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

  Widget _chip(String text, String value) {
    final selected = adType == value;
    return ChoiceChip(
      label: Text(text),
      selected: selected,
      selectedColor: const Color(0xff24394a),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => setState(() => adType = value),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _input(TextEditingController c, {int maxLines = 1}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderSide: BorderSide.none),
      ),
    );
  }
}
