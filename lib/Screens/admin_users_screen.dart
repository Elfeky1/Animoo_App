import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final data = await ApiService.getUsers();
    setState(() {
      users = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, i) {
        final u = users[i];
        return Card(
          child: ListTile(
            title: Text(u['name']),
            subtitle: Text('${u['email']} • ${u['role']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    u['isBanned'] ? Icons.lock : Icons.lock_open,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    await ApiService.toggleBan(u['_id']);
                    fetchUsers();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  onPressed: () async {
                    final newRole = u['role'] == 'admin' ? 'user' : 'admin';
                    await ApiService.changeRole(u['_id'], newRole);
                    fetchUsers();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
