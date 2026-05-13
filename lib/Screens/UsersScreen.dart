import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: const Color(0xff24394a),
      ),
      body: FutureBuilder(
        future: ApiService.getUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data as List;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(u['name']),
                subtitle: Text(u['email']),
              );
            },
          );
        },
      ),
    );
  }
}
