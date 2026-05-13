import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApprovedAdsScreen extends StatefulWidget {
  const ApprovedAdsScreen({super.key});

  @override
  State<ApprovedAdsScreen> createState() => _ApprovedAdsScreenState();
}

class _ApprovedAdsScreenState extends State<ApprovedAdsScreen> {
  bool isLoading = true;
  List ads = [];

  @override
  void initState() {
    super.initState();
    fetchAds();
  }

  Future<void> fetchAds() async {
    final data = await ApiService.getApprovedAds();
    if (!mounted) return;
    setState(() {
      ads = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approved Ads'),
        backgroundColor: const Color(0xff24394a),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ads.isEmpty
              ? const Center(child: Text('No approved ads'))
              : ListView.builder(
                  itemCount: ads.length,
                  itemBuilder: (_, i) {
                    final ad = ads[i];
                    final images = ad['images'] ?? [];
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: images.isNotEmpty
                            ? Image.network(
                                '${ApiService.baseUrl}/uploads/${images.first}',
                                width: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image),
                        title: Text(ad['name']),
                        subtitle: const Text(
                          'APPROVED',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
