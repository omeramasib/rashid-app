import 'package:flutter/material.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:get_it/get_it.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final storage = GetIt.instance<SecureStorageService>();
              await storage.delete(key: 'token');
              await storage.delete(key: 'user_id');
              await storage.delete(key: 'email');
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RoutesName.login,
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
