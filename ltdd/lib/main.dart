import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'services/database_services.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully!');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinema App',
      home: Scaffold(
        appBar: AppBar(title: const Text('Test Firebase')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // Test save data
              UserModel testUser = UserModel(
                id: 'test_user_123',
                name: 'Test User',
                email: 'test@example.com',
                role: 'user',
              );
              await DatabaseService().saveUser(testUser);
              print('Test user saved!'); // Xem console
            },
            child: const Text('Test Save User to Firebase'),
          ),
        ),
      ),
    );
  }
}