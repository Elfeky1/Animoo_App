import 'package:flutter/material.dart';

import '../core/theme/app_style.dart';
import '../services/api_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool isLoading = true;
  List favorites = [];

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    final data = await ApiService.getFavorites();

    if (!mounted) return;

    setState(() {
      favorites = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.scaffold,
      appBar: AppStyle.primaryAppBar(context, title: 'Favorites'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? const Center(
                  child: Text(
                    'No favorites yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchFavorites,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: favorites.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _favoriteTile(favorites[index]);
                    },
                  ),
                ),
    );
  }

  Widget _favoriteTile(Map ad) {
    final images = ad['images'] ?? [];

    return Container(
      decoration: AppStyle.cardDecoration(radius: 16),
      child: ListTile(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: images.isNotEmpty
              ? Image.network(
                  '${ApiService.baseUrl}/uploads/${images.first}',
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 58,
                  height: 58,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.pets),
                ),
        ),
        title: Text(
          ad['name'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppStyle.textPrimary,
          ),
        ),
        subtitle: Text(
          ad['isAdoption'] == true ? 'Adoption' : ad['price'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppStyle.textMuted),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () async {
            await ApiService.toggleFavorite(ad['_id']);
            fetchFavorites();
          },
        ),
        onTap: () {
          ad['isFavorite'] = true;
          Navigator.pushNamed(context, '/details', arguments: ad)
              .then((_) => fetchFavorites());
        },
      ),
    );
  }
}
