import 'package:flutter/material.dart';
import '../core/theme/app_style.dart';
import '../services/api_service.dart';
import 'EditAdScreen.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  bool isLoading = true;
  List ads = [];

  @override
  void initState() {
    super.initState();
    fetchMyAds();
  }

  Future<void> fetchMyAds() async {
    setState(() => isLoading = true);

    final data = await ApiService.getMyAds();

    if (!mounted) return;

    setState(() {
      ads = data;
      isLoading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'PENDING REVIEW';
    }
  }

  String _availabilityLabel(Map ad) {
    final availability = (ad['availabilityStatus'] ?? 'available').toString();
    if (availability == 'sold') return 'SOLD';
    if (availability == 'adopted') return 'ADOPTED';
    return ad['isAdoption'] == true ? 'AVAILABLE FOR ADOPTION' : 'AVAILABLE';
  }

  bool _isLocked(Map ad) {
    final status = (ad['status'] ?? 'pending').toString();
    final availability = (ad['availabilityStatus'] ?? 'available').toString();
    return status != 'pending' || availability != 'available';
  }

  Color _availabilityColor(Map ad) {
    final availability = (ad['availabilityStatus'] ?? 'available').toString();
    if (availability == 'sold' || availability == 'adopted') {
      return Colors.blueGrey;
    }
    return ad['isAdoption'] == true ? Colors.teal : AppStyle.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.scaffold,
      appBar: AppStyle.primaryAppBar(context, title: 'My Ads'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ads.isEmpty
              ? const Center(
                  child: Text(
                    'You have no ads yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchMyAds,
                  child: ListView.builder(
                    itemCount: ads.length,
                    itemBuilder: (context, index) {
                      final ad = ads[index];
                      final List images = ad['images'] ?? [];
                      final status = ad['status'] ?? 'pending';

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: AppStyle.cardDecoration(radius: 18).copyWith(
                          border: Border.all(color: AppStyle.surfaceTint),
                        ),
                        child: Stack(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: images.isNotEmpty
                                      ? Container(
                                          width: 84,
                                          height: 84,
                                          color: const Color(0xfff3f5f8),
                                          child: Image.network(
                                            '${ApiService.baseUrl}/uploads/${images.first}',
                                            width: 84,
                                            height: 84,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : Container(
                                          width: 84,
                                          height: 84,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.image_not_supported),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ad['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppStyle.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ad['description'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        ad['isAdoption'] == true
                                            ? 'For adoption'
                                            : 'For sale ${ad['price'] ?? ''}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppStyle.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          _badge(
                                            _statusText(status),
                                            _statusColor(status),
                                          ),
                                          _badge(
                                            _availabilityLabel(ad),
                                            _availabilityColor(ad),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock_outline,
                                                size: 16,
                                                color: _isLocked(ad)
                                                    ? Colors.grey
                                                    : Colors.green,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _isLocked(ad) ? 'Locked' : 'Open',
                                                style: TextStyle(
                                                  color: _isLocked(ad)
                                                      ? Colors.grey
                                                      : Colors.green,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (status == 'pending')
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: AppStyle.textPrimary,
                                              ),
                                              onPressed: () async {
                                                final updated =
                                                    await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const EditAdScreen(),
                                                    settings: RouteSettings(
                                                      arguments: ad,
                                                    ),
                                                  ),
                                                );

                                                if (updated == true) {
                                                  fetchMyAds();
                                                }
                                              },
                                            ),
                                          if (status == 'approved' &&
                                              (ad['availabilityStatus'] ??
                                                          'available')
                                                      .toString() ==
                                                  'available')
                                            IconButton(
                                              icon: Icon(
                                                ad['isAdoption'] == true
                                                    ? Icons.volunteer_activism_outlined
                                                    : Icons.sell_outlined,
                                                color: Colors.blueGrey,
                                              ),
                                              onPressed: () async {
                                                final label = ad['isAdoption'] == true
                                                    ? 'Mark as Adopted'
                                                    : 'Mark as Sold';
                                                final nextStatus =
                                                    ad['isAdoption'] == true
                                                        ? 'adopted'
                                                        : 'sold';

                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    title: Text(label),
                                                    content: Text(
                                                      ad['isAdoption'] == true
                                                          ? 'Do you want to mark this ad as adopted?'
                                                          : 'Do you want to mark this ad as sold?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                        child: Text(label),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirm == true) {
                                                  final success = await ApiService
                                                      .markAdUnavailable(
                                                    ad['_id'],
                                                    nextStatus,
                                                  );
                                                  if (success) {
                                                    fetchMyAds();
                                                  }
                                                }
                                              },
                                            ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            onPressed: () async {
                                              final confirm = await showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text('Delete Ad'),
                                                  content: const Text(
                                                    'Are you sure you want to delete this ad?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                final success =
                                                    await ApiService.deleteAd(
                                                  ad['_id'],
                                                );
                                                if (success) {
                                                  fetchMyAds();
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if ((ad['availabilityStatus'] ?? 'available')
                                    .toString() !=
                                'available')
                              Positioned(
                                top: 8,
                                right: -30,
                                child: Transform.rotate(
                                  angle: 0.95,
                                  child: Container(
                                    width: 120,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    color: _availabilityColor(ad),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _availabilityLabel(ad),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
