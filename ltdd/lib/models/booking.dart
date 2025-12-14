import 'package:firebase_database/firebase_database.dart';

class BookingModel {
  final String id; // Key
  final String userId;
  final String showtimeId;
  final List<String> seats; // Ghế đã chọn
  final double totalPrice; // Giá gốc
  final double? finalPrice; // Sau áp voucher
  final String? voucherId; // Nếu áp dụng
  final int? bookedAt; // Timestamp
  final String status; // 'pending', 'confirmed', 'cancelled'

  BookingModel({
    required this.id,
    required this.userId,
    required this.showtimeId,
    required this.seats,
    required this.totalPrice,
    this.finalPrice,
    this.voucherId,
    this.bookedAt,
    this.status = 'pending',
  });

  factory BookingModel.fromMap(Map<dynamic, dynamic> data, String key) {
    return BookingModel(
      id: key,
      userId: data['userId'] ?? '',
      showtimeId: data['showtimeId'] ?? '',
      seats: List<String>.from(data['seats'] ?? []),
      totalPrice: data['totalPrice']?.toDouble() ?? 0.0,
      finalPrice: data['finalPrice']?.toDouble(),
      voucherId: data['voucherId'],
      bookedAt: data['bookedAt'],
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'showtimeId': showtimeId,
      'seats': seats,
      'totalPrice': totalPrice,
      'finalPrice': finalPrice,
      'voucherId': voucherId,
      'bookedAt': ServerValue.timestamp,
      'status': status,
    };
  }
}