import 'package:flutter/material.dart';

import '../core/theme/app_style.dart';
import '../services/api_service.dart';

class PublicUserProfileScreen extends StatefulWidget {
  final String userId;

  const PublicUserProfileScreen({super.key, required this.userId});

  @override
  State<PublicUserProfileScreen> createState() => _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  bool isLoading = true;
  Map<String, dynamic>? profile;
  Map<String, dynamic> ratingSummary = const {
    'average': 0.0,
    'count': 0,
    'ratings': [],
  };

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final publicProfile = await ApiService.getPublicUserProfile(widget.userId);
    final ratings = await ApiService.getUserRatings(widget.userId);

    if (!mounted) return;

    setState(() {
      profile = publicProfile;
      ratingSummary = ratings;
      isLoading = false;
    });
  }

  Widget _buildRatingStars(double value, {double size = 18}) {
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }

    final name = profile?['name']?.toString() ?? 'User';
    final phone = profile?['phone']?.toString() ?? '';
    final image = profile?['profileImage']?.toString();
    final average = (ratingSummary['average'] as num?)?.toDouble() ?? 0;
    final count = (ratingSummary['count'] as num?)?.toInt() ?? 0;
    final ratings = (ratingSummary['ratings'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppStyle.scaffold,
      appBar: AppStyle.primaryAppBar(context, title: 'User Profile'),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppStyle.cardDecoration(radius: 18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppStyle.primary,
                    backgroundImage: (image?.isNotEmpty == true)
                        ? NetworkImage('${ApiService.baseUrl}/uploads/$image')
                        : null,
                    child: (image?.isNotEmpty == true)
                        ? null
                        : Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppStyle.textPrimary,
                          ),
                        ),
                        if (phone.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            phone,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildRatingStars(average),
                            const SizedBox(width: 6),
                            Text(
                              count > 0
                                  ? '${average.toStringAsFixed(1)} ($count ratings)'
                                  : 'No ratings yet',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppStyle.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppStyle.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (ratings.isEmpty)
              const Text(
                'No reviews yet',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...ratings.map((rating) {
                final rater = rating['rater'] as Map<String, dynamic>?;
                final ad = rating['ad'] as Map<String, dynamic>?;
                final comment = rating['comment']?.toString() ?? '';
                final score = (rating['score'] as num?)?.toInt() ?? 0;
                final raterImage = rater?['profileImage']?.toString();
                final raterName = rater?['name']?.toString() ?? 'User';
                final raterId = rater?['_id']?.toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: AppStyle.cardDecoration(radius: 16),
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
                              radius: 18,
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
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                            ),
                            const SizedBox(width: 10),
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
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ad?['name'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'About ${ad!['name']}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
              }),
          ],
        ),
      ),
    );
  }
}
