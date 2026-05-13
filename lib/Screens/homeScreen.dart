import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'chat_list_screen.dart';
import 'chatbot_screen.dart';
import 'favorites_screen.dart';
import 'my_ads_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen_new.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primaryColor = Color(0xff173b67);
  static const Color _accentColor = Color(0xff8ea8cb);
  static const Color _surfaceTint = Color(0xffedf3fa);

  int currentIndex = 0;
  String selectedCategory = 'dogs';
  String selectedAdType = 'all';
  final TextEditingController searchController = TextEditingController();
  Timer? searchDebounce;
  int adsRequestId = 0;

  bool isLoading = false;
  List ads = [];
  int notificationCount = 0;
  int chatUnreadCount = 0;
  String currentUserName = 'Animoo';
  String? profileImage;

  @override
  void initState() {
    super.initState();
    fetchAds();
    setupNotifications();
    fetchChatUnreadCount();
    loadCurrentUser();
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    SocketService.removeNotificationListener();
    searchController.dispose();
    super.dispose();
  }

  Future<void> setupNotifications() async {
    SocketService.joinCurrentUser();
    SocketService.onNotification((_) {
      if (!mounted) return;
      setState(() => notificationCount++);
    });

    final data = await ApiService.getNotifications();
    if (!mounted) return;

    setState(() {
      notificationCount = data.where((item) => item['isRead'] == false).length;
    });
  }

  Future<void> loadCurrentUser() async {
    final profile = await ApiService.getProfile();
    final fallbackName = await ApiService.getCurrentUserName();
    final fallbackImage = await ApiService.getCurrentUserProfileImage();
    if (!mounted) return;

    setState(() {
      currentUserName =
          (profile?['name'] ?? fallbackName ?? 'Animoo').toString();
      profileImage = (profile?['profileImage'] ?? fallbackImage)?.toString();
    });
  }

  Future<void> fetchChatUnreadCount() async {
    final conversations = await ApiService.getConversations();
    if (!mounted) return;

    setState(() {
      chatUnreadCount = conversations.fold<int>(
        0,
        (sum, item) => sum + ((item['unreadCount'] ?? 0) as int),
      );
    });
  }

  Future<void> fetchAds() async {
    final requestId = ++adsRequestId;

    setState(() => isLoading = true);

    final data = await ApiService.getAnimals(
      selectedCategory,
      searchController.text.trim(),
      selectedAdType,
    );

    if (!mounted || requestId != adsRequestId) return;

    setState(() {
      ads = data;
      isLoading = false;
    });
  }

  void onSearchChanged(String value) {
    searchDebounce?.cancel();
    searchDebounce = Timer(const Duration(milliseconds: 350), fetchAds);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        titleSpacing: 10,
        toolbarHeight: 78,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/home_logo.jpg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _brandTitle(),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                  if (!mounted) return;
                  setupNotifications();
                },
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      notificationCount > 9
                          ? '9+'
                          : notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                if (!mounted) return;
                loadCurrentUser();
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: profileImage?.isNotEmpty == true
                    ? NetworkImage(
                        '${ApiService.baseUrl}/uploads/$profileImage')
                    : null,
                child: profileImage?.isNotEmpty == true
                    ? null
                    : Text(
                        currentUserName.isNotEmpty
                            ? currentUserName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadCurrentUser();
          await setupNotifications();
          await fetchChatUnreadCount();
          await fetchAds();
        },
        color: _primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroCard(),
              const SizedBox(height: 12),
              _searchBar(),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tabItem('Dogs', 'dogs'),
                    const SizedBox(width: 12),
                    _tabItem('Cats', 'cats'),
                    const SizedBox(width: 12),
                    _tabItem('Food', 'food'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _typeChip('All', 'all'),
                    if (selectedCategory != 'food') ...[
                      const SizedBox(width: 8),
                      _typeChip('Adoption', 'adoption'),
                      const SizedBox(width: 8),
                      _typeChip('Sale', 'sale'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionHeader(),
              const SizedBox(height: 12),
              Builder(
                builder: (_) {
                  if (isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (ads.isEmpty) {
                    return _emptyState();
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ads.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.69,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      return _adCard(ads[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bottomNavItem(
                index: 0,
                label: 'Home',
                icon: Icons.home_rounded,
                onTap: () => _handleNavigationTap(0),
              ),
              _bottomNavItem(
                index: 1,
                label: 'Chat',
                icon: Icons.chat_bubble_rounded,
                badgeCount: chatUnreadCount,
                onTap: () => _handleNavigationTap(1),
              ),
              _centerAddButton(),
              _bottomNavItem(
                index: 3,
                label: 'My Ads',
                icon: Icons.list_alt_rounded,
                onTap: () => _handleNavigationTap(3),
              ),
              _bottomNavItem(
                index: 4,
                label: 'Profile',
                icon: Icons.person_rounded,
                onTap: () => _handleNavigationTap(4),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: _primaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
        child: const Icon(
          Icons.smart_toy_outlined,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _handleNavigationTap(int i) async {
    if (i == 2) {
      setState(() => currentIndex = 2);
      Navigator.pushNamed(context, '/add');
      return;
    }

    if (i == 1) {
      setState(() => currentIndex = 1);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
      );
      if (!mounted) return;
      fetchChatUnreadCount();
      setState(() => currentIndex = 0);
      return;
    }

    if (i == 3) {
      setState(() => currentIndex = 3);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyAdsScreen()),
      );
      return;
    }

    if (i == 4) {
      setState(() => currentIndex = 4);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      if (!mounted) return;
      loadCurrentUser();
      setState(() => currentIndex = 0);
      return;
    }

    setState(() => currentIndex = i);
  }

  Widget _heroCard() {
    final firstName = currentUserName.trim().split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color(0xff204d84)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/home_logo.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $firstName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find pets, care, and trusted listings in one place.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pets_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(height: 4),
                Text(
                  'Pet Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'An',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 13,
                height: 13,
                alignment: Alignment.center,
                child: Transform.rotate(
                  angle: 0,
                  child: const Icon(
                    Icons.pets_rounded,
                    color: Colors.white,
                    size: 9,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        const Text(
          'moo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        const Text(
          'Latest for you',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _primaryColor,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _surfaceTint),
          ),
          child: Text(
            '${ads.length} items',
            style: const TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabItem(String text, String category) {
    final isActive = selectedCategory == category;

    return GestureDetector(
      onTap: () {
        if (selectedCategory == category) return;

        setState(() {
          selectedCategory = category;
        });

        fetchAds();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : _primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String text, String type) {
    final isActive = selectedAdType == type;

    return ChoiceChip(
      label: Text(text),
      selected: isActive,
      selectedColor: _accentColor,
      labelStyle: TextStyle(
        color: isActive ? _primaryColor : _primaryColor,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isActive ? _accentColor : Colors.transparent,
      ),
      onSelected: (_) {
        if (selectedAdType == type) return;

        setState(() {
          selectedAdType = type;
        });

        fetchAds();
      },
    );
  }

  Widget _adCard(Map item) {
    final List images = item['images'] ?? [];
    final availabilityStatus =
        (item['availabilityStatus'] ?? 'available').toString();
    final priceLabel = item['isAdoption'] == true
        ? 'For Adoption'
        : (item['price']?.toString().isNotEmpty == true
            ? item['price'].toString()
            : '-');
    final categoryLabel = selectedCategory == 'food'
        ? 'Food'
        : (item['isAdoption'] == true ? 'Adoption' : 'Sale');
    final availabilityLabel = availabilityStatus == 'sold'
        ? 'SOLD'
        : availabilityStatus == 'adopted'
            ? 'ADOPTED'
            : null;
    final location = item['location']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/details', arguments: item);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: images.isNotEmpty
                  ? Stack(
                      children: [
                        Container(
                          height: 120,
                          width: double.infinity,
                          color: _surfaceTint,
                          child: Image.network(
                            '${ApiService.baseUrl}/uploads/${images.first}',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  categoryLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (availabilityLabel != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accentColor.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    availabilityLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (availabilityLabel != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      height: 126,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    priceLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: _primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search by name, age, place or details',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                searchController.clear();
                searchDebounce?.cancel();
                fetchAds();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final hasSearch = searchController.text.trim().isNotEmpty;

    if (hasSearch) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: _primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 10),
            const Text(
              'No search results',
              style: TextStyle(
                color: _primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try another keyword or clear the search to explore more listings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      );
    }

    final title = switch (selectedCategory) {
      'dogs' => 'No dogs yet',
      'cats' => 'No cats yet',
      'food' => 'No food yet',
      _ => 'No pets yet',
    };

    final subtitle = switch (selectedCategory) {
      'dogs' => 'Add the first lovely dog listing for the community.',
      'cats' => 'Be the first to share a cute cat listing here.',
      'food' => 'Add food and supplies so pet owners can find them easily.',
      _ => 'Be the first to add something new.',
    };

    final emptyImage = switch (selectedCategory) {
      'dogs' => 'assets/images/dog1.png',
      'cats' => 'assets/images/cat1.png',
      'food' => 'assets/images/dog2.png',
      _ => 'assets/images/dog1.png',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  emptyImage,
                  height: 190,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerAddButton() {
    final isSelected = currentIndex == 2;

    return Container(
      width: isSelected ? 56 : 52,
      height: isSelected ? 56 : 52,
      decoration: BoxDecoration(
        color: _primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => _handleNavigationTap(2),
        icon: const Icon(
          Icons.add_rounded,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required int index,
    required String label,
    required IconData icon,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _surfaceTint : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? _primaryColor : Colors.grey.shade500,
                    size: 23,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -1,
                    top: -2,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _primaryColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
