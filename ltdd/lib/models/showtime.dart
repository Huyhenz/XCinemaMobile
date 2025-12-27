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
    // Safely convert startTime
    int startTimeValue = 0;
    try {
      if (data['startTime'] != null) {
        if (data['startTime'] is num) {
          startTimeValue = data['startTime'].toInt();
        } else if (data['startTime'] is String) {
          startTimeValue = int.tryParse(data['startTime']) ?? 0;
        }
      }
    } catch (e) {
      print('⚠️ Error parsing startTime in showtime $key: $e');
    }
    
    // Safely convert price
    double priceValue = 0.0;
    try {
      if (data['price'] != null) {
        if (data['price'] is num) {
          priceValue = data['price'].toDouble();
        } else if (data['price'] is String) {
          priceValue = double.tryParse(data['price']) ?? 0.0;
        }
      }
    } catch (e) {
      print('⚠️ Error parsing price in showtime $key: $e');
    }
    
    // Safely convert availableSeats
    List<String> seatsList = [];
    try {
      if (data['availableSeats'] is List) {
        seatsList = List<String>.from(data['availableSeats']!.map((s) => s.toString()));
      } else if (data['availableSeats'] != null) {
        print('⚠️ Warning: availableSeats is not a List in showtime $key');
      }
    } catch (e) {
      print('⚠️ Error parsing availableSeats in showtime $key: $e');
    }
    
    return ShowtimeModel(
      id: key,
      movieId: data['movieId']?.toString() ?? '',
      theaterId: data['theaterId']?.toString() ?? '',
      startTime: startTimeValue,
      price: priceValue,
      availableSeats: seatsList,
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