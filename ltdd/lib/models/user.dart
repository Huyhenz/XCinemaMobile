import 'package:firebase_database/firebase_database.dart';

class UserModel {
  final String id; // UID từ Firebase Auth
  final String name;
  final String email;
  final String role; // 'user' hoặc 'admin'
  final String? phone;
  final int? dateOfBirth; // Timestamp (milliseconds) - ngày tháng năm sinh
  final int? createdAt; // Timestamp (milliseconds)
  final String? fcmToken; // Cho Firebase Messaging (push notifications)
  final int points; // Điểm tích lũy

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.dateOfBirth,
    this.createdAt,
    this.fcmToken,
    this.points = 0,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> data, String key) {
    return UserModel(
      id: key,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      phone: data['phone'],
      dateOfBirth: data['dateOfBirth'],
      createdAt: data['createdAt'],
      fcmToken: data['fcmToken'],
      points: (data['points'] is num) ? (data['points'] as num).toInt() : (int.tryParse(data['points']?.toString() ?? '0') ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'createdAt': ServerValue.timestamp,
      'fcmToken': fcmToken,
      'points': points,
    };
  }
}