import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_style.dart';
import '../services/api_service.dart';
import 'chat_list_screen.dart';
import 'favorites_screen.dart';
import 'edit_profile_screen.dart';
import 'my_ads_screen.dart';
import 'my_pets_screen.dart';
import 'notifications_screen.dart';
import 'public_user_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String? name;
  String? email;
  String? phone;
  String? role;
  String? profileImage;
  String? currentUserId;
  double ratingAverage = 0;
  int ratingCount = 0;

  bool get isAdmin => role == 'admin';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

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

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await ApiService.getProfile();

    if (!mounted) return;

    setState(() {
      currentUserId = profile?['_id'] ?? prefs.getString('userId');
      name = profile?['name'] ?? prefs.getString('name') ?? 'Animoo User';
      email = profile?['email'] ?? prefs.getString('email') ?? '';
      phone = profile?['phone'] ?? prefs.getString('phone') ?? '';
      role = profile?['role'] ?? prefs.getString('role') ?? 'user';
      profileImage = profile?['profileImage'] ?? prefs.getString('profileImage');
      isLoading = false;
    });

    final ratingSummary = await ApiService.getMyRatingSummary();
    if (!mounted) return;

    setState(() {
      ratingAverage = (ratingSummary['average'] as num?)?.toDouble() ?? 0;
      ratingCount = (ratingSummary['count'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await ApiService.clearLocalSession();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> deleteAccount() async {
    String confirmText = '';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete your account, ads, chats, pets, and related data. This action cannot be undone.',
              ),
              const SizedBox(height: 14),
              const Text(
                'Type DELETE to confirm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppStyle.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                onChanged: (value) {
                  confirmText = value.trim();
                  setDialogState(() {});
                },
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: confirmText == 'DELETE'
                  ? () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context, true);
                    }
                  : null,
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete != true) return;

    final success = await ApiService.deleteAccount();

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account')),
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppStyle.scaffold,
      appBar: AppStyle.primaryAppBar(context, title: 'Profile'),
      body: RefreshIndicator(
        onRefresh: loadUserData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _profileHeader(),
            const SizedBox(height: 18),
            _quickStats(),
            const SizedBox(height: 18),
            _menuItem(
              icon: Icons.edit_outlined,
              text: 'Edit Profile',
              subtitle: 'Update your name and phone',
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      initialName: name ?? '',
                      initialEmail: email ?? '',
                      initialPhone: phone ?? '',
                      initialProfileImage: profileImage,
                    ),
                  ),
                );

                if (updated == true) {
                  loadUserData();
                }
              },
            ),
            if (isAdmin)
              _menuItem(
                icon: Icons.admin_panel_settings,
                text: 'Admin Dashboard',
                subtitle: 'Review users and ads',
                color: Colors.deepPurple,
                onTap: () => Navigator.pushNamed(context, '/admin'),
              ),
            _menuItem(
              icon: Icons.list_alt,
              text: 'My Ads',
              subtitle: 'Manage your posts',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyAdsScreen()),
                );
              },
            ),
            _menuItem(
              icon: Icons.pets,
              text: 'My Pets',
              subtitle: 'Care profiles and reminders',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyPetsScreen()),
                );
              },
            ),
            _menuItem(
              icon: Icons.favorite,
              text: 'Favorites',
              subtitle: 'Saved ads',
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
              },
            ),
            _menuItem(
              icon: Icons.chat_bubble_outline,
              text: 'Chats',
              subtitle: 'Your conversations',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              },
            ),
            _menuItem(
              icon: Icons.notifications_none,
              text: 'Notifications',
              subtitle: 'Messages and updates',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            _menuItem(
              icon: Icons.logout,
              text: 'Logout',
              subtitle: 'Leave this account',
              color: Colors.red,
              onTap: logout,
            ),
            _menuItem(
              icon: Icons.delete_forever_outlined,
              text: 'Delete Account',
              subtitle: 'Permanently remove your account',
              color: Colors.red,
              onTap: deleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader() {
    final initial = (name?.isNotEmpty == true ? name![0] : 'A').toUpperCase();
    final hasProfileImage = profileImage?.isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyle.cardDecoration(radius: 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppStyle.primary,
            backgroundImage: hasProfileImage
                ? NetworkImage('${ApiService.baseUrl}/uploads/$profileImage')
                : null,
            child: hasProfileImage
                ? null
                : Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Animoo User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppStyle.textPrimary,
                  ),
                ),
                if (email?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                if (phone?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: currentUserId == null || currentUserId!.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PublicUserProfileScreen(
                                userId: currentUserId!,
                              ),
                            ),
                          );
                        },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRatingStars(ratingAverage, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        ratingCount > 0
                            ? '${ratingAverage.toStringAsFixed(1)} ($ratingCount ratings)'
                            : 'No ratings yet',
                        style: const TextStyle(
                          color: AppStyle.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    initialName: name ?? '',
                    initialEmail: email ?? '',
                    initialPhone: phone ?? '',
                    initialProfileImage: profileImage,
                  ),
                ),
              );

              if (updated == true) {
                loadUserData();
              }
            },
            icon: const Icon(
              Icons.edit_outlined,
              color: AppStyle.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickStats() {
    return Row(
      children: [
        Expanded(
          child: _infoPill(
            icon: isAdmin ? Icons.verified_user : Icons.person,
            title: isAdmin ? 'Admin' : 'User',
            subtitle: 'Account type',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _infoPill(
            icon: Icons.pets,
            title: 'Animoo',
            subtitle: 'Community',
          ),
        ),
      ],
    );
  }

  Widget _infoPill({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppStyle.primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppStyle.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppStyle.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppStyle.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String text,
    required String subtitle,
    required VoidCallback onTap,
    Color color = AppStyle.primary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: color),
        title: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppStyle.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppStyle.textMuted),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
