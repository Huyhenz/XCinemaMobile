import 'package:firebase_database/firebase_database.dart';

class TheaterModel {
  final String id; // Key
  final String name; // Tên phòng chiếu (e.g., 'Room 1')
  final int capacity; // Sức chứa
  final List<String> seats; // Danh sách ghế mặc định (e.g., ['A1', 'A2', ...])

  TheaterModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.seats,
  });

  factory TheaterModel.fromMap(Map<dynamic, dynamic> data, String key) {
    return TheaterModel(
      id: key,
      name: data['name'] ?? '',
      capacity: data['capacity'] ?? 0,
      seats: List<String>.from(data['seats'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'capacity': capacity,
      'seats': seats,
    };
  }
}