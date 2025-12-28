import 'package:firebase_database/firebase_database.dart';

class VoucherModel {
  final String id; // Code voucher
  final double discount; // Phần trăm (0-100) hoặc giá cố định
  final String type; // 'percent' hoặc 'fixed'
  final int expiryDate; // Timestamp hết hạn
  final bool isActive;
  final int? points; // Điểm cần để đổi voucher (null nếu không cần điểm)

  VoucherModel({
    required this.id,
    required this.discount,
    required this.type,
    required this.expiryDate,
    this.isActive = true,
    this.points,
  });

  factory VoucherModel.fromMap(Map<dynamic, dynamic> data, String key) {
    return VoucherModel(
      id: key,
      discount: data['discount']?.toDouble() ?? 0.0,
      type: data['type'] ?? 'percent',
      expiryDate: data['expiryDate'] ?? 0,
      isActive: data['isActive'] ?? true,
      points: data['points'] != null ? ((data['points'] is num) ? (data['points'] as num).toInt() : int.tryParse(data['points'].toString())) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'discount': discount,
      'type': type,
      'expiryDate': expiryDate,
      'isActive': isActive,
      'points': points,
    };
  }
}