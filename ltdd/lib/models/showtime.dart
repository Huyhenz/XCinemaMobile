import 'package:firebase_database/firebase_database.dart';

class ShowtimeModel {
  final String id; // Key
  final String movieId; // Tham chiếu đến Movie
  final String theaterId; // Tham chiếu đến phòng chiếu (nếu có model riêng)
  final int startTime; // Timestamp
  final double price; // Giá vé cơ bản (VND)
  final List<String> availableSeats; // Danh sách ghế trống, ví dụ: ['A1', 'A2']

  ShowtimeModel({
    required this.id,
    required this.movieId,
    required this.theaterId,
    required this.startTime,
    required this.price,
    required this.availableSeats,
  });

  factory ShowtimeModel.fromMap(Map<dynamic, dynamic> data, String key) {
    return ShowtimeModel(
      id: key,
      movieId: data['movieId'] ?? '',
      theaterId: data['theaterId'] ?? '',
      startTime: data['startTime'] ?? 0,
      price: data['price']?.toDouble() ?? 0.0,
      availableSeats: List<String>.from(data['availableSeats'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'movieId': movieId,
      'theaterId': theaterId,
      'startTime': startTime,
      'price': price,
      'availableSeats': availableSeats,
    };
  }
}