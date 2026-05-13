import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_style.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import 'image_viewer_screen.dart';
import 'public_user_profile_screen.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  int currentIndex = 0;

  Widget _buildRatingStars(double value, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        IconData icon;

        if (value >= starNumber) {
          icon = Icons.star_rounded;
        } else if (value >= starNumber - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }

        return Icon(
          icon,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  Widget _ratingSummary(Map<String, dynamic> summary) {
    final average = (summary['average'] as num?)?.toDouble() ?? 0;
    final count = (summary['count'] as num?)?.toInt() ?? 0;

    if (count == 0) {
      return const Text(
        'No ratings yet',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Row(
      children: [
        _buildRatingStars(average),
        const SizedBox(width: 6),
        Text(
          '${average.toStringAsFixed(1)} ($count)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppStyle.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _ratingReviews(Map<String, dynamic> summary) {
    final ratings = (summary['ratings'] as List?) ?? [];

    if (ratings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: ratings.take(3).map((rating) {
        final rater = rating['rater'] as Map<String, dynamic>?;
        final comment = rating['comment']?.toString() ?? '';
        final score = (rating['score'] as num?)?.toInt() ?? 0;
        final raterName = rater?['name']?.toString() ?? 'User';
        final raterImage = rater?['profileImage']?.toString();
        final raterId = rater?['_id']?.toString();

        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppStyle.primary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: raterId == null || raterId.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicUserProfileScreen(
                              userId: raterId,
                            ),
                          ),
                        );
                      },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppStyle.primary,
                      backgroundImage: (raterImage?.isNotEmpty == true)
                          ? NetworkImage(
                              '${ApiService.baseUrl}/uploads/$raterImage',
                            )
                          : null,
                      child: (raterImage?.isNotEmpty == true)
                          ? null
                          : Text(
                              raterName.isNotEmpty
                                  ? raterName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        raterName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppStyle.textPrimary,
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < score
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (comment.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: const TextStyle(
                    color: AppStyle.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final List images = item['images'] ?? [];
    final owner = item['user'];
    final ownerName = owner is Map ? owner['name']?.toString() : null;
    final ownerPhone = owner is Map ? owner['phone']?.toString() : null;
    final hasPhone = ownerPhone != null && ownerPhone.trim().isNotEmpty;
    final bool isAdoption = item['isAdoption'] == true;
    final availabilityStatus =
        (item['availabilityStatus'] ?? 'available').toString();
    final availabilityLabel = availabilityStatus == 'sold'
        ? 'Sold'
        : availabilityStatus == 'adopted'
            ? 'Adopted'
            : null;
    final isUnavailable = availabilityLabel != null;
    final String priceLabel = isAdoption
        ? 'For Adoption'
        : (item['price']?.toString().trim().isNotEmpty == true
            ? item['price'].toString()
            : 'Price not available');
    bool isFavorite = item['isFavorite'] == true;

    return Scaffold(
      backgroundColor: AppStyle.scaffold,

      
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppStyle.textPrimary),
        actions: [
          StatefulBuilder(
            builder: (context, setIconState) {
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : AppStyle.textPrimary,
                ),
                onPressed: () async {
                  final result = await ApiService.toggleFavorite(item['_id']);
                  if (result == null) return;
                  setIconState(() => isFavorite = result);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: AppStyle.textPrimary),
            onPressed: () => _showReportDialog(item),
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  itemCount: images.isNotEmpty ? images.length : 1,
                  onPageChanged: (i) {
                    setState(() => currentIndex = i);
                  },
                  itemBuilder: (context, index) {
                    if (images.isEmpty) {
                      return const Center(
                        child: Icon(Icons.image_not_supported, size: 80),
                      );
                    }

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
                      child: Hero(
                        tag: item['_id'],
                        child: Stack(
                          children: [
                            Image.network(
                              '${ApiService.baseUrl}/uploads/${images[index]}',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            if (availabilityLabel != null)
                              Positioned(
                                left: 16,
                                top: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    availabilityLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    child: Row(
                      children: List.generate(
                        images.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentIndex == index ? 12 : 8,
                          height: currentIndex == index ? 12 : 8,
                          decoration: BoxDecoration(
                            color: currentIndex == index
                                ? Colors.white
                                : Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppStyle.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),


                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: availabilityLabel != null
                          ? Colors.blueGrey.withOpacity(0.12)
                          : AppStyle.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      availabilityLabel ?? priceLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppStyle.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    item['description'],
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 20),

                  
                  if (item['category'] != 'food') ...[
                    _infoRow('Age', '${item['age'] ?? '—'} years'),
                    _infoRow(
                      'Vaccinated',
                      item['vaccinated'] == true ? 'Yes' : 'No',
                    ),
                    _infoRow('Health', item['healthStatus'] ?? '—'),
                    _infoRow('Location', item['location'] ?? '—'),
                  ],

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppStyle.primary.withOpacity(0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Owner',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppStyle.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: owner is Map && owner['_id'] != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PublicUserProfileScreen(
                                        userId: owner['_id'].toString(),
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            ownerName ?? 'Unknown owner',
                            style: const TextStyle(
                              color: AppStyle.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (owner is Map && owner['_id'] != null) ...[
                          const SizedBox(height: 6),
                          FutureBuilder<Map<String, dynamic>>(
                            future: ApiService.getUserRatings(
                              owner['_id'].toString(),
                            ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ratingSummary(snapshot.data!),
                                  _ratingReviews(snapshot.data!),
                                ],
                              );
                            },
                          ),
                        ],
                        if (hasPhone) ...[
                          const SizedBox(height: 4),
                          Text(
                            ownerPhone,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  FutureBuilder<String?>(
                    future: ApiService.getCurrentUserId(),
                    builder: (context, snapshot) {
                      final ownerId =
                          owner is Map ? owner['_id']?.toString() : null;
                      final isMyAd =
                          ownerId != null && ownerId == snapshot.data;

                      if (isMyAd || isUnavailable) {
                        return const SizedBox.shrink();
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppStyle.primary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () async {
                                final conversation =
                                    await ApiService.startConversation(
                                        item['_id']);

                                if (!mounted) return;

                                if (conversation == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cannot start chat'),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChatScreen(conversation: conversation),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat, color: Colors.white),
                              label: const Text(
                                'Chat',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          if (hasPhone) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () => _callOwner(item),
                                icon: const Icon(
                                  Icons.call,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Call',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callOwner(Map<String, dynamic> item) async {
    final owner = item['user'];
    final phone = owner is Map ? owner['phone']?.toString() : null;

    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final phoneUri = Uri(scheme: 'tel', path: phone.trim());

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot open phone app')),
    );
  }

  Future<void> _showReportDialog(Map<String, dynamic> item) async {
    String reasonText = '';
    String? selectedReason;
    const suggestions = [
      'Fake ad',
      'Wrong information',
      'Scam or spam',
      'Inappropriate content',
    ];

    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canSubmit = reasonText.isNotEmpty;

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 24,
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.report_problem_rounded,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Report this ad',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppStyle.textPrimary,
                              ),
                            ),
                            Text(
                              'Help us review "${item['name'] ?? 'this ad'}" faster.',
                              style: const TextStyle(
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions.map((entry) {
                      final isSelected = selectedReason == entry;
                      return ChoiceChip(
                        label: Text(entry),
                        selected: isSelected,
                        onSelected: (_) {
                          selectedReason = entry;
                          reasonText = entry;
                          setDialogState(() {});
                        },
                        selectedColor: AppStyle.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppStyle.primary
                              : Colors.grey.shade700,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppStyle.primary
                              : Colors.grey.shade300,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    autofocus: true,
                    minLines: 3,
                    maxLines: 5,
                    onChanged: (value) {
                      reasonText = value.trim();
                      if (selectedReason != null && reasonText != selectedReason) {
                        selectedReason = null;
                      }
                      setDialogState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Tell us what is wrong',
                      filled: true,
                      fillColor: const Color(0xfff5f7fb),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: !canSubmit
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  Navigator.pop(context, reasonText);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Submit Report'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (reason == null || reason.isEmpty) return;

    final success = await ApiService.reportAd(item['_id'], reason);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Report submitted' : 'Report failed'),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
