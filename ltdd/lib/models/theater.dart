import 'package:firebase_database/firebase_database.dart';

class TheaterModel {
  final String id; // Key
  final String name; // Tên phòng chiếu (e.g., 'Room 1')
  final String cinemaId; // ID của rạp chiếu (Cinema)
  final int capacity; // Sức chứa
  final List<String> seats; // Danh sách ghế mặc định (e.g., ['A1', 'A2', ...])
  final Map<String, String> seatTypes; // Map từ tên ghế đến loại ghế ('single', 'couple', 'vip')
  final String theaterType; // Loại phòng: 'normal', 'couple', 'vip'
  final double singleSeatPrice; // Giá ghế đơn (VND)
  final double coupleSeatPrice; // Giá ghế cặp (VND)
  final double vipSeatPrice; // Giá ghế VIP (VND)

  TheaterModel({
    required this.id,
    required this.name,
    required this.cinemaId,
    required this.capacity,
    required this.seats,
    Map<String, String>? seatTypes,
    String? theaterType,
    double? singleSeatPrice,
    double? coupleSeatPrice,
    double? vipSeatPrice,
  })  : seatTypes = seatTypes ?? {},
        theaterType = theaterType ?? 'normal',
        singleSeatPrice = singleSeatPrice ?? 0.0,
        coupleSeatPrice = coupleSeatPrice ?? 0.0,
        vipSeatPrice = vipSeatPrice ?? 0.0;

  factory TheaterModel.fromMap(Map<dynamic, dynamic> data, String key) {
    // Parse seatTypes
    Map<String, String> seatTypesMap = {};
    try {
      if (data['seatTypes'] != null && data['seatTypes'] is Map) {
        final seatTypesData = Map<dynamic, dynamic>.from(data['seatTypes'] as Map);
        seatTypesMap = seatTypesData.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (e) {
      print('⚠️ Error parsing seatTypes in theater $key: $e');
    }

    // Parse theaterType
    String theaterTypeValue = 'normal';
    try {
      if (data['theaterType'] != null) {
        theaterTypeValue = data['theaterType'].toString();
      }
    } catch (e) {
      print('⚠️ Error parsing theaterType in theater $key: $e');
    }

    // Parse prices
    double singlePrice = 0.0;
    double couplePrice = 0.0;
    double vipPrice = 0.0;
    try {
      if (data['singleSeatPrice'] != null) {
        if (data['singleSeatPrice'] is num) {
          singlePrice = data['singleSeatPrice'].toDouble();
        } else if (data['singleSeatPrice'] is String) {
          singlePrice = double.tryParse(data['singleSeatPrice']) ?? 0.0;
        }
      }
      if (data['coupleSeatPrice'] != null) {
        if (data['coupleSeatPrice'] is num) {
          couplePrice = data['coupleSeatPrice'].toDouble();
        } else if (data['coupleSeatPrice'] is String) {
          couplePrice = double.tryParse(data['coupleSeatPrice']) ?? 0.0;
        }
      }
      if (data['vipSeatPrice'] != null) {
        if (data['vipSeatPrice'] is num) {
          vipPrice = data['vipSeatPrice'].toDouble();
        } else if (data['vipSeatPrice'] is String) {
          vipPrice = double.tryParse(data['vipSeatPrice']) ?? 0.0;
        }
      }
    } catch (e) {
      print('⚠️ Error parsing seat prices in theater $key: $e');
    }

    return TheaterModel(
      id: key,
      name: data['name'] ?? '',
      cinemaId: data['cinemaId']?.toString() ?? '',
      capacity: data['capacity'] ?? 0,
      seats: List<String>.from(data['seats'] ?? []),
      seatTypes: seatTypesMap,
      theaterType: theaterTypeValue,
      singleSeatPrice: singlePrice,
      coupleSeatPrice: couplePrice,
      vipSeatPrice: vipPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cinemaId': cinemaId,
      'capacity': capacity,
      'seats': seats,
      'seatTypes': seatTypes,
      'theaterType': theaterType,
      'singleSeatPrice': singleSeatPrice,
      'coupleSeatPrice': coupleSeatPrice,
      'vipSeatPrice': vipSeatPrice,
    };
  }

  // Helper method để lấy giá của một ghế
  double getSeatPrice(String seatName) {
    final seatType = seatTypes[seatName] ?? 'single';
    if (seatType == 'vip') {
      return vipSeatPrice;
    } else if (seatType == 'couple') {
      return coupleSeatPrice;
    } else {
      return singleSeatPrice;
    }
  }

  // Helper method để lấy loại ghế
  String getSeatType(String seatName) {
    return seatTypes[seatName] ?? 'single';
  }
}