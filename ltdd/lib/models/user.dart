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
  final String? avatarUrl; // URL của avatar

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
    this.avatarUrl,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> data, String key) {
    // Parse phone - đảm bảo là String và không empty
    String? phoneValue;
    final phoneData = data['phone'];
    if (phoneData != null && phoneData.toString().trim().isNotEmpty) {
      phoneValue = phoneData.toString().trim();
    } else {
      phoneValue = null;
    }
    
    // Parse dateOfBirth - đảm bảo là int
    int? dateOfBirthValue;
    final dateOfBirthData = data['dateOfBirth'];
    if (dateOfBirthData != null) {
      if (dateOfBirthData is int) {
        dateOfBirthValue = dateOfBirthData;
      } else if (dateOfBirthData is num) {
        dateOfBirthValue = dateOfBirthData.toInt();
      } else {
        // Thử parse từ String nếu cần
        dateOfBirthValue = int.tryParse(dateOfBirthData.toString());
      }
    } else {
      dateOfBirthValue = null;
    }
    
    return UserModel(
      id: key,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      phone: phoneValue,
      dateOfBirth: dateOfBirthValue,
      createdAt: data['createdAt'] is int ? data['createdAt'] : (data['createdAt'] is num ? data['createdAt'].toInt() : int.tryParse(data['createdAt']?.toString() ?? '')),
      fcmToken: data['fcmToken']?.toString(),
      points: (data['points'] is num) ? (data['points'] as num).toInt() : (int.tryParse(data['points']?.toString() ?? '0') ?? 0),
      avatarUrl: data['avatarUrl']?.toString(),
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
      'avatarUrl': avatarUrl,
    };
  }
}