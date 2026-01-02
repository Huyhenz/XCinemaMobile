import 'package:firebase_database/firebase_database.dart';

class VoucherModel {
  final String id; // Code voucher
  final double discount; // Phần trăm (0-100) hoặc giá cố định
  final String type; // 'percent' hoặc 'fixed'
  final int expiryDate; // Timestamp hết hạn
  final bool isActive;
  final int? points; // Điểm cần để đổi voucher (null nếu không cần điểm)
  final String voucherType; // 'free', 'task', 'points'
  final String? requiredTaskId; // ID của task cần hoàn thành (cho task voucher)
  final bool isUnlocked; // Đã mở khóa chưa (cho task voucher)

  VoucherModel({
    required this.id,
    required this.discount,
    required this.type,
    required this.expiryDate,
    this.isActive = true,
    this.points,
    this.voucherType = 'free', // Mặc định là free
    this.requiredTaskId,
    this.isUnlocked = false,
  });

  factory VoucherModel.fromMap(Map<dynamic, dynamic> data, String key) {
    // Xác định voucherType dựa trên các trường có sẵn
    String voucherType = 'free';
    if (data['voucherType'] != null) {
      voucherType = data['voucherType'].toString();
    } else if (data['points'] != null) {
      voucherType = 'points';
    } else if (data['requiredTaskId'] != null) {
      voucherType = 'task';
    }
    
    return VoucherModel(
      id: key,
      discount: data['discount']?.toDouble() ?? 0.0,
      type: data['type'] ?? 'percent',
      expiryDate: data['expiryDate'] ?? 0,
      isActive: data['isActive'] ?? true,
      points: data['points'] != null ? ((data['points'] is num) ? (data['points'] as num).toInt() : int.tryParse(data['points'].toString())) : null,
      voucherType: voucherType,
      requiredTaskId: data['requiredTaskId']?.toString(),
      isUnlocked: data['isUnlocked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'discount': discount,
      'type': type,
      'expiryDate': expiryDate,
      'isActive': isActive,
      'points': points,
      'voucherType': voucherType,
      'requiredTaskId': requiredTaskId,
      'isUnlocked': isUnlocked,
    };
  }
}