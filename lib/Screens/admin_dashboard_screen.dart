import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/theme/app_style.dart';
import '../services/api_service.dart';
import 'admin_ad_details_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool isLoading = true;
  bool usersLoading = true;
  bool reportsLoading = true;

  List pendingAds = [];
  List approvedAds = [];
  List users = [];
  List adReports = [];
  List userReports = [];
  Map stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    fetchDashboard();
    fetchUsers();
    fetchReports();
  }

  Future<void> fetchDashboard() async {
    setState(() => isLoading = true);

    final pending = await ApiService.getPendingAds();
    final approved = await ApiService.getApprovedAds();
    final s = await ApiService.getAdStats();

    if (!mounted) return;

    setState(() {
      pendingAds = pending is List ? pending : [];
      approvedAds = approved is List ? approved : [];
      stats = s is Map ? s : {};
      isLoading = false;
    });
  }

  Future<void> fetchUsers() async {
    usersLoading = true;
    final data = await ApiService.getUsers();

    if (!mounted) return;

    setState(() {
      users = data is List ? data : [];
      usersLoading = false;
    });
  }

  Future<void> fetchReports() async {
    reportsLoading = true;
    final data = await ApiService.getAdminReports();

    if (!mounted) return;

    setState(() {
      final safeData = data is Map ? data : {};
      adReports = (safeData['adReports'] as List?) ?? [];
      userReports = (safeData['userReports'] as List?) ?? [];
      reportsLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.scaffold,
      appBar: AppBar(
        backgroundColor: AppStyle.primary,
        elevation: 0,
        toolbarHeight: 74,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Reports'),
            Tab(text: 'Stats'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _pendingTab(),
                _approvedTab(),
                _reportsTab(),
                _statsTab(),
                _usersTab(),
              ],
            ),
    );
  }

  Widget _pendingTab() {
    return pendingAds.isEmpty
        ? const Center(child: Text('No pending ads 🎉'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingAds.length,
            itemBuilder: (context, index) {
              return _adCard(pendingAds[index]);
            },
          );
  }

  Widget _approvedTab() {
    return approvedAds.isEmpty
        ? const Center(child: Text('No approved ads'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvedAds.length,
            itemBuilder: (context, index) {
              return _adCard(approvedAds[index], clickable: true);
            },
          );
  }

  Widget _reportsTab() {
    if (reportsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalReports = adReports.length + userReports.length;
    if (totalReports == 0) {
      return const Center(child: Text('No reports right now'));
    }

    return RefreshIndicator(
      onRefresh: fetchReports,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (adReports.isNotEmpty) ...[
            Text(
              'Ad Reports',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppStyle.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...adReports.map((report) => _adReportCard(report)),
            const SizedBox(height: 20),
          ],
          if (userReports.isNotEmpty) ...[
            Text(
              'User Reports',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppStyle.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...userReports.map((report) => _userReportCard(report)),
          ],
        ],
      ),
    );
  }

  Widget _statsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppStyle.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statCard(
                title: 'Pending',
                value: stats['pending']?.toString() ?? '0',
                color: Colors.orange,
                icon: Icons.pending_actions,
              ),
              const SizedBox(width: 12),
              _statCard(
                title: 'Approved',
                value: stats['approved']?.toString() ?? '0',
                color: Colors.green,
                icon: Icons.check_circle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                title: 'Rejected',
                value: stats['rejected']?.toString() ?? '0',
                color: Colors.red,
                icon: Icons.cancel,
              ),
              const SizedBox(width: 12),
              _statCard(
                title: 'Total Ads',
                value: stats['total']?.toString() ?? '0',
                color: Colors.blue,
                icon: Icons.all_inbox,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            'Ads Distribution',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _adsPieChart(),
        ],
      ),
    );
  }

  Widget _usersTab() {
    if (usersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: fetchUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final isBanned = user['isBanned'] == true;
          final role = (user['role'] ?? 'user').toString();
          final userName = (user['name'] ?? 'User').toString().trim();
          final userEmail = (user['email'] ?? 'No email').toString().trim();
          final initial = userName.isNotEmpty
              ? userName[0].toUpperCase()
              : 'U';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    isBanned ? Colors.red : const Color(0xff24394a),
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                userName.isNotEmpty ? userName : 'Unknown user',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userEmail.isNotEmpty ? userEmail : 'No email'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip(
                        role.toUpperCase(),
                        role == 'admin' ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      _chip(
                        isBanned ? 'BANNED' : 'ACTIVE',
                        isBanned ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'ban') {
                    await ApiService.toggleBan(user['_id']);
                  } else if (value == 'role') {
                    final newRole = role == 'admin' ? 'user' : 'admin';
                    await ApiService.changeRole(user['_id'], newRole);
                  }
                  fetchUsers();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'ban',
                    child: Text(isBanned ? 'Unban' : 'Ban'),
                  ),
                  const PopupMenuItem(
                    value: 'role',
                    child: Text('Change Role'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _adCard(Map ad, {bool clickable = true}) {
    final images = ad['images'] ?? [];

    return GestureDetector(
      onTap: clickable
          ? () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminAdDetailsScreen(),
                  settings: RouteSettings(arguments: ad),
                ),
              );
              if (updated == true) fetchDashboard();
            }
          : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: const Color(0xfff3f5f8),
                  child: Image.network(
                    '${ApiService.baseUrl}/uploads/${images.first}',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ad['description'] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(
                        (ad['status'] ?? 'pending').toString().toUpperCase(),
                        _statusColor((ad['status'] ?? 'pending').toString()),
                      ),
                      if ((ad['idCardImage'] ?? '').toString().isNotEmpty)
                        _chip('ID CARD', Colors.deepPurple),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adReportCard(Map report) {
    final ad = report['ad'];
    final reporter = report['reporter'];
    final adOwner = ad?['user'];
    final adName = ad?['name']?.toString() ?? 'Removed ad';
    final reporterName = reporter?['name']?.toString() ?? 'Unknown user';
    final reporterEmail = reporter?['email']?.toString() ?? '';
    final targetName = adOwner?['name']?.toString() ?? 'Unknown owner';
    final targetPhone = adOwner?['phone']?.toString() ?? '';
    final targetEmail = adOwner?['email']?.toString() ?? '';
    final reason = report['reason']?.toString() ?? '';
    final createdAt = report['createdAt']?.toString() ?? '';
    final image = (ad?['images'] as List?)?.isNotEmpty == true
        ? ad['images'].first.toString()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.report_gmailerrorred_rounded,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ad report',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _chip(
                  (report['status'] ?? 'open').toString().toUpperCase(),
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: const Color(0xfff4f6f8),
                  child: Image.network(
                    '${ApiService.baseUrl}/uploads/$image',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (image != null) const SizedBox(height: 12),
            _reportSectionLabel('Advertisement'),
            const SizedBox(height: 6),
            _reportInfoTile(
              icon: Icons.pets_rounded,
              title: adName,
              subtitle:
                  'Owner: $targetName${targetPhone.isNotEmpty ? ' - $targetPhone' : ''}',
            ),
            const SizedBox(height: 8),
            _reportSectionLabel('Reported by'),
            const SizedBox(height: 6),
            _reportInfoTile(
              icon: Icons.person_rounded,
              title: reporterName,
              subtitle: reporterEmail.isNotEmpty ? reporterEmail : 'No email',
            ),
            const SizedBox(height: 10),
            _reportSectionLabel('Reported user'),
            const SizedBox(height: 6),
            _reportInfoTile(
              icon: Icons.shield_outlined,
              title: targetName,
              subtitle: [
                if (targetEmail.isNotEmpty) targetEmail,
                if (targetPhone.isNotEmpty) targetPhone,
              ].join(' - ').isEmpty
                  ? 'No contact details'
                  : [
                      if (targetEmail.isNotEmpty) targetEmail,
                      if (targetPhone.isNotEmpty) targetPhone,
                    ].join(' - '),
            ),
            const SizedBox(height: 10),
            _reportSectionLabel('Reason'),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfff8fafc),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                reason,
                style: const TextStyle(color: Color(0xff24394a), height: 1.4),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _formatDate(createdAt),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            if (ad != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminAdDetailsScreen(),
                          settings: RouteSettings(arguments: ad),
                        ),
                      );
                    },
                    child: const Text('Open Ad'),
                  ),
                  if ((report['status'] ?? 'open').toString() != 'reviewed')
                    TextButton(
                      onPressed: () async {
                        final success = await ApiService.reviewAdReport(
                          report['_id'],
                        );
                        if (!mounted) return;
                        if (success) {
                          fetchReports();
                        }
                      },
                      child: const Text('Mark Reviewed'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _userReportCard(Map report) {
    final reportedUser = report['reportedUser'];
    final reporter = report['reporter'];
    final ad = report['ad'];
    final reason = report['reason']?.toString() ?? '';
    final targetName = reportedUser?['name']?.toString() ?? 'Unknown user';
    final reporterName = reporter?['name']?.toString() ?? 'Unknown user';
    final reporterEmail = reporter?['email']?.toString() ?? '';
    final targetEmail = reportedUser?['email']?.toString() ?? '';
    final targetPhone = reportedUser?['phone']?.toString() ?? '';
    final adName = ad?['name']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'User report',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _chip(
                  (report['status'] ?? 'open').toString().toUpperCase(),
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _reportSectionLabel('Reported by'),
            const SizedBox(height: 6),
            _reportInfoTile(
              icon: Icons.person_outline_rounded,
              title: reporterName,
              subtitle: reporterEmail.isNotEmpty ? reporterEmail : 'No email',
            ),
            const SizedBox(height: 10),
            _reportSectionLabel('Reported user'),
            const SizedBox(height: 6),
            _reportInfoTile(
              icon: Icons.gpp_bad_rounded,
              title: targetName,
              subtitle: [
                if (targetEmail.isNotEmpty) targetEmail,
                if (targetPhone.isNotEmpty) targetPhone,
              ].join(' - ').isEmpty
                  ? 'No contact details'
                  : [
                      if (targetEmail.isNotEmpty) targetEmail,
                      if (targetPhone.isNotEmpty) targetPhone,
                    ].join(' - '),
            ),
            const SizedBox(height: 8),
            if (adName.isNotEmpty) ...[
              _reportSectionLabel('Related ad'),
              const SizedBox(height: 6),
              _reportInfoTile(
                icon: Icons.inventory_2_outlined,
                title: adName,
                subtitle: 'Linked from conversation/ad report context',
              ),
              const SizedBox(height: 10),
            ],
            _reportSectionLabel('Reason'),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfff8fafc),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                reason,
                style: const TextStyle(color: Color(0xff24394a), height: 1.4),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _formatDate(report['createdAt']?.toString() ?? ''),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if ((report['status'] ?? 'open').toString() != 'reviewed')
                  TextButton(
                    onPressed: () async {
                      final success = await ApiService.reviewUserReport(
                        report['_id'],
                      );
                      if (!mounted) return;
                      if (success) {
                        fetchReports();
                      }
                    },
                    child: const Text('Mark Reviewed'),
                  ),
                TextButton(
                  onPressed: () async {
                    final userId = reportedUser?['_id']?.toString();
                    if (userId == null || userId.isEmpty) return;
                    final success = await ApiService.toggleBan(userId);
                    if (!mounted) return;
                    if (success) {
                      fetchReports();
                      fetchUsers();
                    }
                  },
                  child: Text(
                    reportedUser?['isBanned'] == true ? 'Unban User' : 'Ban User',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _reportInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xff24394a), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xff24394a),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _adsPieChart() {
    final pending = (stats['pending'] ?? 0).toDouble();
    final approved = (stats['approved'] ?? 0).toDouble();
    final rejected = (stats['rejected'] ?? 0).toDouble();

    if (pending + approved + rejected == 0) {
      return const Center(child: Text('No data available'));
    }

    return SizedBox(
      height: 260,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 50,
          sectionsSpace: 4,
          sections: [
            PieChartSectionData(
              value: approved,
              title: 'Approved',
              color: Colors.green,
              radius: 60,
              titleStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              value: pending,
              title: 'Pending',
              color: Colors.orange,
              radius: 60,
              titleStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              value: rejected,
              title: 'Rejected',
              color: Colors.red,
              radius: 60,
              titleStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
