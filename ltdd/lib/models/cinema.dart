import 'package:firebase_database/firebase_database.dart';

class CinemaModel {
  final String id; // Key
  final String name; // Tên rạp chiếu (e.g., 'CGV Vincom', 'Galaxy Cinema')
  final String address; // Địa chỉ rạp
  final String? phone; // Số điện thoại
  final String? imageUrl; // URL ảnh rạp
  final double? latitude; // Vĩ độ (cho map)
  final double? longitude; // Kinh độ (cho map)
  final int? createdAt; // Timestamp

  CinemaModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory CinemaModel.fromMap(Map<dynamic, dynamic> data, String key) {
    // Safely convert latitude
    double? latValue;
    try {
      if (data['latitude'] != null) {
        if (data['latitude'] is num) {
          latValue = data['latitude'].toDouble();
        } else if (data['latitude'] is String) {
          latValue = double.tryParse(data['latitude']);
        }
      }
    } catch (e) {
      print('⚠️ Error parsing latitude in cinema $key: $e');
    }

    // Safely convert longitude
    double? lngValue;
    try {
      if (data['longitude'] != null) {
        if (data['longitude'] is num) {
          lngValue = data['longitude'].toDouble();
        } else if (data['longitude'] is String) {
          lngValue = double.tryParse(data['longitude']);
        }
      }
    } catch (e) {
      print('⚠️ Error parsing longitude in cinema $key: $e');
    }

    return CinemaModel(
      id: key,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      latitude: latValue,
      longitude: lngValue,
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': ServerValue.timestamp,
    };
  }
}





