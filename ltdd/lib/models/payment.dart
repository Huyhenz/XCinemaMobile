import 'package:firebase_database/firebase_database.dart';

class PaymentModel {
  final String id; // Key
  final String bookingId;
  final double amount; // Số tiền cuối cùng (sau voucher)
  final String status; // 'success', 'failed', 'pending'
  final String? transactionId; // Từ VNPay hoặc gateway khác
  final int? paidAt; // Timestamp

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    this.transactionId,
    this.paidAt,
  });

  factory PaymentModel.fromMap(Map<dynamic, dynamic> data, String key) {
    return PaymentModel(
      id: key,
      bookingId: data['bookingId'] ?? '',
      amount: data['amount']?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',
      transactionId: data['transactionId'],
      paidAt: data['paidAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'amount': amount,
      'status': status,
      'transactionId': transactionId,
      'paidAt': ServerValue.timestamp,
    };
  }
}