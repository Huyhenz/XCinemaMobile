import 'package:firebase_database/firebase_database.dart';

class UserModel {
  final String id; // UID từ Firebase Auth
  final String name;
  final String email;
  final String role; // 'user' hoặc 'admin'
  final String? phone;
  final int? createdAt; // Timestamp (milliseconds)
  final String? fcmToken; // Cho Firebase Messaging (push notifications)

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.createdAt,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> data, String key) {
    return UserModel(
      id: key,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      phone: data['phone'],
      createdAt: data['createdAt'],
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'createdAt': ServerValue.timestamp,
      'fcmToken': fcmToken,
    };
  }
}