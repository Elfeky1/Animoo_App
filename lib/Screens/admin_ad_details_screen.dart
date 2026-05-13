import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'image_viewer_screen.dart';

class AdminAdDetailsScreen extends StatelessWidget {
  const AdminAdDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ad = ModalRoute.of(context)!.settings.arguments as Map;
    final images = ad['images'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ad Details'),
        backgroundColor: const Color(0xff24394a),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 280,
            child: PageView.builder(
              itemCount: images.length,
              itemBuilder: (_, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageViewerScreen(
                          images: images,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: const Color(0xfff3f5f8),
                    child: Image.network(
                      '${ApiService.baseUrl}/uploads/${images[index]}',
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  ad['description'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _infoRow('Category', ad['category']),
                _infoRow('Price', ad['price']),
                _infoRow('Location', ad['location']),
                _infoRow('Age', ad['age']?.toString()),
                _infoRow('Vaccinated', ad['vaccinated'] == true ? 'Yes' : 'No'),
                const SizedBox(height: 20),
                if (ad['idCardImage'] != null) ...[
                  const Text(
                    'ID Card',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewerScreen(
                            images: [ad['idCardImage']],
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: const Color(0xfff3f5f8),
                        child: Image.network(
                          '${ApiService.baseUrl}/uploads/${ad['idCardImage']}',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          await ApiService.approveAd(ad['_id']);
                          Navigator.pop(context, true);
                        },
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          await ApiService.rejectAd(ad['_id']);
                          Navigator.pop(context, true);
                        },
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
