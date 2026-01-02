import 'package:firebase_database/firebase_database.dart';

class BookingModel {
  final String id; // Key
  final String userId;
  final String showtimeId;
  final String cinemaId; // ID của rạp chiếu
  final List<String> seats; // Ghế đã chọn
  final double totalPrice; // Giá gốc
  final double? finalPrice; // Sau áp voucher
  final String? voucherId; // Nếu áp dụng
  final int? bookedAt; // Timestamp
  final String status; // 'pending', 'confirmed', 'cancelled'
  final String? paymentMethod; // 'paypal', 'vnpay', 'zalopay'
  final Map<String, int>? snacks; // snackId -> quantity

  BookingModel({
    required this.id,
    required this.userId,
    required this.showtimeId,
    required this.cinemaId,
    required this.seats,
    required this.totalPrice,
    this.finalPrice,
    this.voucherId,
    this.bookedAt,
    this.status = 'pending',
    this.paymentMethod,
    this.snacks,
  });

  factory BookingModel.fromMap(Map<dynamic, dynamic> data, String key) {
    // Safely convert seats - handle both List and other types
    List<String> seatsList = [];
    try {
      if (data['seats'] is List) {
        seatsList = List<String>.from(data['seats']!.map((s) => s.toString()));
      } else if (data['seats'] != null) {
        // If seats is not a List, try to convert
        print('⚠️ Warning: seats is not a List in booking $key');
      }
    } catch (e) {
      print('⚠️ Error parsing seats in booking $key: $e');
    }
    
    // Safely convert totalPrice
    double totalPriceValue = 0.0;
    try {
      if (data['totalPrice'] != null) {
        if (data['totalPrice'] is num) {
          totalPriceValue = data['totalPrice'].toDouble();
        } else if (data['totalPrice'] is String) {
          totalPriceValue = double.tryParse(data['totalPrice']) ?? 0.0;
        }
      }
    } catch (e) {
      print('⚠️ Error parsing totalPrice in booking $key: $e');
    }
    
    // Safely convert finalPrice
    double? finalPriceValue;
    try {
      if (data['finalPrice'] != null) {
        if (data['finalPrice'] is num) {
          finalPriceValue = data['finalPrice'].toDouble();
        } else if (data['finalPrice'] is String) {
          finalPriceValue = double.tryParse(data['finalPrice']);
        }
      }
    } catch (e) {
      print('⚠️ Error parsing finalPrice in booking $key: $e');
    }
    
    // Safely convert bookedAt
    int? bookedAtValue;
    try {
      if (data['bookedAt'] != null) {
        if (data['bookedAt'] is num) {
          bookedAtValue = data['bookedAt'].toInt();
        } else if (data['bookedAt'] is String) {
          bookedAtValue = int.tryParse(data['bookedAt']);
        }
      }
    } catch (e) {
      print('⚠️ Error parsing bookedAt in booking $key: $e');
    }
    
    // Safely convert snacks
    Map<String, int>? snacksMap;
    try {
      if (data['snacks'] != null && data['snacks'] is Map) {
        final snacksData = Map<dynamic, dynamic>.from(data['snacks']);
        snacksMap = {};
        snacksData.forEach((key, value) {
          if (value is num) {
            snacksMap![key.toString()] = value.toInt();
          } else if (value is String) {
            snacksMap![key.toString()] = int.tryParse(value) ?? 0;
          }
        });
      }
    } catch (e) {
      print('⚠️ Error parsing snacks in booking $key: $e');
    }

    return BookingModel(
      id: key,
      userId: data['userId']?.toString() ?? '',
      showtimeId: data['showtimeId']?.toString() ?? '',
      cinemaId: data['cinemaId']?.toString() ?? '',
      seats: seatsList,
      totalPrice: totalPriceValue,
      finalPrice: finalPriceValue,
      voucherId: data['voucherId']?.toString(),
      bookedAt: bookedAtValue,
      status: data['status']?.toString() ?? 'pending',
      paymentMethod: data['paymentMethod']?.toString(),
      snacks: snacksMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'showtimeId': showtimeId,
      'cinemaId': cinemaId,
      'seats': seats,
      'totalPrice': totalPrice,
      'finalPrice': finalPrice,
      'voucherId': voucherId,
      'bookedAt': bookedAt ?? ServerValue.timestamp,
      'status': status,
      'paymentMethod': paymentMethod,
      if (snacks != null && snacks!.isNotEmpty) 'snacks': snacks,
    };
  }
}