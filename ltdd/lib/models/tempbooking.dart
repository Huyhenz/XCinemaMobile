import 'package:firebase_database/firebase_database.dart';

class TempBookingModel {
  final String id; // Key tạm (có thể generate random hoặc dựa trên user+showtime)
  final String userId;
  final String showtimeId;
  final List<String> seats; // Ghế tạm giữ
  final int createdAt; // Timestamp tạo
  final int expiryTime; // Timestamp hết hạn (ví dụ: createdAt + 10 phút)
  final String status; // 'active', 'expired', 'converted' (chuyển sang booking)

  TempBookingModel({
    required this.id,
    required this.userId,
    required this.showtimeId,
    required this.seats,
    required this.createdAt,
    required this.expiryTime,
    this.status = 'active',
  });

  factory TempBookingModel.fromMap(Map<dynamic, dynamic> data, String key) {
    return TempBookingModel(
      id: key,
      userId: data['userId'] ?? '',
      showtimeId: data['showtimeId'] ?? '',
      seats: List<String>.from(data['seats'] ?? []),
      createdAt: data['createdAt'] ?? 0,
      expiryTime: data['expiryTime'] ?? 0,
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'showtimeId': showtimeId,
      'seats': seats,
      'createdAt': ServerValue.timestamp,
      'expiryTime': expiryTime, // Tính ở client: DateTime.now().add(Duration(minutes: 10)).millisecondsSinceEpoch
      'status': status,
    };
  }
}