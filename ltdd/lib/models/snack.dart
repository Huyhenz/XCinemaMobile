// File: lib/models/snack.dart
import 'package:firebase_database/firebase_database.dart';

class SnackModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category; // 'popcorn', 'drink', 'combo', 'snack'
  final bool isActive;
  final int? quantity; // Số lượng có sẵn (null nếu không giới hạn)

  SnackModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isActive = true,
    this.quantity,
  });

  factory SnackModel.fromMap(Map<dynamic, dynamic> data, String key) {
    return SnackModel(
      id: key,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : double.tryParse(data['price'].toString()) ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'snack',
      isActive: data['isActive'] ?? true,
      quantity: data['quantity'] != null ? ((data['quantity'] is num) ? (data['quantity'] as num).toInt() : int.tryParse(data['quantity'].toString())) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isActive': isActive,
      'quantity': quantity,
    };
  }
}

